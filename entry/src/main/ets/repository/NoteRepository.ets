/**
 * @file NoteRepository.ets
 * @brief 笔记数据访问层
 * @description 负责 Note 实体的数据库 CRUD 操作及高级查询
 * @see RdbManager, Note
 */
import { Note } from '../model/NoteModel';
import { RdbManager } from '../common/database/RdbManager';
import { Logger } from '../utils/Logger';

const TAG = 'NoteRepository';

interface GeneratedTypeLiteralInterface_1 {
  id?: number;
  limit?: number;
  offset?: number;
  isShared?: boolean;
  category?: string;
}

export class NoteRepository {
  /**
   * 根据 ID 获取笔记
   * @param id 笔记 ID
   * @returns Note 或 null
   */
  async getById(id: number): Promise<Note | null> {
    const notes = await this.query({ id, limit: 1 });
    return notes.length > 0 ? notes[0] : null;
  }

  /**
   * 获取所有笔记
   * @returns Note[]
   */
  async getAll(): Promise<Note[]> {
    return this.query({});
  }

  /**
   * 新增笔记
   * @param note 笔记实体
   * @returns 新记录 ID
   */
  async insert(note: Note): Promise<number> {
    Logger.info(TAG, `insert: Creating note "${note.title}"`);
    return RdbManager.getInstance().insertNote(note);
  }

  /**
   * 更新笔记
   * @param note 笔记实体
   * @returns 受影响行数
   */
  async update(note: Note): Promise<number> {
    Logger.info(TAG, `update: Updating note ${note.id}`);
    return RdbManager.getInstance().updateNote(note);
  }

  /**
   * 删除笔记
   * @param id 笔记 ID
   * @returns 受影响行数
   */
  async delete(id: number): Promise<number> {
    Logger.info(TAG, `delete: Deleting note ${id}`);
    return RdbManager.getInstance().deleteNote(id);
  }

  /**
   * 分页 + 筛选查询笔记
   * @param params 查询参数
   * @param params.id 精确 ID
   * @param params.limit 每页数量
   * @param params.offset 偏移量
   * @param params.isShared 是否分享
   * @param params.category 分类
   * @returns Note[]
   */
  async query(params: GeneratedTypeLiteralInterface_1): Promise<Note[]> {
    return RdbManager.getInstance().getNotes(params.limit, params.offset, params.isShared, params.category);
  }

  /**
   * 便捷方法：分页查询笔记（positional 参数）
   * @param limit 每页数量
   * @param offset 偏移量
   * @param isShared 是否分享（undefined=全部）
   * @param category 分类（undefined=全部）
   * @returns Note[]
   */
  async getNotes(limit?: number, offset?: number, isShared?: boolean, category?: string): Promise<Note[]> {
    return RdbManager.getInstance().getNotes(limit, offset, isShared, category);
  }

  /**
   * 获取已分享的笔记（旅游建议）
   * @param category 分类（可选）
   * @returns Note[]
   */
  async getSharedNotes(category?: string): Promise<Note[]> {
    return RdbManager.getInstance().getNotes(undefined, undefined, true, category);
  }
}
