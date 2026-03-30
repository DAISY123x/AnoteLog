import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { pushService } from '@kit.PushKit';
import { RdbManager } from '../common/database/RdbManager';
import { AuthService } from '../service/AuthService';
import { AIService } from '../service/AIService';
import { NetworkUtil } from '../utils/NetworkUtil';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      // Initialize Database
      await RdbManager.getInstance().init(this.context);
      
      // Initialize Auth Service
      await AuthService.getInstance().init(this.context);

      // Initialize AI Service
      await AIService.getInstance().init(this.context);
      
      // Initialize Network Util (starts listening)
      NetworkUtil.getInstance();

      // Initialize Push Kit
      try {
        const pushToken = await pushService.getToken();
        hilog.info(DOMAIN, 'PushKit', 'Push Token: %{public}s', pushToken);
        // TODO: Send token to server
      } catch (err) {
        hilog.error(DOMAIN, 'PushKit', 'Failed to get push token: %{public}s', JSON.stringify(err));
      }

    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to init RdbManager or set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}