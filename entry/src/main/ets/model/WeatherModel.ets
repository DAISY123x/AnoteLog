/**
 * @file WeatherModel.ets
 * @brief 天气展示用数据模型
 * @description WeatherService 输出结构，供顶栏胶囊与弹窗复用
 */

/** 当前天气快照（实况，高德 lives[0] 映射） */
export interface WeatherSnapshot {
  province: string;
  city: string;
  weather: string;
  temperature: string;
  humidity: string;
  windDirection: string;
  windPower: string;
  reportTime: string;
  /** 出行短句（本地规则生成） */
  hint: string;
  /** 是否为模拟/降级数据 */
  isMock: boolean;
  /** 本次天气查询使用的 city（adcode），便于对照高德文档 */
  queryAdcode?: string;
  /** 高德返回 lives 为空等业务无数据 */
  noData?: boolean;
  /** 因首查失败而使用配置默认城市时，展示给用户的说明 */
  fallbackTip?: string;
}
