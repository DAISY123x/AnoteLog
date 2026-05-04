/**
 * @file PushMessageAbility.ets
 * @brief Push Kit 前台消息监听 Ability
 * @description 声明 action.ohos.push.listener，在 onCreate 中注册 receiveMessage，将消息交给 PushService 持久化
 */
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { pushService } from '@kit.PushKit';
import { window } from '@kit.ArkUI';
import { Logger } from '../utils/Logger';
import { PushService, PushNotificationFields, PushMessageLike } from '../service/PushService';


export default class PushMessageAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      pushService.receiveMessage('DEFAULT', this, (msg: PushMessageLike) => {
        PushService.getInstance().onPushMessageReceived(this.context, msg).catch((e: Error) => {
          Logger.error('PushMessageAbility', `handle message: ${e.message}`);
        });
      });
      Logger.info('PushMessageAbility', 'Push receiveMessage(DEFAULT) registered');
    } catch (e) {
      Logger.error('PushMessageAbility', `register listener failed: ${JSON.stringify(e)}`);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/PushStubPage', (err) => {
      if (err.code) {
        Logger.warn('PushMessageAbility', `loadContent: ${err.code}`);
      }
    });
  }
}
