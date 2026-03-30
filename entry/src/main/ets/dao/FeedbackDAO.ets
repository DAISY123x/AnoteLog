import { RdbManager } from '../common/database/RdbManager';

export class FeedbackDAO {
  /**
   * 提交反馈
   * @param content 反馈内容
   * @param contact 联系方式
   * @returns Promise<number>
   */
  static async submitFeedback(content: string, contact: string): Promise<number> {
    console.log('[DEBUG] FeedbackDAO: 提交反馈');
    try {
      return await RdbManager.getInstance().submitFeedback(content, contact);
    } catch (e) {
      console.error('[ERROR] FeedbackDAO: 提交反馈失败', e);
      throw e as Error;
    }
  }
}
