/**
 * @file TripDAO.ets
 * @brief 行程数据访问层（DAO）
 * @description 封装行程相关的高级查询逻辑，内部委托 TripRepository 执行数据库操作
 * @deprecated 推荐直接使用 TripRepository 以减少中间层
 * @see TripRepository, Trip
 */
import { Trip } from '../model/TripModel';
import { TripRepository } from '../repository/TripRepository';
import { Logger } from '../utils/Logger';

const TAG = 'TripDAO';

export class TripDAO {
  private static repository: TripRepository = new TripRepository();

  /**
   * 获取待完成行程 (planning 或 ongoing)
   * @returns Promise<Trip[]>
   */
  static async getPendingTrips(): Promise<Trip[]> {
    Logger.debug(TAG, '获取待完成行程');
    try {
      return await TripDAO.repository.getPendingTrips();
    } catch (e) {
      Logger.error(TAG, `获取待完成行程失败: ${e}`);
      throw e as Error;
    }
  }
}
