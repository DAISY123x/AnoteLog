import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { pushService } from '@kit.PushKit';
import { RdbManager } from '../common/database/RdbManager';
import { AuthService } from '../service/AuthService';
import { AIService } from '../service/AIService';
import { ConfigService } from '../service/ConfigService';
import { NetworkUtil } from '../utils/NetworkUtil';
import { MockService } from '../common/service/MockService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);

      // Initialize Config Service (MUST be before AIService to load API key)
      await ConfigService.getInstance().init(this.context);

      // Initialize Mock Service (load mock data from rawfile)
      await MockService.getInstance().init(this.context.resourceManager);

      // Initialize Database
      await RdbManager.getInstance().init(this.context);

      // Initialize Auth Service
      await AuthService.getInstance().init(this.context);

      // Initialize AI Service (reads config from ConfigService)
      await AIService.getInstance().init(this.context);

      // Initialize Network Util (starts listening)
      NetworkUtil.getInstance();

      // Initialize Push Kit
      try {
        const pushToken = await pushService.getToken();
        hilog.info(DOMAIN, 'PushKit', 'Push Token: %{public}s', pushToken);
      } catch (err) {
        hilog.error(DOMAIN, 'PushKit', 'Failed to get push token: %{public}s', JSON.stringify(err));
      }

    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to init services. Cause: %{public}s', JSON.stringify(err));
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