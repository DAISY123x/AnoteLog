/**
 * @file WeatherService.ets
 * @brief 高德 Web 天气服务（支持强制刷新、定位开关预检）
 * @description 无 Key 或请求失败时返回 Mock；带内存缓存(30min)；Key 仅来自 ConfigService。
 *   定位顺序：GPS+逆地理（开关开启）→ 网络 IP；默认城市仅在天象请求失败或无数据时回退。
 *   提供 forceRefresh() 供调用方实时更新。
 */
import http from '@ohos.net.http';
import { BusinessError } from '@kit.BasicServicesKit';
import { geoLocationManager } from '@kit.LocationKit';
import { ConfigService } from './ConfigService';
import { NetworkUtil } from '../utils/NetworkUtil';
import { Logger } from '../utils/Logger';
import { WeatherSnapshot } from '../model/WeatherModel';

const TAG = 'WeatherService';

interface AmapIpJson {
  status?: string;
  adcode?: string;
  city?: string;
  province?: string;
  rectangle?: string;
  info?: string;
}

interface AmapLive {
  province?: string;
  city?: string;
  weather?: string;
  temperature?: string;
  humidity?: string;
  winddirection?: string;
  windpower?: string;
  reporttime?: string;
}

interface AmapWeatherJson {
  status?: string;
  info?: string;
  infocode?: string;
  lives?: AmapLive[];
}

interface RegeoAddressComponent {
  province?: string;
  city?: string | string[];
  district?: string;
  adcode?: string;
}

interface Regeocode {
  addressComponent?: RegeoAddressComponent;
}

interface RegeoJson {
  status?: string;
  info?: string;
  regeocode?: Regeocode;
}

export class WeatherService {
  private static instance: WeatherService | null = null;
  private cache: WeatherSnapshot | null = null;
  private cacheAt: number = 0;
  /** 缓存有效期 30 分钟 */
  private readonly TTL_MS: number = 30 * 60 * 1000;

  private constructor() {}

  static getInstance(): WeatherService {
    if (WeatherService.instance === null) {
      WeatherService.instance = new WeatherService();
    }
    return WeatherService.instance;
  }

  // ==================== 公开接口 ====================

  /**
   * 获取当前天气（有缓存则直接返回，否则请求网络）
   * 首次调用会等待 ConfigService 初始化完成
   */
  async getCurrentWeather(): Promise<WeatherSnapshot> {
    await ConfigService.getInstance().ready;
    return this.fetchInternal(false);
  }

  /**
   * 强制刷新天气（忽略缓存，重新请求网络）
   * 用于：用户手动下拉/进入前台/打开详情等需要实时数据的场景
   */
  async forceRefresh(): Promise<WeatherSnapshot> {
    await ConfigService.getInstance().ready;
    return this.fetchInternal(true);
  }

  getMockWeather(): WeatherSnapshot {
    return WeatherService.buildMock(true);
  }

  // ==================== 内部实现 ====================

  /**
   * 核心获取逻辑（统一入口，force 控制是否跳过缓存）
   */
  private async fetchInternal(force: boolean): Promise<WeatherSnapshot> {
    const cfg = ConfigService.getInstance().getWeatherConfig();
    const key = cfg.webKey;

    const defaultAd = cfg.defaultAdcode.trim();
    Logger.info(TAG,
      `step0 hasKey=${key.length > 0} key=${WeatherService.maskKey(key)} fallbackAdcode(仅失败时用)=${defaultAd}`);

    if (key.length === 0) {
      return WeatherService.buildMock(true);
    }

    if (!force && this.cache !== null && Date.now() - this.cacheAt < this.TTL_MS) {
      Logger.info(TAG, 'step0 return memory cache');
      return this.cache;
    }

    try {
      const snap = await WeatherService.fetchWeatherWithLocationFallback(key, defaultAd);
      this.cache = snap;
      this.cacheAt = Date.now();
      Logger.info(TAG,
        `step3 success isMock=${snap.isMock} city=${snap.city} 省=${snap.province} ` +
          `queryAdcode=${snap.queryAdcode ?? ''} fallbackTip=${snap.fallbackTip !== undefined ? 'yes' : 'no'}`);
      return snap;
    } catch (e) {
      Logger.error(TAG, `fetch failed: ${JSON.stringify(e)}`);
      return this.cache !== null ? this.cache : WeatherService.buildMock(false);
    }
  }

