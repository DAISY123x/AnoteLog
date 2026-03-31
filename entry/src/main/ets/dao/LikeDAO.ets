/**
 * @file LikeDAO.ets
 * @brief 点赞数据访问层（DAO）
 * @description 封装点赞相关的高级查询逻辑，内部委托 LikeRepository 执行数据库操作
 * @deprecated 推荐直接使用 LikeRepository 以减少中间层
 * @see LikeRepository, Note, DbPlace
 */
import { Note } from '../model/NoteModel';
import { LikeRepository } from '../repository/LikeRepository';
import { DbPlace } from '../common/database/RdbManager';
import { Logger } from '../utils/Logger';

const TAG = 'LikeDAO';

export class LikeDAO {
  private static repository: LikeRepository = new LikeRepository();

  /**
   * 获取点赞的笔记
   * @returns Promise<Note[]>
   */
  static async getLikedNotes(): Promise<Note[]> {
    Logger.debug(TAG, '获取点赞笔记');
    try {
      return await LikeDAO.repository.getLikedNotes();
    } catch (e) {
      Logger.error(TAG, `获取点赞笔记失败: ${e}`);
      throw e as Error;
    }
  }

  /**
   * 获取点赞的地点
   * @returns Promise<DbPlace[]>
   */
  static async getLikedPlaces(): Promise<DbPlace[]> {
    Logger.debug(TAG, '获取点赞地点');
    try {
      return await LikeDAO.repository.getLikedPlaces();
    } catch (e) {
      Logger.error(TAG, `获取点赞地点失败: ${e}`);
      throw e as Error;
    }
  }
}
