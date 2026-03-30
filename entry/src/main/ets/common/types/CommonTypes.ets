/**
 * @file CommonTypes.ets
 * @brief 应用通用类型定义
 * @description 抽取散布在各处的内联 interface，统一管理
 */

// ==================== 首页相关类型 ====================

/**
 * 首页 Banner 项目
 */
export interface BannerItem {
  id: number;
  imageSrc: string;
  title: string;
}

/**
 * 首页功能卡片
 */
export interface FunctionalCardItem {
  id: number;
  title: string;
  icon: ResourceStr;
  colors: [ResourceColor, number][];
  shadowColor: string;
}

/**
 * 首页推荐行程卡片
 */
export interface UserTripItem {
  id: number;
  userName: string;
  userAvatar: string;
  imageSrc: string;
  title: string;
  date: string;
  location: string;
  likes: number;
}

// ==================== 通知相关类型 ====================

/**
 * 通知项
 */
export interface NotificationItem {
  id: number;
  title: string;
  content: string;
  time: string;
  isRead: boolean;
}

// ==================== 搜索相关类型 ====================

/**
 * 搜索结果项 (SearchPage 内部使用)
 */
export interface SearchResult {
  id: number | string;
  title: string;
  address: string;
  type: string;
  icon?: string;
  latitude?: number;
  longitude?: number;
}

// ==================== 通用类型别名 ====================

/**
 * 行程状态
 */
export type TripStatus = 'planning' | 'ongoing' | 'completed';

/**
 * 点赞类型
 */
export type LikeType = 'note' | 'place';

/**
 * HTTP 请求方法
 */
export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