  // ==================== 工具方法 ====================

  private static maskKey(key: string): string {
    if (key.length <= 8) return '****';
    return `${key.substring(0, 4)}****${key.substring(key.length - 4)}`;
  }

  /** 定位开关预检：避免在关闭状态下调用 GPS 导致 3301100 噪音日志 */
  private static async isGpsAvailable(): Promise<boolean> {
    try {
      return await geoLocationManager.isLocationEnabled();
    } catch {
      return false;
    }
  }

  // ==================== 定位策略（不含配置默认城市）====================

  /** GPS（若开关开）→ 失败则 IP。不读取 defaultAdcode。 */
  private static async resolveAdcodeFromLocation(key: string): Promise<string> {
    if (await WeatherService.isGpsAvailable()) {
      const gpsResult = await WeatherService.tryAdcodeFromGps(key);
      if (gpsResult !== null && gpsResult.length > 0) {
        return gpsResult;
      }
      Logger.info(TAG, 'GPS未返回adcode，改用IP');
    } else {
      Logger.info(TAG, '定位开关已关闭，跳过GPS');
    }
    const ip = await WeatherService.fetchAdcodeFromIp(key);
    return ip;
  }

  /**
   * 先用 GPS/IP 解析的 adcode 查实况；无数据或请求失败时再试配置中的默认城市，并写入 fallbackTip。
   */
  private static async fetchWeatherWithLocationFallback(key: string, defaultAdcode: string): Promise<WeatherSnapshot> {
    const fetchFor = async (ad: string): Promise<WeatherSnapshot> => {
      return WeatherService.fetchLiveWithParentRetry(key, ad);
    };
    const valid = (ad: string): boolean => ad.length >= 4;

    const primary = await WeatherService.resolveAdcodeFromLocation(key);
    Logger.info(TAG, `step1 定位解析 adcode=${primary}（仅GPS/IP，不含配置默认）`);

    let primarySnap: WeatherSnapshot | null = null;
    let primaryHttpError = false;

    if (valid(primary)) {
      try {
        primarySnap = await fetchFor(primary);
        if (!primarySnap.noData) {
          return primarySnap;
        }
        Logger.warn(TAG, `step2 无实况 lives空 adcode=${primary}`);
      } catch (e) {
        primaryHttpError = true;
        Logger.error(TAG, `step2 请求失败 adcode=${primary}: ${JSON.stringify(e)}`);
        primarySnap = WeatherService.buildNoData(primary);
      }
    } else {
      Logger.warn(TAG, 'step1 无有效adcode（GPS/IP均未返回）');
    }

    if (!valid(defaultAdcode)) {
      return primarySnap !== null ? primarySnap : WeatherService.buildMock(false);
    }

    if (valid(primary) && primary === defaultAdcode) {
      if (primarySnap !== null) {
        return WeatherService.attachHint(primarySnap,
          primarySnap.noData ? '当前区域暂无气象实况' : undefined);
      }
      return WeatherService.buildMock(false);
    }

    let tip: string;
    if (!valid(primary)) {
      tip = '暂时无法获取您的位置，已展示默认城市天气';
    } else if (primaryHttpError) {
      tip = '天气数据加载异常，已展示默认城市天气';
    } else if (primarySnap !== null && primarySnap.noData) {
      tip = '当前区域暂无气象实况，已切换为默认城市天气';
    } else {
      tip = '天气数据加载异常，已展示默认城市天气';
    }

    Logger.warn(TAG, `step3 回退默认城市 adcode=${defaultAdcode} primary=${primary}`);
    try {
      const fb = await fetchFor(defaultAdcode);
      return WeatherService.attachHint(fb, tip);
    } catch (e) {
      Logger.error(TAG, `step3 默认城市失败: ${JSON.stringify(e)}`);
      if (primarySnap !== null) {
        return WeatherService.attachHint(primarySnap, `${tip}（默认城市暂不可用）`);
      }
      return WeatherService.buildMock(false);
    }
  }

