/**
 * @file ApiService.ets
 * @brief 后端API服务
 * @description 统一封装HTTP请求，智能降级：后端可用时使用真实接口，后端不可用时自动降级到本地数据
 * @see ConfigService, MockService
 */
import http from '@ohos.net.http';
import { ConfigService } from '../../service/ConfigService';
import { Logger } from '../../utils/Logger';

const TAG = 'ApiService';

// ==================== 导出类型定义 ====================

/** API 统一响应结构（与后端 Result<T> 对应） */
export interface ApiResponse<T> {
  code: number;
  msg: string;
  data: T;
}

/** API 分页响应结构 */
export interface ApiPageResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  first: boolean;
  last: boolean;
}

/** 用户信息 DTO */
export interface ApiUser {
  id: number;
  unionId: string;
  nickname: string;
  avatar: string;
  signature?: string;
}

/** 登录响应 DTO */
export interface ApiLoginResponse {
  token: string;
  userId: number;
  unionId: string;
  nickname: string;
  avatar: string;
}

/** 笔记 DTO */
export interface ApiNote {
  id: number;
  userId: number;
  title: string;
  content: string;
  location: string;
  images: string[];
  category: string;
  isShared: boolean;
  createTime: string;
  updateTime: string;
}

/** 行程 DTO */
export interface ApiTrip {
  id: number;
  userId: number;
  name: string;
  location: string;
  coverImage?: string;
  status: string;
  startDate?: string;
  endDate?: string;
  createTime: string;
  updateTime: string;
  places?: ApiTripPlace[];
}

/** 行程地点 DTO */
export interface ApiTripPlace {
  id: number;
  tripId: number;
  title: string;
  type: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  distanceKm?: number;
  durationMin?: number;
  note?: string;
  orderIndex: number;
  dayIndex: number;
}

/** 自定义地点 DTO */
export interface ApiPlace {
  id: number;
  userId: number;
  name: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  type?: string;
  contact?: string;
  createTime: string;
  updateTime: string;
}

/** 点赞信息 DTO */
export interface ApiLike {
  id: number;
  userId: number;
  targetId: number;
  targetType: string;
  createTime: string;
}

/** 反馈响应 DTO */
export interface FeedbackIdResponse {
  id: number;
}

// ==================== 内部请求体类型（避免 ArkTS 对象字面量类型问题） ====================

class MockLoginBody {
  unionId: string = '';
  nickname: string = '';
  avatarUrl: string = '';
}

class ToggleLikeBody {
  targetId: number = 0;
  targetType: string = '';
}

class SubmitFeedbackBody {
  content: string = '';
  contact: string = '';
}

class NoteBody {
  title: string = '';
  content: string = '';
  location: string = '';
  images: string[] = [];
  category: string = '';
  isShared: boolean = false;
}

class TripBody {
  name: string = '';
  location: string = '';
  coverImage: string = '';
  status: string = '';
  startDate: string = '';
  endDate: string = '';
}

class TripUpdateBody {
  name: string = '';
  location: string = '';
  coverImage: string = '';
  status: string = '';
  startDate: string = '';
  endDate: string = '';
}

class PlaceBody {
  title: string = '';
  type: string = '';
  address: string = '';
  latitude: number = 0;
  longitude: number = 0;
  distanceKm: number = 0;
  durationMin: number = 0;
  note: string = '';
  orderIndex: number = 0;
  dayIndex: number = 0;
}

class PlaceUpdateBody {
  title: string = '';
  type: string = '';
  address: string = '';
  latitude: number = 0;
  longitude: number = 0;
  distanceKm: number = 0;
  durationMin: number = 0;
  note: string = '';
  orderIndex: number = 0;
  dayIndex: number = 0;
}

class CustomPlaceBody {
  name: string = '';
  address: string = '';
  latitude: number = 0;
  longitude: number = 0;
  type: string = '';
  contact: string = '';
}

class CustomPlaceUpdateBody {
  name: string = '';
  address: string = '';
  latitude: number = 0;
  longitude: number = 0;
  type: string = '';
  contact: string = '';
}

// ==================== ApiService 主类 ====================

export class ApiService {
  private static instance: ApiService;
  private baseUrl: string = '';
  private token: string = '';
  private initialized: boolean = false;

  private constructor() {}

