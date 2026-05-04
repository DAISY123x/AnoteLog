/**
 * @file ConfigService.ets
 * @brief 配置服务
 * @description 统一读取 app_config.json 配置文件，安全管理敏感配置（API Key 等）
 * @important 禁止硬编码 API Key，所有密钥必须通过此服务读取
 * @see app_config.json
 */
import common from '@ohos.app.ability.common';
import { Logger } from '../utils/Logger';

const TAG = 'ConfigService';

interface AIConfig {
  provider: string;
  apiUrl: string;
  model: string;
  apiKey: string;
  maxTokens: number;
  temperature: number;
  cacheTtlMinutes: number;
}

interface MapConfig {
  provider: string;
  language: string;
}

interface ApiConfig {
  enabled: boolean;
  baseUrl: string;
  timeout: number;
}

interface WeatherConfigRaw {
  provider?: string;
  language?: string;
  webKey?: string;
  apiKey?: string;
  defaultAdcode?: string;
}

/** 归一化后的天气配置（供 WeatherService 使用） */
export interface WeatherConfig {
  provider: string;
  language: string;
  webKey: string;
  defaultAdcode: string;
}

interface AppConfig {
  api?: ApiConfig;
  ai: AIConfig;
  map: MapConfig;
  weather?: WeatherConfigRaw;
}

export class ConfigService {
  private static instance: ConfigService;
  private config: AppConfig | null = null;
  private loaded: boolean = false;
  private readyResolve: ((v: void) => void) | null = null;
  public readonly ready: Promise<void>;

  private constructor() {
    this.ready = new Promise<void>((resolve) => {
      this.readyResolve = resolve;
    });
  }

  public static getInstance(): ConfigService {
    if (!ConfigService.instance) {
      ConfigService.instance = new ConfigService();
    }
    return ConfigService.instance;
  }

  /**
   * 初始化配置（需在 EntryAbility.onCreate 中调用，ConfigService.init 必须在 AIService.init 之前）
   */
  /**
   * rawfile UTF-8 解码（跳过 BOM）。逐字节 charCode 会破坏 BOM 与中文，导致 JSON.parse 失败并落入空 webKey 降级。
   */
  private static decodeUtf8RawFile(raw: Uint8Array): string {
    let i = 0;
    if (raw.length >= 3 && raw[0] === 0xEF && raw[1] === 0xBB && raw[2] === 0xBF) {
      i = 3;
      Logger.info(TAG, 'app_config.json: skipped UTF-8 BOM');
    }
    let out = '';
    while (i < raw.length) {
      const c = raw[i++];
      if (c < 0x80) {
        out += String.fromCharCode(c);
      } else if ((c & 0xE0) === 0xC0 && i < raw.length) {
        out += String.fromCharCode(((c & 0x1F) << 6) | (raw[i++] & 0x3F));
      } else if ((c & 0xF0) === 0xE0 && i + 1 < raw.length) {
        out += String.fromCharCode(((c & 0x0F) << 12) | ((raw[i] & 0x3F) << 6) | (raw[i + 1] & 0x3F));
        i += 2;
      } else if ((c & 0xF8) === 0xF0 && i + 2 < raw.length) {
        let codePoint =
          ((c & 0x07) << 18) |
          ((raw[i] & 0x3F) << 12) |
          ((raw[i + 1] & 0x3F) << 6) |
          (raw[i + 2] & 0x3F);
        i += 3;
        codePoint -= 0x10000;
        out += String.fromCharCode(0xD800 + (codePoint >> 10), 0xDC00 + (codePoint & 0x3FF));
      } else {
        out += '\uFFFD';
      }
    }
    return out;
  }

  public async init(context: common.UIAbilityContext): Promise<void> {
    if (this.loaded) {
      return;
    }

    try {
      const resourceMgr = context.resourceManager;
      const rawData: Uint8Array = await resourceMgr.getRawFileContent('app_config.json');
      const jsonStr = ConfigService.decodeUtf8RawFile(rawData);
      this.config = JSON.parse(jsonStr) as AppConfig;
      this.loaded = true;
      const wk = (this.config.weather?.webKey ?? this.config.weather?.apiKey ?? '').toString().trim();
      Logger.info(TAG, `ConfigService initialized OK; weather.webKey length=${wk.length}`);
      this.readyResolve?.();
    } catch (err) {
      const e = err as Error;
      Logger.error(TAG, `Failed to load app_config.json: ${e.message}`);
      // 降级：使用默认空配置，确保服务可运行
      this.config = {
        ai: {
          provider: 'deepseek',
          apiUrl: 'https://api.deepseek.com/v1/chat/completions',
          model: 'deepseek-chat',
          apiKey: '',
          maxTokens: 500,
          temperature: 0.7,
          cacheTtlMinutes: 30
        },
        map: {
          provider: 'huawei',
          language: 'zh-CN'
        },
        weather: {
          provider: 'gaode',
          language: 'zh-CN',
          webKey: '',
          defaultAdcode: '110000'
        }
      };
      this.loaded = true;
      this.readyResolve?.();
    }
  }

  /**
   * 获取 AI 配置
   * @returns AIConfig
   */
  public getAIConfig(): AIConfig {
    if (!this.config) {
      Logger.warn(TAG, 'Config not loaded, returning default AI config');
      return {
        provider: 'deepseek',
        apiUrl: 'https://api.deepseek.com/v1/chat/completions',
        model: 'deepseek-chat',
        apiKey: '',
        maxTokens: 500,
        temperature: 0.7,
        cacheTtlMinutes: 30
      };
    }
    return this.config.ai;
  }

  /**
   * 获取地图配置
   * @returns MapConfig
   */
  public getMapConfig(): MapConfig {
    if (!this.config) {
      return { provider: 'huawei', language: 'zh-CN' };
    }
    return this.config.map;
  }

  /**
   * 天气配置（高德 Web Key 等）
   */
  public getWeatherConfig(): WeatherConfig {
    if (this.config === null) {
      Logger.warn(TAG, 'getWeatherConfig: config null，请确认 EntryAbility 已 await ConfigService.init');
    } else if (this.config.weather === undefined) {
      Logger.warn(TAG, 'getWeatherConfig: app_config 缺少 weather 段');
    }
    const w = this.config?.weather;
    const keyRaw = w?.webKey ?? w?.apiKey ?? '';
    const key = typeof keyRaw === 'string' ? keyRaw : '';
    const trimmed = key.trim();
    if (trimmed.length === 0 && this.config !== null) {
      Logger.warn(TAG, 'getWeatherConfig: webKey/apiKey 为空（若刚修 BOM 请 Clean 重装 HAP）');
    }
    const ad = w?.defaultAdcode;
    return {
      provider: w?.provider ?? 'gaode',
      language: w?.language ?? 'zh-CN',
      webKey: trimmed,
      defaultAdcode: (ad !== undefined && ad.length > 0) ? ad : '110000'
    };
  }

  /**
   * 检查 API Key 是否已配置
   * @returns boolean
   */
  public hasAPIKey(): boolean {
    if (!this.config) return false;
    return !!this.config.ai.apiKey && this.config.ai.apiKey !== '' && this.config.ai.apiKey !== 'YOUR_DEEPSEEK_API_KEY_HERE';
  }

  /**
   * 获取后端 API 配置
   * @returns ApiConfig
   */
  public getApiConfig(): ApiConfig {
    if (!this.config?.api) {
      return { enabled: false, baseUrl: '', timeout: 30000 };
    }
    return this.config.api;
  }
}