  private static attachHint(s: WeatherSnapshot, tip: string | undefined): WeatherSnapshot {
    if (tip === undefined || tip.length === 0) {
      return s;
    }
    return {
      province: s.province,
      city: s.city,
      weather: s.weather,
      temperature: s.temperature,
      humidity: s.humidity,
      windDirection: s.windDirection,
      windPower: s.windPower,
      reportTime: s.reportTime,
      hint: s.hint,
      isMock: s.isMock,
      queryAdcode: s.queryAdcode,
      noData: s.noData,
      fallbackTip: tip
    };
  }

  /** GPS + 高德逆地理 → adcode */
  private static async tryAdcodeFromGps(key: string): Promise<string | null> {
    return new Promise((resolve) => {
      try {
        const request: geoLocationManager.CurrentLocationRequest = {
          priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
          scenario: geoLocationManager.LocationRequestScenario.UNSET,
          maxAccuracy: 100,
          timeoutMs: 8000
        };
        geoLocationManager.getCurrentLocation(request,
          (err: BusinessError, location: geoLocationManager.Location): void => {
            if (err !== undefined && err !== null) {
              Logger.warn(TAG, `GPS定位 code=${err.code} msg=${err.message}`);
              resolve(null);
              return;
            }
            const lng = location.longitude;
            const lat = location.latitude;
            Logger.info(TAG, `GPS成功: lng=${lng} lat=${lat}`);
            const locParam = `${lng},${lat}`;
            const url =
              `https://restapi.amap.com/v3/geocode/regeo?key=${encodeURIComponent(key)}` +
                `&location=${encodeURIComponent(locParam)}&extensions=base`;
            WeatherService.httpGet(url).then((text: string) => {
              try {
                const rpv = text.length > 320 ? `${text.substring(0, 320)}...` : text;
                Logger.info(TAG, `regeo raw: ${rpv}`);
                const j = JSON.parse(text) as RegeoJson;
                if (j.status !== '1') { resolve(null); return; }
                const ac = j.regeocode?.addressComponent;
                if (ac === undefined) { resolve(null); return; }
                const ad = ac.adcode ?? '';
                const cname = WeatherService.formatCityField(ac.city);
                Logger.info(TAG, `逆地理: ${ac.province ?? ''} ${cname} adcode=${ad}`);
                resolve(ad.length >= 4 ? ad : null);
              } catch {
                resolve(null);
              }
            }).catch(() => resolve(null));
          });
      } catch {
        resolve(null);
      }
    });
  }

  /** 高德 IP 定位 → adcode */
  private static async fetchAdcodeFromIp(key: string): Promise<string> {
    try {
      const url = `https://restapi.amap.com/v3/ip?key=${encodeURIComponent(key)}`;
      Logger.info(TAG, `step1 ip: request key=${WeatherService.maskKey(key)}`);
      const text = await WeatherService.httpGet(url);
      const preview = text.length > 280 ? `${text.substring(0, 280)}...` : text;
      Logger.info(TAG, `step1 ip raw: ${preview}`);
      const j = JSON.parse(text) as AmapIpJson;
      Logger.info(TAG,
        `定位(IP): status=${j.status ?? ''} ${j.province ?? ''} ${j.city ?? ''} adcode=${j.adcode ?? ''}`);
      if (j.status === '1' && j.adcode !== undefined && j.adcode.length > 0) {
        return j.adcode;
      }
    } catch (e) {
      Logger.warn(TAG, `IP定位 error: ${JSON.stringify(e)}`);
    }
    return '';
  }

  // ==================== 天气数据获取 ====================

