/**
 * @file PushService.ets
 * @brief 推送消息落库与应用内通知列表
 * @description 将 Push Kit 回调中的消息写入 preferences，维护未读数并与 AppStorage 同步
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';

const PREF_STORE: string = 'anote_push_notifications';
const KEY_ITEMS: string = 'items_json';

/** 单条应用内通知（持久化） */
export interface PushNotificationRecord {
  id: string;
  title: string;
  content: string;
  time: number;
  isRead: boolean;
}

/** 推送消息通知字段 */
export interface PushNotificationFields {
  title?: string;
  body?: string;
}

/** 解析后的推送消息结果 */
interface ParsedPushMessage {
  title: string;
  content: string;
}

/** SDK 回调中可能出现的字段（不同消息形态字段略有差异） */
export interface PushMessageLike {
  data?: string;
  notification?: PushNotificationFields;
}

export class PushService {
  private static instance: PushService | null = null;
  private pref: preferences.Preferences | null = null;

  private constructor() {
  }

  static getInstance(): PushService {
    if (PushService.instance === null) {
      PushService.instance = new PushService();
    }
    return PushService.instance;
  }

  /**
   * 在主进程 EntryAbility 中初始化 preferences，并刷新未读数到 AppStorage
   */
  async init(context: common.Context): Promise<void> {
    try {
      this.pref = await preferences.getPreferences(context, PREF_STORE);
      await this.flushUnreadToAppStorage();
      Logger.info('PushService', 'initialized');
    } catch (e) {
      Logger.error('PushService', `init failed: ${JSON.stringify(e)}`);
    }
  }

  /**
   * 供 PushMessageAbility 在无事先 init 时使用（独立 Ability 进程）
   */
  private async ensurePref(context: common.Context): Promise<preferences.Preferences> {
    if (this.pref === null) {
      this.pref = await preferences.getPreferences(context, PREF_STORE);
    }
    return this.pref;
  }

  /**
   * Push Kit 前台消息回调入口：解析标题/正文并追加列表
   */
  async onPushMessageReceived(context: common.Context, message: PushMessageLike): Promise<void> {
    const pref = await this.ensurePref(context);
    const parsed = PushService.parsePushMessage(message);
    Logger.info('PushService', `incoming push title=${parsed.title}`);
    const list = await PushService.readList(pref);
    const record: PushNotificationRecord = {
      id: `${Date.now()}`,
      title: parsed.title,
      content: parsed.content,
      time: Date.now(),
      isRead: false
    };
    list.unshift(record);
    await PushService.writeList(pref, list);
    await pref.flush();
    await this.flushUnreadToAppStorageWithPref(pref);
  }

  async getNotifications(context: common.Context): Promise<PushNotificationRecord[]> {
    const pref = await this.ensurePref(context);
    return PushService.readList(pref);
  }

  async markRead(context: common.Context, id: string): Promise<void> {
    const pref = await this.ensurePref(context);
    const list = await PushService.readList(pref);
    const next = list.map((item: PushNotificationRecord): PushNotificationRecord => {
      if (item.id === id) {
        const copy: PushNotificationRecord = {
          id: item.id,
          title: item.title,
          content: item.content,
          time: item.time,
          isRead: true
        };
        return copy;
      }
      return item;
    });
    await PushService.writeList(pref, next);
    await pref.flush();
    await this.flushUnreadToAppStorageWithPref(pref);
  }

  async markAllRead(context: common.Context): Promise<void> {
    const pref = await this.ensurePref(context);
    const list = await PushService.readList(pref);
    const next = list.map((item: PushNotificationRecord): PushNotificationRecord => {
      const copy: PushNotificationRecord = {
        id: item.id,
        title: item.title,
        content: item.content,
        time: item.time,
        isRead: true
      };
      return copy;
    });
    await PushService.writeList(pref, next);
    await pref.flush();
    await this.flushUnreadToAppStorageWithPref(pref);
  }

  async clearAll(context: common.Context): Promise<void> {
    const pref = await this.ensurePref(context);
    await PushService.writeList(pref, []);
    await pref.flush();
    await this.flushUnreadToAppStorageWithPref(pref);
  }

  private async flushUnreadToAppStorage(): Promise<void> {
    if (this.pref === null) {
      return;
    }
    await this.flushUnreadToAppStorageWithPref(this.pref);
  }

  private async flushUnreadToAppStorageWithPref(pref: preferences.Preferences): Promise<void> {
    const list = await PushService.readList(pref);
    let unread = 0;
    for (let i = 0; i < list.length; i++) {
      if (!list[i].isRead) {
        unread++;
      }
    }
    AppStorage.setOrCreate('notificationUnreadCount', unread);
  }

  private static parsePushMessage(message: PushMessageLike): ParsedPushMessage {
    let title = '推送消息';
    let content = '';
    if (message.notification !== undefined && message.notification !== null) {
      const n = message.notification;
      if (n.title !== undefined && n.title.length > 0) {
        title = n.title;
      }
      if (n.body !== undefined && n.body.length > 0) {
        content = n.body;
      }
    }
    if (message.data !== undefined && message.data !== null && message.data.length > 0) {
      if (content.length === 0) {
        content = message.data;
      }
      try {
        const rawObj = JSON.parse(message.data) as object;
        if (typeof rawObj === 'object' && rawObj !== null) {
          const rec = rawObj as Record<string, Object>;
          const nested = rec['notification'];
          if (typeof nested === 'object' && nested !== null) {
            const n = nested as Record<string, Object>;
            const nt = n['title'];
            const nb = n['body'];
            if (typeof nt === 'string' && nt.length > 0) {
              title = nt;
            }
            if (typeof nb === 'string' && nb.length > 0) {
              content = nb;
            }
          }
          const tVal = rec['title'];
          if (typeof tVal === 'string' && tVal.length > 0) {
            title = tVal;
          }
          const cVal = rec['content'] !== undefined ? rec['content'] : rec['body'];
          if (typeof cVal === 'string' && cVal.length > 0) {
            content = cVal;
          }
        }
      } catch (_e) {
        // 非 JSON 时沿用 data 原文
      }
    }
    if (content.length === 0) {
      content = '(无正文)';
    }
    return { title: title, content: content } as ParsedPushMessage;
  }

  private static async readList(pref: preferences.Preferences): Promise<PushNotificationRecord[]> {
    const raw = await pref.get(KEY_ITEMS, '[]') as string;
    try {
      const arr = JSON.parse(raw) as PushNotificationRecord[];
      if (Array.isArray(arr)) {
        return arr;
      }
    } catch (_e) {
      Logger.warn('PushService', 'corrupt notification list, reset');
    }
    return [];
  }

  private static async writeList(pref: preferences.Preferences, list: PushNotificationRecord[]): Promise<void> {
    await pref.put(KEY_ITEMS, JSON.stringify(list));
  }
}
