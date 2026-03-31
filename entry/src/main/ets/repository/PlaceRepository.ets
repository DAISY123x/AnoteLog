/**
 * @file PlaceRepository.ets
 * @brief 地点数据访问层
 * @description 负责 saved_place 和 custom_place 表的完整 CRUD
 * @see RdbManager, CustomPlace, DbPlace
 */
import { CustomPlace } from '../model/CustomPlaceModel';
import { RdbManager, DbPlace } from '../common/database/RdbManager';
import { Logger } from '../utils/Logger';

const TAG = 'PlaceRepository';

// ==================== 收藏地点 (saved_place) ====================

export class PlaceRepository {
  /**
   * 根据 ID 获取自定义地点
   * @param id 地点 ID
   * @returns CustomPlace 或 null
   */
  async getCustomPlaceById(id: number): Promise<CustomPlace | null> {
    return RdbManager.getInstance().getCustomPlaceById(id);
  }

  /**
   * 获取所有自定义地点
   * @param keyword 搜索关键词（可选）
   * @returns CustomPlace[]
   */
  async getAllCustomPlaces(keyword?: string): Promise<CustomPlace[]> {
    return RdbManager.getInstance().getCustomPlaces(undefined, undefined, keyword);
  }

  /**
   * 新增自定义地点
   * @param place 地点实体
   * @returns 新记录 ID
   */
  async insertCustomPlace(place: CustomPlace): Promise<number> {
    Logger.info(TAG, `insertCustomPlace: Adding "${place.name}"`);
    return RdbManager.getInstance().insertCustomPlace(place);
  }

  /**
   * 更新自定义地点
   * @param place 地点实体
   * @returns 受影响行数
   */
  async updateCustomPlace(place: CustomPlace): Promise<number> {
    Logger.info(TAG, `updateCustomPlace: Updating ${place.id}`);
    return RdbManager.getInstance().updateCustomPlace(place);
  }

  /**
   * 删除自定义地点
   * @param id 地点 ID
   * @returns 受影响行数
   */
  async deleteCustomPlace(id: number): Promise<number> {
    Logger.info(TAG, `deleteCustomPlace: Deleting ${id}`);
    return RdbManager.getInstance().deleteCustomPlace(id);
  }

  /**
   * 检查地点是否重复（同名 + 同坐标）
   * @param name 地点名称
   * @param lat 纬度
   * @param lng 经度
   * @returns boolean
   */
  async isDuplicate(name: string, lat: number, lng: number): Promise<boolean> {
    return RdbManager.getInstance().checkCustomPlaceDuplicate(name, lat, lng);
  }

  // ==================== 收藏地点 (saved_place) ====================

  /**
   * 收藏地点
   * @param place 地点信息
   * @returns 收藏记录 ID
   */
  async savePlace(place: DbPlace): Promise<number> {
    Logger.info(TAG, `savePlace: Saving "${place.title}"`);
    return RdbManager.getInstance().savePlace(place);
  }
}
