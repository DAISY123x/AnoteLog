/**
 * @file LoginPage.ets
 * @brief 登录页
 * @description 支持华为ID快捷登录和手机号密码登录
 * @see AuthService
 */
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { authentication } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { Logger } from '../utils/Logger';

import { AuthService } from '../service/AuthService';

interface HuaweiIDCredential {
  openID: string;
  nickName?: string;
  avatarUri?: string;
}

@Entry
@Component
struct LoginPage {
  @State phoneNumber: string = '';
  @State password: string = '';
  @State isPrivacyChecked: boolean = false;

  private loginWithHuawei() {
    // ... (Keep existing implementation if needed, but simplified for brevity in this thought, I will not change this part in the tool call unless I replace the whole file or specific block)
    try {
      let controller = new authentication.AuthenticationController();
      let request = new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest();
      request.forceLogin = true; // 强制拉起登录界面
      controller.executeRequest(request).then((response: authentication.AuthenticationResponse) => {
        let credential = response as HuaweiIDCredential;
        // 登录成功
        Logger.info('LoginPage', 'Huawei ID Login Success');
        promptAction.showToast({ message: `欢迎回来，${credential.nickName || '用户'}` });

        // 保存用户信息
        AppStorage.setOrCreate('isLogin', true);
        AppStorage.setOrCreate('userInfo', {
          username: credential.nickName || 'Huawei User',
          isLogin: true
        });

        router.back();
      }).catch((err: BusinessError) => {
        promptAction.showToast({ message: '登录失败，请重试' });
      });
    } catch (err) {
      Logger.error('LoginPage', `Huawei ID Login Exception: ${JSON.stringify(err)}`);
    }
  }

  async handleLogin() {
    if (!this.isPrivacyChecked) {
      promptAction.showToast({ message: '请先勾选隐私协议' });
      return;
    }
    if (this.phoneNumber.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }
    if (this.password.length < 6) {
      promptAction.showToast({ message: '密码长度至少6位' });
      return;
    }

    try {
      await AuthService.getInstance().login(this.phoneNumber, this.password);
      promptAction.showToast({ message: '登录成功' });
      router.back();
    } catch (err) {
      promptAction.showToast({ message: (err as Error).message });
    }
  }

  async handleRegister() {
    if (!this.isPrivacyChecked) {
      promptAction.showToast({ message: '请先勾选隐私协议' });
      return;
    }
    if (this.phoneNumber.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }
    if (this.password.length < 6) {
      promptAction.showToast({ message: '密码长度至少6位' });
      return;
    }

    try {
      await AuthService.getInstance().register(this.phoneNumber, this.password);
      promptAction.showToast({ message: '注册成功，请登录' });
      // Auto login or just let user login
      await AuthService.getInstance().login(this.phoneNumber, this.password);
      promptAction.showToast({ message: '登录成功' });
      router.back();
    } catch (err) {
      promptAction.showToast({ message: (err as Error).message });
    }
  }

  build() {
    Column() {
      // ... (Header parts unchanged)
      Row() {
        Image($r('app.media.ic_arrow_back'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.icon_primary'))
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      .padding({ left: 16, top: 16 })
      .justifyContent(FlexAlign.Start)

      // 2. Logo / 标题区域
      Column() {
        Image($r('app.media.startIcon')) // 使用应用图标
          .width(80)
          .height(80)
          .borderRadius(16)
          .margin({ bottom: 24 })

        Text('欢迎来到旅游攻略助手')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .margin({ bottom: 8 })

        Text('探索世界，记录美好旅程')
          .fontSize(16)
          .fontColor('#999')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 40, bottom: 60 })

      // 3. 华为账号一键登录
      Button() {
        Row() {
          Image($r('app.media.ic_home_normal')) // 暂替华为Logo
            .width(24)
            .height(24)
            .fillColor(Color.White)
            .margin({ right: 12 })

          Text('华为账号一键登录')
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('85%')
      .height(50)
      .backgroundColor('#C7000B') // 华为红
      .borderRadius(25)
      .onClick(() => {
        if (!this.isPrivacyChecked) {
          promptAction.showToast({ message: '请先勾选隐私协议' });
          return;
        }
        this.loginWithHuawei();
      })
      .shadow({ radius: 10, color: 'rgba(199, 0, 11, 0.3)', offsetY: 5 })

      // 4. 其他方式登录分割线
      Row() {
        Divider().strokeWidth(1).color('#E0E0E0').layoutWeight(1)
        Text('或')
          .fontSize(14)
          .fontColor('#999')
          .margin({ left: 12, right: 12 })
        Divider().strokeWidth(1).color('#E0E0E0').layoutWeight(1)
      }
      .width('85%')
      .margin({ top: 30, bottom: 30 })

      // 5. 手机号/密码登录表单
      Column({ space: 16 }) {
        TextInput({ placeholder: '请输入手机号' })
          .width('85%')
          .height(50)
          .backgroundColor('#F5F7FA')
          .borderRadius(12)
          .type(InputType.PhoneNumber)
          .onChange((value) => {
            this.phoneNumber = value;
          })

        TextInput({ placeholder: '请输入密码' })
          .width('85%')
          .height(50)
          .backgroundColor('#F5F7FA')
          .borderRadius(12)
          .type(InputType.Password)
          .onChange((value) => {
            this.password = value;
          })

        Row({ space: 16 }) {
          Button('注册')
            .layoutWeight(1)
            .height(50)
            .backgroundColor('#34C759')
            .borderRadius(25)
            .enabled(!!(this.phoneNumber && this.password))
            .onClick(() => {
              this.handleRegister();
            })

          Button('登录')
            .layoutWeight(1)
            .height(50)
            .backgroundColor(this.phoneNumber && this.password ? '#007DFF' : '#B0C4DE')
            .borderRadius(25)
            .enabled(!!(this.phoneNumber && this.password))
            .onClick(() => {
              this.handleLogin();
            })
        }
        .width('85%')
      }

      Blank()

      // 6. 底部隐私协议
      Row() {
        Checkbox({ name: 'privacy', group: 'privacy' })
          .select(this.isPrivacyChecked)
          .selectedColor('#007DFF')
          .onChange((value: boolean) => {
            this.isPrivacyChecked = value;
          })

        Text() {
          Span('我已阅读并同意 ')
            .fontColor('#999')
          Span('《用户协议》')
            .fontColor('#007DFF')
          Span(' 和 ')
            .fontColor('#999')
          Span('《隐私政策》')
            .fontColor('#007DFF')
        }
        .fontSize(12)
      }
      .margin({ bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