  public static getInstance(): ApiService {
    if (!ApiService.instance) {
      ApiService.instance = new ApiService();
    }
    return ApiService.instance;
  }

  public async init(baseUrl: string): Promise<void> {
    this.baseUrl = baseUrl;
    try {
      const cfg = ConfigService.getInstance().getApiConfig();
      if (cfg && cfg.enabled === false) {
        Logger.info(TAG, `ApiService init: API disabled, using fallback`);
        this.initialized = false;
        return;
      }
    } catch (_e) { /* continue */ }

    const ok: boolean = await this.ping();
    this.initialized = ok;
    Logger.info(TAG, `ApiService init: ${baseUrl}, backend=${ok ? 'ONLINE' : 'OFFLINE (fallback)'}`);
  }

  private async ping(): Promise<boolean> {
    const httpClient = http.createHttp();
    try {
      const resp = await httpClient.request(this.baseUrl + '/health', {
        method: 'GET' as http.RequestMethod,
        header: { 'Content-Type': 'application/json' },
        connectTimeout: 3000,
        readTimeout: 3000
      });
      return resp.responseCode >= 200 && resp.responseCode < 300;
    } catch (_e) {
      return false;
    } finally {
      httpClient.destroy();
    }
  }

  public setToken(token: string): void {
    this.token = token;
    Logger.info(TAG, `Token set, len=${token.length}`);
  }

  public getToken(): string {
    return this.token;
  }

  public clearToken(): void {
    this.token = '';
    Logger.info(TAG, 'Token cleared');
  }

  // ==================== HTTP 请求方法 ====================
  private buildQueryString(params: Record<string, string>): string {
    const keys: string[] = Object.keys(params);
    let result = '';
    for (let i = 0; i < keys.length; i++) {
      const k = keys[i];
      if (i > 0) {
        result += '&';
      }
      result += encodeURIComponent(k) + '=' + encodeURIComponent(params[k]);
    }
    return result;
  }

  private async get<T>(path: string, params?: Record<string, string>): Promise<ApiResponse<T>> {
    let url = this.baseUrl + path;
    if (params) {
      const qs = this.buildQueryString(params);
      if (qs.length > 0) {
        url = url + '?' + qs;
      }
    }
    return this.request<T>(url, 'GET');
  }

  private async post<T>(path: string, body: object): Promise<ApiResponse<T>> {
    return this.request<T>(this.baseUrl + path, 'POST', body);
  }

  private async put<T>(path: string, body: object): Promise<ApiResponse<T>> {
    return this.request<T>(this.baseUrl + path, 'PUT', body);
  }

  private async delete<T>(path: string): Promise<ApiResponse<T>> {
    return this.request<T>(this.baseUrl + path, 'DELETE');
  }

  private async request<T>(url: string, method: string, body?: object): Promise<ApiResponse<T>> {
    if (!this.initialized || !this.baseUrl) {
      Logger.warn(TAG, `API not init, fallback: ${method} ${url}`);
      return this.fallbackResponse<T>();
    }
    try {
      const cfg = ConfigService.getInstance().getApiConfig();
      if (cfg && cfg.enabled === false) {
        Logger.info(TAG, `API disabled, fallback: ${method} ${url}`);
        return this.fallbackResponse<T>();
      }
    } catch (_e) {
      // continue
    }

    const httpClient = http.createHttp();
    try {
      const header: Record<string, string> = {
        'Content-Type': 'application/json'
      };
      if (this.token.length > 0) {
        header['Authorization'] = 'Bearer ' + this.token;
      }
      const options: http.HttpRequestOptions = {
        method: method as http.RequestMethod,
        header: header,
        connectTimeout: 10000,
        readTimeout: 10000
      };
      if (body && (method === 'POST' || method === 'PUT')) {
        options.extraData = JSON.stringify(body);
      }
      Logger.info(TAG, `[API] ${method} ${url}`);
      const resp = await httpClient.request(url, options);
      const code = resp.responseCode;
      if (code >= 200 && code < 300) {
        const str: string = resp.result as string;
        Logger.info(TAG, `[API] OK: ${method} ${url} -> ${code}`);
        return JSON.parse(str) as ApiResponse<T>;
      } else {
        Logger.warn(TAG, `[API] HTTP ${code}: ${method} ${url}`);
        return this.fallbackResponse<T>();
      }
    } catch (err) {
      Logger.error(TAG, `[API] Error: ${method} ${url}`, err);
      return this.fallbackResponse<T>();
    } finally {
      httpClient.destroy();
    }
  }

