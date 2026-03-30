import { RdbManager } from '../common/database/RdbManager';
import { Trip } from '../model/TripModel';
import { Logger } from '../utils/Logger';

export class TripDAO {
  /**
   * 获取待完成行程 (planning 或 ongoing)
   * @returns Promise<Trip[]>
   */
  static async getPendingTrips(): Promise<Trip[]> {
    Logger.debug('TripDAO', '获取待完成行程');
    console.log('[DEBUG] TripDAO: 获取待完成行程');
    try {
      // 获取所有行程并在内存中过滤，因为 RdbManager 目前支持单状态查询或全部查询
      const allTrips = await RdbManager.getInstance().getTrips(100, 0, '', 'all');
      return allTrips.filter(t => t.status === 'planning' || t.status === 'ongoing');
    } catch (e) {
      Logger.error('TripDAO', `获取待完成行程失败: ${e}`);
      console.error('[ERROR] TripDAO: 获取待完成行程失败', e);
      throw e as Error;
    }
  }
}
