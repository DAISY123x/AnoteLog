/**
 * @file IRepository.ets
 * @brief Repository 基接口
 * @description 定义所有 Repository 必须实现的标准 CRUD 方法
 * @see NoteRepository, TripRepository, LikeRepository, PlaceRepository, FeedbackRepository
 */
export interface IRepository<T> {
  /**
   * 根据 ID 获取单条记录
   * @param id 记录 ID
   * @returns 记录实体或 null
   */
  getById(id: number): Promise<T | null>;

  /**
   * 获取所有记录
   * @returns 记录列表
   */
  getAll(): Promise<T[]>;

  /**
   * 插入新记录
   * @param entity 记录实体
   * @returns 新记录 ID
   */
  insert(entity: T): Promise<number>;

  /**
   * 更新记录
   * @param entity 记录实体
   * @returns 受影响行数
   */
  update(entity: T): Promise<number>;

  /**
   * 删除记录
   * @param id 记录 ID
   * @returns 受影响行数
   */
  delete(id: number): Promise<number>;
}
