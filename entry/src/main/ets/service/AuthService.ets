import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import preferences from '@ohos.data.preferences';
import { BusinessError } from '@kit.BasicServicesKit';
import common from '@ohos.app.ability.common';
import { Logger } from '../utils/Logger';

export interface UserInfo {
  username: string;
  isLogin: boolean;
  token?: string;
}

export class AuthService {
  private static instance: AuthService;
  private pref: preferences.Preferences | null = null;
  private readonly PREF_NAME = 'auth_prefs';
  
  // 模拟数据库：手机号 -> 加密后的密码
  // 默认用户: 13800000000 / 123456
  // 123456 的 SHA256: 8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92
  private mockUsers: Map<string, string> = new Map([
    ['13800000000', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92']
  ]);

  private constructor() {
  }

  public static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }

  public async init(context: common.UIAbilityContext) {
    try {
      this.pref = await preferences.getPreferences(context, this.PREF_NAME);
      // 恢复登录状态
      let isLogin = await this.pref.get('isLogin', false);
      let username = await this.pref.get('username', '') as string;
      
      if (isLogin) {
        AppStorage.setOrCreate('isLogin', true);
        AppStorage.setOrCreate('userInfo', {
          username: username,
          isLogin: true
        });
      }
    } catch (err) {
      Logger.error('AuthService', `Failed to get preferences: ${err}`);
    }
  }

  public async register(username: string, password: string): Promise<boolean> {
    if (this.mockUsers.has(username)) {
      throw new Error('用户已存在');
    }
    let hashed = await this.hashPassword(password);
    this.mockUsers.set(username, hashed);
    return true;
  }

  public async login(username: string, password: string): Promise<boolean> {
    if (!this.mockUsers.has(username)) {
      throw new Error('用户不存在');
    }
    
    let hashed = await this.hashPassword(password);
    let storedHash = this.mockUsers.get(username);
    
    if (hashed === storedHash) {
      // 登录成功，保存会话
      await this.saveSession(username);
      return true;
    } else {
      throw new Error('密码错误');
    }
  }

  public async logout() {
    if (this.pref) {
      await this.pref.put('isLogin', false);
      await this.pref.put('username', '');
      await this.pref.flush();
    }
    AppStorage.setOrCreate('isLogin', false);
    AppStorage.setOrCreate('userInfo', null);
  }

  private async saveSession(username: string) {
    if (this.pref) {
      await this.pref.put('isLogin', true);
      await this.pref.put('username', username);
      await this.pref.flush();
    }
    AppStorage.setOrCreate('isLogin', true);
    AppStorage.setOrCreate('userInfo', {
      username: username,
      isLogin: true
    });
  }

  private async hashPassword(password: string): Promise<string> {
    try {
      let md = cryptoFramework.createMd('SHA256');
      let textEncoder = new util.TextEncoder();
      let dataBlob: cryptoFramework.DataBlob = { data: textEncoder.encodeInto(password) };
      await md.update(dataBlob);
      let result = await md.digest();
      return this.uint8ArrayToHex(result.data);
    } catch (err) {
      Logger.error('AuthService', `Hash error: ${err}`);
      throw new Error('加密失败');
    }
  }

  private uint8ArrayToHex(data: Uint8Array): string {
    let hex = '';
    for (let i = 0; i < data.length; i++) {
      let val = data[i];
      if (val < 16) {
        hex += '0';
      }
      hex += val.toString(16);
    }
    return hex;
  }
}