  private fallbackResponse<T>(): ApiResponse<T> {
    Logger.warn(TAG, '[MOCK] fallback');
    return {
      code: 200,
      msg: 'success',
      data: null as T
    };
  }

  // ==================== 认证 ====================

  async mockLogin(unionId: string, nickname: string, avatarUrl: string): Promise<ApiResponse<ApiLoginResponse>> {
    const body = new MockLoginBody();
    body.unionId = unionId;
    body.nickname = nickname;
    body.avatarUrl = avatarUrl;
    return this.post<ApiLoginResponse>('/api/auth/huawei/mock-login', body as object);
  }

  async getMe(): Promise<ApiResponse<ApiUser>> {
    return this.get<ApiUser>('/api/auth/me');
  }

  // ==================== 笔记 ====================

  async getNotes(page: number, size: number, category?: string): Promise<ApiResponse<ApiPageResponse<ApiNote>>> {
    const params: Record<string, string> = {};
    params['page'] = page.toString();
    params['size'] = size.toString();
    if (category !== undefined && category !== '全部') {
      params['category'] = category;
    }
    return this.get<ApiPageResponse<ApiNote>>('/api/notes', params);
  }

  async getNoteById(id: number): Promise<ApiResponse<ApiNote>> {
    return this.get<ApiNote>('/api/notes/' + id.toString());
  }

  async createNote(title: string, content: string, location: string, images: string[], category: string, isShared: boolean): Promise<ApiResponse<ApiNote>> {
    const body = new NoteBody();
    body.title = title;
    body.content = content;
    body.location = location;
    body.images = images;
    body.category = category;
    body.isShared = isShared;
    return this.post<ApiNote>('/api/notes', body as object);
  }

  async updateNote(id: number, title: string, content: string, location: string, category: string, isShared: boolean): Promise<ApiResponse<ApiNote>> {
    const body = new NoteBody();
    body.title = title;
    body.content = content;
    body.location = location;
    body.category = category;
    body.isShared = isShared;
    return this.put<ApiNote>('/api/notes/' + id.toString(), body as object);
  }

  async deleteNote(id: number): Promise<ApiResponse<null>> {
    return this.delete<null>('/api/notes/' + id.toString());
  }

  async getSharedNotes(page: number, size: number): Promise<ApiResponse<ApiPageResponse<ApiNote>>> {
    const params: Record<string, string> = {};
    params['page'] = page.toString();
    params['size'] = size.toString();
    return this.get<ApiPageResponse<ApiNote>>('/api/notes/shared', params);
  }

  // ==================== 行程 ====================

  async getTrips(page: number, size: number, status?: string): Promise<ApiResponse<ApiPageResponse<ApiTrip>>> {
    const params: Record<string, string> = {};
    params['page'] = page.toString();
    params['size'] = size.toString();
    if (status !== undefined && status !== 'all') {
      params['status'] = status;
    }
    return this.get<ApiPageResponse<ApiTrip>>('/api/trips', params);
  }

  async getTripById(id: number): Promise<ApiResponse<ApiTrip>> {
    return this.get<ApiTrip>('/api/trips/' + id.toString());
  }

  async createTrip(name: string, location: string, coverImage: string, status: string, startDate: string, endDate: string): Promise<ApiResponse<ApiTrip>> {
    const body = new TripBody();
    body.name = name;
    body.location = location;
    body.coverImage = coverImage;
    body.status = status;
    body.startDate = startDate;
    body.endDate = endDate;
    return this.post<ApiTrip>('/api/trips', body as object);
  }

  async updateTrip(id: number, name: string, location: string, coverImage: string, status: string, startDate: string, endDate: string): Promise<ApiResponse<ApiTrip>> {
    const body = new TripUpdateBody();
    body.name = name;
    body.location = location;
    body.coverImage = coverImage;
    body.status = status;
    body.startDate = startDate;
    body.endDate = endDate;
    return this.put<ApiTrip>('/api/trips/' + id.toString(), body as object);
  }

