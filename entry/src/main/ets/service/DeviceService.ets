export interface Device {
  id: string;
  name: string;
  type: string; // 'phone', 'tablet', 'watch'
  lastSyncTime: number;
  isCurrent?: boolean;
}

export class DeviceService {
  /**
   * 获取绑定的设备列表
   * @returns Promise<Device[]>
   */
  static async getBoundDevices(): Promise<Device[]> {
    console.log('[DEBUG] DeviceService: 获取绑定设备');
    // 模拟网络请求延迟
    await new Promise<void>((resolve: (value: void | PromiseLike<void>) => void) => {
      setTimeout(resolve, 500);
    });
    
    return [
      { id: '1', name: 'Mate 60 Pro', type: 'phone', lastSyncTime: Date.now(), isCurrent: true },
      { id: '2', name: 'MatePad Pro', type: 'tablet', lastSyncTime: Date.now() - 1000 * 60 * 60 * 2, isCurrent: false },
      { id: '3', name: 'HUAWEI WATCH GT 4', type: 'watch', lastSyncTime: Date.now() - 1000 * 60 * 60 * 24, isCurrent: false }
    ];
  }

  /**
   * 同步所有设备
   * @returns Promise<boolean>
   */
  static async syncAllDevices(): Promise<boolean> {
     console.log('[DEBUG] DeviceService: 开始同步设备');
     await new Promise<void>((resolve: (value: void | PromiseLike<void>) => void) => {
       setTimeout(resolve, 1500);
     });
     console.log('[DEBUG] DeviceService: 设备同步完成');
     return true;
  }
}
