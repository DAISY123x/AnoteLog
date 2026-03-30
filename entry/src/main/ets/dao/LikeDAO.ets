import { RdbManager, DbPlace } from '../common/database/RdbManager';
import { Note } from '../model/NoteModel';
import { Logger } from '../utils/Logger';

export class LikeDAO {
  /**
   * 获取点赞的笔记
   * @returns Promise<Note[]>
   */
  static async getLikedNotes(): Promise<Note[]> {
    Logger.debug('LikeDAO', '获取点赞笔记');
    console.log('[DEBUG] LikeDAO: 获取点赞笔记');
    try {
      return await RdbManager.getInstance().getLikedNotes();
    } catch (e) {
      Logger.error('LikeDAO', `获取点赞笔记失败: ${e}`);
      console.error('[ERROR] LikeDAO: 获取点赞笔记失败', e);
      throw e as Error;
    }
  }

  /**
   * 获取点赞的地点
   * @returns Promise<DbPlace[]>
   */
  static async getLikedPlaces(): Promise<DbPlace[]> {
     Logger.debug('LikeDAO', '获取点赞地点');
     console.log('[DEBUG] LikeDAO: 获取点赞地点');
     try {
       return await RdbManager.getInstance().getLikedPlaces();
     } catch (e) {
       Logger.error('LikeDAO', `获取点赞地点失败: ${e}`);
       console.error('[ERROR] LikeDAO: 获取点赞地点失败', e);
       throw e as Error;
     }
  }
}