  private static async fetchLiveWithParentRetry(key: string, adcode: string): Promise<WeatherSnapshot> {
    let snap = await WeatherService.fetchLiveOnce(key, adcode);
    if (!snap.noData) return snap;
    const p = WeatherService.parentAdcode(adcode);
    if (p !== null) {
      Logger.info(TAG, `lives空，重试上级 adcode=${p}`);
      snap = await WeatherService.fetchLiveOnce(key, p);
    }
    return snap;
  }

  private static parentAdcode(adcode: string): string | null {
    if (adcode.length !== 6) return null;
    const parent = `${adcode.substring(0, 4)}00`;
    return parent === adcode ? null : parent;
  }

  private static async fetchLiveOnce(key: string, adcode: string): Promise<WeatherSnapshot> {
    const url =
      `https://restapi.amap.com/v3/weather/weatherInfo?key=${encodeURIComponent(key)}` +
        `&city=${encodeURIComponent(adcode)}&extensions=base`;
    Logger.info(TAG, `step2 weather: city(adcode)=${adcode}`);
    const text = await WeatherService.httpGet(url);
    const wPrev = text.length > 400 ? `${text.substring(0, 400)}...` : text;
    Logger.info(TAG, `step2 weather raw: ${wPrev}`);
    const j = JSON.parse(text) as AmapWeatherJson;

    if (j.status !== '1') {
      throw new Error(j.info ?? 'weather api');
    }
    if (j.lives === undefined || j.lives.length < 1) {
      return WeatherService.buildNoData(adcode);
    }

    const L = j.lives[0];
    const tempStr = L.temperature ?? '--';
    let tempNum = parseInt(tempStr, 10);
    if (isNaN(tempNum)) tempNum = 20;
    const weatherStr = L.weather ?? '未知';

    return {
      province: L.province ?? '',
      city: L.city ?? '',
      weather: weatherStr,
      temperature: tempStr,
      humidity: L.humidity ?? '--',
      windDirection: L.winddirection ?? '',
      windPower: L.windpower ?? '',
      reportTime: L.reporttime ?? '',
      hint: WeatherService.hintFrom(weatherStr, tempNum),
      isMock: false,
      queryAdcode: adcode,
      noData: false
    };
  }

  // ==================== HTTP & 辅助 ====================

  private static async httpGet(url: string): Promise<string> {
    const req = http.createHttp();
    try {
      const res = await req.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 12000,
        readTimeout: 12000
      });
      if (res.responseCode !== 200) throw new Error(`http ${res.responseCode}`);
      return res.result as string;
    } finally {
      req.destroy();
    }
  }

  private static formatCityField(c: string | string[] | undefined): string {
    if (c === undefined) return '';
    return typeof c === 'string' ? c : (c.length > 0 ? c[0] : '');
  }

  // ==================== 数据构建 ====================

  private static buildMock(isDemo: boolean): WeatherSnapshot {
    const hint = isDemo
      ? '（演示数据）请确认 app_config.json 中 webKey 已配置'
      : '网络不可用或请求失败，请稍后重试';
    return {
      province: '湖南', city: '衡阳市', weather: '晴', temperature: '22',
      humidity: '56', windDirection: '南', windPower: '≤3',
      reportTime: '', hint, isMock: true, queryAdcode: undefined, noData: false
    };
  }

  private static buildNoData(adcode: string): WeatherSnapshot {
    return {
      province: '', city: '', weather: '暂无实况', temperature: '--',
      humidity: '--', windDirection: '', windPower: '',
      reportTime: '', hint: '该区域暂无气象实况数据',
      isMock: false, queryAdcode: adcode, noData: true
    };
  }

  private static hintFrom(weather: string, tempNum: number): string {
    if (weather.indexOf('雨') >= 0) return '有雨，记得带伞';
    if (weather.indexOf('雪') >= 0) return '降雪，注意保暖防滑';
    if (weather.indexOf('雾') >= 0 || weather.indexOf('霾') >= 0) return '能见度一般，注意安全';
    if (tempNum >= 30) return '气温较高，注意防晒补水';
    if (tempNum <= 5) return '气温较低，注意保暖';
    return '天气尚可，适合户外活动';
  }
}
