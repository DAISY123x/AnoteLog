/**
 * @file LikeRepository.ets
 * @brief 点赞数据访问层
 * @description 负责 user_like 表的完整 CRUD 及关联查询
 * @see RdbManager, Note, DbPlace
 */
import { Note } from '../model/NoteModel';
import { RdbManager, DbPlace } from '../common/database/RdbManager';
import { Logger } from '../utils/Logger';

const TAG = 'LikeRepository';

export class LikeRepository {
  /**
   * 点赞/取消点赞（Toggle）
   * @param targetId 被点赞对象 ID
   * @param type 点赞类型（'note' | 'place'）
   * @returns true=点赞成功, false=取消点赞
   */
  async toggleLike(targetId: number, type: 'note' | 'place'): Promise<boolean> {
    Logger.info(TAG, `toggleLike: target=${targetId}, type=${type}`);
    return RdbManager.getInstance().toggleLike(targetId, type);
  }

  /**
   * 检查是否已点赞
   * @param targetId 被点赞对象 ID
   * @param type 点赞类型
   * @returns boolean
   */
  async isLiked(targetId: number, type: 'note' | 'place'): Promise<boolean> {
    return RdbManager.getInstance().isLiked(targetId, type);
  }

  /**
   * 获取点赞的笔记列表
   * @returns Note[]
   */
  async getLikedNotes(): Promise<Note[]> {
    Logger.info(TAG, 'getLikedNotes');
    return RdbManager.getInstance().getLikedNotes();
  }

  /**
   * 获取点赞的地点列表
   * @returns DbPlace[]
   */
  async getLikedPlaces(): Promise<DbPlace[]> {
    Logger.info(TAG, 'getLikedPlaces');
    return RdbManager.getInstance().getLikedPlaces();
  }
}
