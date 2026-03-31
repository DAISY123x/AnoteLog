import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { Logger } from '../utils/Logger';
import { ConfigService } from './ConfigService';

export interface AIRecommendation {
  id: number;
  title: string;
  reason: string;
  tags: string[];
}

// Optimized Interface
export interface AttractionDetail {
  id?: number;
  name?: string;
  description: string; // Simplified culture intro < 200 chars
  coverImageUrl: string;
  openingHours: string;
  address: string; // Detailed address
  tips: string; // Play suggestions (20 words)
  // Cache control
  _cacheTime?: number; 
}

interface GeneratedTypeLiteralInterface_1 {
  content: string;
}

export interface Choice {
  message: GeneratedTypeLiteralInterface_1;
}

export interface OpenAIResponse {
  choices: Choice[];
}

export class AIService {
  private static instance: AIService;
  private apiKey: string = '';
  private apiUrl: string = 'https://api.deepseek.com/v1/chat/completions';
  private cacheTtlMs: number = 30 * 60 * 1000; // 30 minutes

  private context: common.UIAbilityContext | null = null;
  private pref: preferences.Preferences | null = null;
  private memoryCache: Map<string, AttractionDetail> = new Map();
  private activeRequests: Map<string, http.HttpRequest> = new Map();

  private constructor() {
  }

  public static getInstance(): AIService {
    if (!AIService.instance) {
      AIService.instance = new AIService();
    }
    return AIService.instance;
  }

  public async init(context: common.UIAbilityContext) {
    this.context = context;
    try {
      this.pref = await preferences.getPreferences(context, 'ai_cache_store');
    } catch (e) {
      Logger.error('AIService', 'Failed to get preferences');
    }
    // 从 ConfigService 加载配置（注意：ConfigService.init 需在 AIService.init 之前调用）
    const aiConfig = ConfigService.getInstance().getAIConfig();
    this.apiKey = aiConfig.apiKey;
    this.apiUrl = aiConfig.apiUrl;
    this.cacheTtlMs = aiConfig.cacheTtlMinutes * 60 * 1000;
    Logger.info('AIService', `Configured with API URL: ${this.apiUrl}, hasKey: ${!!this.apiKey}`);
  }

  // Cancel an active request for a place
  public cancelRequest(placeName: string) {
    if (this.activeRequests.has(placeName)) {
      try {
        const req = this.activeRequests.get(placeName);
        req?.destroy();
        this.activeRequests.delete(placeName);
        Logger.info('AIService', `Cancelled request for ${placeName}`);
      } catch (e) {
        Logger.error('AIService', 'Cancel failed');
      }
    }
  }

