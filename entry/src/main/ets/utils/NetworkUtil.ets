import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from './Logger';

export class NetworkUtil {
  private static instance: NetworkUtil;
  private netConn: connection.NetConnection | null = null;
  private hasNet: boolean = true;

  private constructor() {
    this.init();
  }

  public static getInstance(): NetworkUtil {
    if (!NetworkUtil.instance) {
      NetworkUtil.instance = new NetworkUtil();
    }
    return NetworkUtil.instance;
  }

  private init() {
    try {
      this.netConn = connection.createNetConnection();
      
      // 注册监听
      this.netConn.on('netAvailable', (data: connection.NetHandle) => {
        Logger.info('NetworkUtil', 'Network available');
        console.info('NetworkUtil: Network available');
        this.hasNet = true;
        AppStorage.setOrCreate('isNetworkAvailable', true);
      });

      this.netConn.on('netUnavailable', () => {
        Logger.info('NetworkUtil', 'Network unavailable');
        console.info('NetworkUtil: Network unavailable');
        this.hasNet = false;
        AppStorage.setOrCreate('isNetworkAvailable', false);
      });

      this.netConn.on('netLost', (data: connection.NetHandle) => {
        Logger.info('NetworkUtil', 'Network lost');
        console.info('NetworkUtil: Network lost');
        this.hasNet = false;
        AppStorage.setOrCreate('isNetworkAvailable', false);
      });

      // 初始检查
      connection.hasDefaultNet().then((has: boolean) => {
        Logger.info('NetworkUtil', `Initial check result: ${has}`);
        console.info('NetworkUtil: Initial check result:', has);
        this.hasNet = has;
        AppStorage.setOrCreate('isNetworkAvailable', has);
      }).catch((err: BusinessError) => {
        Logger.error('NetworkUtil', `Check default net failed: ${err}`);
        console.error('NetworkUtil: Check default net failed:', err);
        this.hasNet = false; // Assume false on error
        AppStorage.setOrCreate('isNetworkAvailable', false);
      });
    } catch (e) {
      Logger.error('NetworkUtil', `Init failed: ${e}`);
      console.error('NetworkUtil: Init failed', e);
    }
  }

  public isNetworkAvailable(): boolean {
    return this.hasNet;
  }
}
