/**
 * @file FeedbackDAO.ets
 * @brief 反馈数据访问层（DAO）
 * @description 封装反馈提交逻辑，内部委托 FeedbackRepository 执行数据库操作
 * @deprecated 推荐直接使用 FeedbackRepository 以减少中间层
 * @see FeedbackRepository
 */
import { FeedbackRepository } from '../repository/FeedbackRepository';
import { Logger } from '../utils/Logger';

const TAG = 'FeedbackDAO';

export class FeedbackDAO {
  private static repository: FeedbackRepository = new FeedbackRepository();

  /**
   * 提交反馈
   * @param content 反馈内容
   * @param contact 联系方式
   * @returns Promise<number>
   */
  static async submitFeedback(content: string, contact: string): Promise<number> {
    Logger.debug(TAG, '提交反馈');
    try {
      return await FeedbackDAO.repository.submit(content, contact);
    } catch (e) {
      Logger.error(TAG, `提交反馈失败: ${e}`);
      throw e as Error;
    }
  }
}
