/**
 * @file AppConstants.ets
 * @brief 应用全局常量定义
 * @description 集中管理分页大小、缓存 key、存储 key 等常量
 */
export class AppConstants {
  // ==================== 分页配置 ====================
  static readonly PAGE_SIZE_DEFAULT: number = 15;
  static readonly PAGE_SIZE_SMALL: number = 10;
  static readonly PAGE_SIZE_LARGE: number = 20;

  // ==================== 存储 Keys ====================
  static readonly PREF_AUTH: string = 'auth_prefs';
  static readonly PREF_AI_CACHE: string = 'ai_cache_store';
  static readonly STORAGE_KEY_IS_LOGIN: string = 'isLogin';
  static readonly STORAGE_KEY_USER_INFO: string = 'userInfo';
  static readonly STORAGE_KEY_SELECTED_SEARCH: string = 'selectedSearchResult';
  static readonly STORAGE_KEY_NETWORK_AVAILABLE: string = 'isNetworkAvailable';

  // ==================== AI 配置 ====================
  static readonly AI_CACHE_TTL_MS: number = 30 * 60 * 1000; // 30 min
  static readonly AI_REQUEST_TIMEOUT_MS: number = 60000;
  static readonly AI_MAX_RETRIES: number = 3;
  static readonly AI_MAX_TOKENS: number = 500;

  // ==================== 笔记分类 ====================
  static readonly NOTE_CATEGORIES: string[] = ['经验', '美食', '住宿', '交通', '景点'];
  static readonly NOTE_CATEGORY_DEFAULT: string = '经验';

  // ==================== 地点类型 ====================
  static readonly PLACE_TYPES: string[] = ['景点', '美食', '酒店', '交通', '购物', '其他'];
  static readonly PLACE_TYPE_DEFAULT: string = '景点';

  // ==================== 行程状态 ====================
  static readonly TRIP_STATUS_PLANNING: string = 'planning';
  static readonly TRIP_STATUS_ONGOING: string = 'ongoing';
  static readonly TRIP_STATUS_COMPLETED: string = 'completed';

  // ==================== 数据库配置 ====================
  static readonly DB_NAME: string = 'Anote.db';
  static readonly DB_SECURITY_LEVEL: string = 'S1';
}