  private async callLLM(systemPrompt: string, userPrompt: string, placeNameForCancel?: string): Promise<string> {
    const httpRequest = http.createHttp();
    
    if (placeNameForCancel) {
      this.activeRequests.set(placeNameForCancel, httpRequest);
    }

    try {
      const response = await httpRequest.request(
        this.apiUrl,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`
          },
          extraData: {
            model: "deepseek-chat",
            messages: [
              { role: "system", content: systemPrompt },
              { role: "user", content: userPrompt }
            ],
            max_tokens: 500, // Reduced max tokens for faster response
            temperature: 0.7,
            stream: false
          },
          expectDataType: http.HttpDataType.STRING,
          readTimeout: 60000,
          connectTimeout: 60000
        }
      );

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as OpenAIResponse;
        if (result.choices && result.choices.length > 0) {
          return result.choices[0].message.content;
        }
        return '';
      } else {
        Logger.error('AIService', `Error Code: ${response.responseCode}`);
        Logger.error('AIService', `Error Body: ${JSON.stringify(response.result)}`);
        return '';
      }
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('AIService', `Request Failed: ${error.message}`);
      return '';
    } finally {
      httpRequest.destroy();
      if (placeNameForCancel) {
        this.activeRequests.delete(placeNameForCancel);
      }
    }
  }

  public async getAttractionDetails(placeName: string): Promise<AttractionDetail> {
    const now = Date.now();

    // 1. Check Memory Cache with TTL
    if (this.memoryCache.has(placeName)) {
      const detail = this.memoryCache.get(placeName) as AttractionDetail;
      if (detail._cacheTime && (now - detail._cacheTime < this.cacheTtlMs)) {
        Logger.info('AIService', 'Hit Memory Cache for');
        return detail;
      } else {
        Logger.info('AIService', 'Memory Cache expired for');
        this.memoryCache.delete(placeName);
      }
    }

    // 2. Check Local Cache (Preferences) with TTL
    if (this.pref) {
      try {
        const cachedStr = await this.pref.get(placeName, '') as string;
        if (cachedStr) {
          const detail = JSON.parse(cachedStr) as AttractionDetail;
          if (detail._cacheTime && (now - detail._cacheTime < this.cacheTtlMs)) {
            Logger.info('AIService', 'Hit Local Cache for');
            this.memoryCache.set(placeName, detail); // Update memory
            return detail;
          } else {
            Logger.info('AIService', 'Local Cache expired for');
          }
        }
      } catch (e) {
        Logger.error('AIService', 'Local cache read failed');
      }
    }

    // 3. Fetch from API with Retry
    // Simplified Prompt as per requirements
    const systemPrompt = `你是一个导游助手。请返回JSON格式的景点信息。
    JSON格式:
    {
      "description": "200字以内的核心精简文化介绍",
      "openingHours": "开放时间",
      "address": "详细地址",
      "tips": "20字以内的游玩建议",
      "coverImageUrl": "封面图片URL"
    }
    注意:
    1. coverImageUrl 返回空字符串，前端处理默认图。
    2. 严格遵守JSON格式，不要返回其他文本。
    3. 去除经纬度、门票价格、消费建议等非必要信息。`;

    let retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        const rawData = await this.callLLM(systemPrompt, `介绍：${placeName}`, placeName);
        
        if (rawData) {
            const jsonStr = rawData.replace(/```json/g, '').replace(/```/g, '').trim();
            const detail = JSON.parse(jsonStr) as AttractionDetail;
            
            // Fill defaults
            if (!detail.coverImageUrl) {
                detail.coverImageUrl = 'app.media.background11';
            }
            detail.name = placeName;
            detail._cacheTime = Date.now();

            // Save Cache
            this.memoryCache.set(placeName, detail);
            if (this.pref) {
                await this.pref.put(placeName, JSON.stringify(detail));
                await this.pref.flush();
            }

            return detail;
        }
      } catch (e) {
        Logger.error('AIService', `Retry ${retryCount + 1} failed for ${placeName}`);
      }
      retryCount++;
    }

    // 4. Fallback Mock Data
    Logger.warn('AIService', 'All retries failed, returning mock data');
    return this.getMockData(placeName);
  }

  private getMockData(placeName: string): AttractionDetail {
    return {
      name: placeName,
      description: `${placeName} 是一个历史悠久的地方，拥有独特的文化底蕴和美丽的自然风光，非常值得一游。`,
      openingHours: '09:00 - 17:30',
      address: '北京市中心区域',
      tips: '建议错峰出行，注意防晒。',
      coverImageUrl: 'app.media.background11',
      _cacheTime: Date.now()
    };
  }

  // ... (Other methods remain unchanged)
  public async optimizeRoute(places: string[]): Promise<string[]> {
    const systemPrompt = `你是一个旅行规划专家。请根据用户提供的地点列表，规划一条地理位置上最优的游览路线。
    只返回排序后的地点名称数组 JSON，不要其他废话。`;

    const rawData = await this.callLLM(systemPrompt, `请对以下地点进行最优路线排序：${JSON.stringify(places)}`);

    if (rawData) {
      try {
        const jsonStr = rawData.replace(/```json/g, '').replace(/```/g, '').trim();
        return JSON.parse(jsonStr) as string[];
      } catch (e) {
        Logger.error('AIService', `JSON Parse Error: ${e}`);
      }
    }
    return [...places].reverse();
  }

  public async getTravelAdvice(query: string): Promise<string> {
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve(`根据您的需求"${query}"，我建议您可以去体验一下当地的特色美食，比如...（AI生成内容）`);
      }, 1000);
    });
  }

  public async recommendPlaces(currentCity: string): Promise<AIRecommendation[]> {
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve([
          {
            id: 201,
            title: '特色博物馆',
            reason: '距离您当前位置较近，且评价很高',
            tags: ['文化', '室内']
          },
          {
            id: 202,
            title: '网红咖啡馆',
            reason: '适合下午休息，拍照出片',
            tags: ['休闲', '美食']
          }
        ]);
      }, 800);
    });
  }
}