  async deleteTrip(id: number): Promise<ApiResponse<null>> {
    return this.delete<null>('/api/trips/' + id.toString());
  }

  async addPlaceToTrip(tripId: number, title: string, type: string, address: string, lat: number, lng: number,
    distKm: number, durMin: number, note: string, orderIdx: number, dayIdx: number): Promise<ApiResponse<ApiTripPlace>> {
    const body = new PlaceBody();
    body.title = title;
    body.type = type;
    body.address = address;
    body.latitude = lat;
    body.longitude = lng;
    body.distanceKm = distKm;
    body.durationMin = durMin;
    body.note = note;
    body.orderIndex = orderIdx;
    body.dayIndex = dayIdx;
    return this.post<ApiTripPlace>('/api/trips/' + tripId.toString() + '/places', body as object);
  }

  async updateTripPlace(tripId: number, placeId: number, title: string, type: string, address: string, lat: number, lng: number,
    distKm: number, durMin: number, note: string, orderIdx: number, dayIdx: number): Promise<ApiResponse<ApiTripPlace>> {
    const body = new PlaceUpdateBody();
    body.title = title;
    body.type = type;
    body.address = address;
    body.latitude = lat;
    body.longitude = lng;
    body.distanceKm = distKm;
    body.durationMin = durMin;
    body.note = note;
    body.orderIndex = orderIdx;
    body.dayIndex = dayIdx;
    return this.put<ApiTripPlace>('/api/trips/' + tripId.toString() + '/places/' + placeId.toString(), body as object);
  }

  async removePlaceFromTrip(tripId: number, placeId: number): Promise<ApiResponse<null>> {
    return this.delete<null>('/api/trips/' + tripId.toString() + '/places/' + placeId.toString());
  }

  // ==================== 地点 ====================

  async getPlaces(): Promise<ApiResponse<ApiPlace[]>> {
    return this.get<ApiPlace[]>('/api/places');
  }

  async getPlaceById(id: number): Promise<ApiResponse<ApiPlace>> {
    return this.get<ApiPlace>('/api/places/' + id.toString());
  }

  async createPlace(name: string, address: string, lat: number, lng: number, type: string, contact: string): Promise<ApiResponse<ApiPlace>> {
    const body = new CustomPlaceBody();
    body.name = name;
    body.address = address;
    body.latitude = lat;
    body.longitude = lng;
    body.type = type;
    body.contact = contact;
    return this.post<ApiPlace>('/api/places', body as object);
  }

  async updatePlace(id: number, name: string, address: string, lat: number, lng: number, type: string, contact: string): Promise<ApiResponse<ApiPlace>> {
    const body = new CustomPlaceUpdateBody();
    body.name = name;
    body.address = address;
    body.latitude = lat;
    body.longitude = lng;
    body.type = type;
    body.contact = contact;
    return this.put<ApiPlace>('/api/places/' + id.toString(), body as object);
  }

  async deletePlace(id: number): Promise<ApiResponse<null>> {
    return this.delete<null>('/api/places/' + id.toString());
  }

  // ==================== 点赞 ====================

  async toggleLike(targetId: number, targetType: string): Promise<ApiResponse<boolean>> {
    const body = new ToggleLikeBody();
    body.targetId = targetId;
    body.targetType = targetType;
    return this.post<boolean>('/api/likes', body as object);
  }

  async getLikes(page: number, size: number, type?: string): Promise<ApiResponse<ApiPageResponse<ApiLike>>> {
    const params: Record<string, string> = {};
    params['page'] = page.toString();
    params['size'] = size.toString();
    if (type !== undefined) {
      params['type'] = type;
    }
    return this.get<ApiPageResponse<ApiLike>>('/api/likes', params);
  }

  async checkLike(targetId: number, targetType: string): Promise<ApiResponse<boolean>> {
    const params: Record<string, string> = {};
    params['targetId'] = targetId.toString();
    params['targetType'] = targetType;
    return this.get<boolean>('/api/likes/check', params);
  }

  // ==================== 反馈 ====================

  async submitFeedback(content: string, contact: string): Promise<ApiResponse<FeedbackIdResponse>> {
    const body = new SubmitFeedbackBody();
    body.content = content;
    body.contact = contact;
    return this.post<FeedbackIdResponse>('/api/feedback', body as object);
  }
}
