/**
 * @file PlaceImageService.ets
 * @brief 高德 Web 景点图片服务
 * @description 通过高德 /v3/place/text 接口搜索景点，再取结果中的 photos 字段作为真实照片 URL。
 * Key 仅从 ConfigService 读取；无 Key、搜索无结果或无照片时返回 null，不影响主流程。
 */
import http from '@ohos.net.http';
import { ConfigService } from './ConfigService';
import { Logger } from '../utils/Logger';

const TAG = 'PlaceImageService';

interface AmapPhoto {
  title?: string;
  url?: string;
}

interface AmapPoi {
  id?: string;
  name?: string;
  location?: string;
  address?: string;
  photos?: AmapPhoto[];
}

interface AmapPlaceTextJson {
  status?: string;
  info?: string;
  infocode?: string;
  count?: string;
  pois?: AmapPoi[];
}

export class PlaceImageService {
  private static instance: PlaceImageService;
  private cache: Map<string, string | null> = new Map();
  private cacheTime: Map<string, number> = new Map();
  private readonly TTL_MS: number = 60 * 60 * 1000;

  private constructor() {
  }

  static getInstance(): PlaceImageService {
    if (!PlaceImageService.instance) {
      PlaceImageService.instance = new PlaceImageService();
    }
    return PlaceImageService.instance;
  }

  private httpGet(url: string): Promise<string> {
    const req = http.createHttp();
    return new Promise<string>((resolve, reject): void => {
      req.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      }).then((res) => {
        if (res.responseCode === 200) {
          resolve(String(res.result));
        } else {
          reject(new Error(`http ${res.responseCode}`));
        }
      }).catch((e: Error) => {
        reject(e);
      }).finally((): void => {
        req.destroy();
      });
    });
  }

  private maskKey(key: string): string {
    if (key.length <= 8) {
      return '****';
    }
    return `${key.substring(0, 4)}****${key.substring(key.length - 4)}`;
  }

  /**
   * 根据景点名称获取第一张高德真实照片 URL。
   * 使用 /v3/place/text?keywords=景点名 搜索 POI，再取 photos[0].url。
   * 结果缓存 60 分钟；有 Key 但无结果 / 无照片时返回 null。
   */
  async getPhotoUrl(name: string): Promise<string | null> {
    const now: number = Date.now();

    if (this.cache.has(name)) {
      const t: number = this.cacheTime.get(name) ?? 0;
      if (now - t < this.TTL_MS) {
        const cached: string | null = this.cache.get(name) ?? null;
        Logger.info(TAG, `getPhotoUrl: "${name}" cache hit=${cached !== null}`);
        return cached;
      }
    }

    const cfg = ConfigService.getInstance().getWeatherConfig();
    const key: string = cfg.webKey;
    if (key.length === 0) {
      Logger.warn(TAG, `getPhotoUrl: "${name}" 无 webKey，跳过`);
      this.cache.set(name, null);
      this.cacheTime.set(name, now);
      return null;
    }

    const url: string =
      `https://restapi.amap.com/v3/place/text?keywords=${encodeURIComponent(name)}` +
        `&city=全国&citylimit=false&key=${encodeURIComponent(key)}&extensions=photos`;
    Logger.info(TAG, `getPhotoUrl: "${name}" key=${this.maskKey(key)}`);

    try {
      const text: string = await this.httpGet(url);
      const preview: string = text.length > 400 ? `${text.substring(0, 400)}...` : text;
      Logger.info(TAG, `getPhotoUrl: "${name}" raw=${preview}`);

      const j: AmapPlaceTextJson = JSON.parse(text) as AmapPlaceTextJson;
      if (j.status !== '1') {
        Logger.warn(TAG, `getPhotoUrl: "${name}" status!=1 info=${j.info}`);
        this.cache.set(name, null);
        this.cacheTime.set(name, now);
        return null;
      }

      const count: number = parseInt(j.count ?? '0', 10);
      if (count <= 0 || !j.pois || j.pois.length === 0) {
        Logger.info(TAG, `getPhotoUrl: "${name}" count=${count} 无POI结果`);
        this.cache.set(name, null);
        this.cacheTime.set(name, now);
        return null;
      }

      const photo: string | undefined = j.pois[0].photos?.[0]?.url;
      if (photo && photo.length > 0) {
        Logger.info(TAG, `getPhotoUrl: "${name}" 照片 url=${photo.substring(0, 80)}...`);
        this.cache.set(name, photo);
        this.cacheTime.set(name, now);
        return photo;
      }

      Logger.info(TAG, `getPhotoUrl: "${name}" POI存在但无照片`);
      this.cache.set(name, null);
      this.cacheTime.set(name, now);
      return null;
    } catch (e) {
      Logger.error(TAG, `getPhotoUrl: "${name}" 请求失败 ${JSON.stringify(e)}`);
      this.cache.set(name, null);
      this.cacheTime.set(name, now);
      return null;
    }
  }

  invalidate(name: string): void {
    this.cache.delete(name);
    this.cacheTime.delete(name);
  }
}
