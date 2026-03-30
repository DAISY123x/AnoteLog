import { RdbManager, DbPlace } from '../common/database/RdbManager';
import { Note } from '../model/NoteModel';

export class LikeDAO {
  /**
   * 获取点赞的笔记
   * @returns Promise<Note[]>
   */
  static async getLikedNotes(): Promise<Note[]> {
    console.log('[DEBUG] LikeDAO: 获取点赞笔记');
    try {
      return await RdbManager.getInstance().getLikedNotes();
    } catch (e) {
      console.error('[ERROR] LikeDAO: 获取点赞笔记失败', e);
      throw e as Error;
    }
  }

  /**
   * 获取点赞的地点
   * @returns Promise<DbPlace[]>
   */
  static async getLikedPlaces(): Promise<DbPlace[]> {
     console.log('[DEBUG] LikeDAO: 获取点赞地点');
     try {
       return await RdbManager.getInstance().getLikedPlaces();
     } catch (e) {
       console.error('[ERROR] LikeDAO: 获取点赞地点失败', e);
       throw e as Error;
     }
  }
}
