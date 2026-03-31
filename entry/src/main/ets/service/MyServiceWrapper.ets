import { TripDAO } from '../dao/TripDAO';
import { LikeDAO } from '../dao/LikeDAO';
import { FeedbackDAO } from '../dao/FeedbackDAO';
import { DeviceService, Device } from './DeviceService';
import { Trip } from '../model/TripModel';
import { Note } from '../model/NoteModel';
import { DbPlace } from '../common/database/RdbManager';
import { Logger } from '../utils/Logger';

export class MyServiceWrapper {
  private static instance: MyServiceWrapper;

  private constructor() {
  }

  public static getInstance(): MyServiceWrapper {
    if (!MyServiceWrapper.instance) {
      MyServiceWrapper.instance = new MyServiceWrapper();
    }
    return MyServiceWrapper.instance;
  }

  /**
   * 统一错误处理流程
   * @param opName 操作名称
   * @param operation 异步操作函数
   */
  private async wrapOperation<T>(opName: string, operation: () => Promise<T>): Promise<T> {
    Logger.debug('MyServiceWrapper', `开始操作: ${opName}`);
    const startTime = Date.now();
    try {
      const result = await operation();
      Logger.debug('MyServiceWrapper', `操作成功: ${opName}, 耗时: ${Date.now() - startTime}ms`);
      return result;
    } catch (e) {
      Logger.error('MyServiceWrapper', `操作失败 ${opName}: ${e}`);
      throw new Error(`操作失败: ${opName}`);
    }
  }

  // ==================== 1. "待完成的行程"模块 ====================

  /**
   * 获取待完成行程
   * @returns Promise<Trip[]>
   */
  async getPendingTrips(): Promise<Trip[]> {
    return this.wrapOperation('获取待完成行程', () => TripDAO.getPendingTrips());
  }

  // ==================== 2. "我的点赞"模块 ====================

  /**
   * 获取点赞笔记
   * @returns Promise<Note[]>
   */
  async getLikedNotes(): Promise<Note[]> {
    return this.wrapOperation('获取点赞笔记', () => LikeDAO.getLikedNotes());
  }

  /**
   * 获取点赞地点
   * @returns Promise<DbPlace[]>
   */
  async getLikedPlaces(): Promise<DbPlace[]> {
    return this.wrapOperation('获取点赞地点', () => LikeDAO.getLikedPlaces());
  }

  // ==================== 3. "设备同步"模块 ====================

  /**
   * 同步设备
   * @returns Promise<boolean>
   */
  async syncDevices(): Promise<boolean> {
    return this.wrapOperation('同步设备', () => DeviceService.syncAllDevices());
  }

  /**
   * 获取绑定设备列表
   * @returns Promise<Device[]>
   */
  async getBoundDevices(): Promise<Device[]> {
    return this.wrapOperation('获取绑定设备', () => DeviceService.getBoundDevices());
  }

  // ==================== 4. "反馈建议"模块 ====================

  /**
   * 提交反馈
   * @param content 反馈内容
   * @param contact 联系方式
   * @returns Promise<number>
   */
  async submitFeedback(content: string, contact: string): Promise<number> {
    return this.wrapOperation('提交反馈', () => FeedbackDAO.submitFeedback(content, contact));
  }
}
