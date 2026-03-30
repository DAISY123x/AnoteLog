import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { CloudServiceAdapter } from '../../service/CloudServiceAdapter';
import { BusinessError } from '@kit.BasicServicesKit';

// 路由错误接口定义
interface RouterError {
  code: number;
  message: string;
}

/**
 * 路由管理工具类
 * 统一处理页面跳转、错误捕获、权限校验
 */
export class RouterManager {
  private static instance: RouterManager;

  private constructor() {
  }

  public static getInstance(): RouterManager {
    if (!RouterManager.instance) {
      RouterManager.instance = new RouterManager();
    }
    return RouterManager.instance;
  }

  /**
   * 跳转到指定页面
   * @param url 页面路径
   * @param params 页面参数
   */
  public async push(url: string, params?: Record<string, Object>): Promise<void> {
    try {
      console.info(`[RouterManager] Attempting to push to: ${url}`);

      // 1. 简单的权限/状态检查 (可扩展)
      if (!this.checkCanNavigate(url)) {
        console.warn(`[RouterManager] Navigation blocked for: ${url}`);
        return;
      }

      // 2. 记录跳转行为
      CloudServiceAdapter.getInstance().logUserAction('navigation_push', url).catch((e: Error) => {
        console.warn('[RouterManager] Log action failed', e);
      });

      // 3. 执行跳转
      await router.pushUrl({
        url: url,
        params: params
      }, router.RouterMode.Standard);

    } catch (err) {
      this.handleError(err as BusinessError, url);
    }
  }

  /**
   * 替换当前页面
   * @param url 页面路径
   * @param params 页面参数
   */
  public async replace(url: string, params?: Record<string, Object>): Promise<void> {
    try {
      console.info(`[RouterManager] Attempting to replace with: ${url}`);

      if (!this.checkCanNavigate(url)) {
        return;
      }
      CloudServiceAdapter.getInstance().logUserAction('navigation_replace', url).catch((e: Error) => {
        console.warn('[RouterManager] Log action failed', e);
      });

      await router.replaceUrl({
        url: url,
        params: params
      }, router.RouterMode.Standard);

    } catch (err) {
      this.handleError(err as BusinessError, url);
    }
  }

  /**
   * 返回上一页
   */
  public back(url?: string, params?: Record<string, Object>): void {
    try {
      console.info(`[RouterManager] Back`);
      if (url) {
        router.back({ url: url, params: params });
      } else {
        router.back();
      }
    } catch (err) {
      console.error(`[RouterManager] Back failed:`, err);
    }
  }

  public getParams(): Record<string, Object> {
    return router.getParams() as Record<string, Object>;
  }

  private checkCanNavigate(url: string): boolean {
    return true;
  }

  private handleError(err: BusinessError, url: string): void {
    console.error(`[RouterManager] Navigation error to ${url}:`, JSON.stringify(err));
    let message = '页面跳转失败';
    if (err.code === 100002) {
      message = '页面路由未找到，请检查路径配置';
    } else if (err.code === 100003) {
      message = '页面栈已满，无法打开新页面';
    }
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  }
}
