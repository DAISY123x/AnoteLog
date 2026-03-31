/**
 * @file FeedbackRepository.ets
 * @brief 反馈数据访问层
 * @description 负责 feedback 表的完整 CRUD
 * @see RdbManager
 */
import { RdbManager } from '../common/database/RdbManager';
import { Logger } from '../utils/Logger';

const TAG = 'FeedbackRepository';

export interface Feedback {
  id?: number;
  content: string;
  contact?: string;
  createTime?: number;
}

export class FeedbackRepository {
  /**
   * 提交用户反馈
   * @param content 反馈内容
   * @param contact 联系方式（可选）
   * @returns 新记录 ID
   */
  async submit(content: string, contact?: string): Promise<number> {
    Logger.info(TAG, 'submit: New feedback submitted');
    return RdbManager.getInstance().submitFeedback(content, contact || '');
  }
}
