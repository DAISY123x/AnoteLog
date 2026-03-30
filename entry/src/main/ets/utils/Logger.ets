/**
 * @file Logger.ets
 * @brief 应用统一日志工具
 * @description 封装 HarmonyOS hilog 模块，提供带时间戳的统一日志输出
 */
import hilog from '@ohos.hilog';

export class Logger {
  private static readonly DOMAIN: number = 0x0000;
  private static readonly PREFIX: string = 'Anote';
  static info(tag: string, message: string, ...args: Object[]): void {
    hilog.info(Logger.DOMAIN, tag, `[${Logger.PREFIX}] ${message}`, args);
  }
  static warn(tag: string, message: string, ...args: Object[]): void {
    hilog.warn(Logger.DOMAIN, tag, `[${Logger.PREFIX}] ${message}`, args);
  }
  static error(tag: string, message: string, ...args: Object[]): void {
    hilog.error(Logger.DOMAIN, tag, `[${Logger.PREFIX}] ${message}`, args);
  }
  static debug(tag: string, message: string, ...args: Object[]): void {
    hilog.debug(Logger.DOMAIN, tag, `[${Logger.PREFIX}] ${message}`, args);
  }
}
