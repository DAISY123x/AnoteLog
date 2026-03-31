/**
 * @file FeedbackPage.ets
 * @brief 反馈页
 * @description 用户提交意见反馈
 * @see FeedbackRepository
 */
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { RouterManager } from '../common/utils/RouterManager';
import { Logger } from '../utils/Logger';
import { FeedbackRepository } from '../repository/FeedbackRepository';

@Entry
@Component
struct FeedbackPage {
  @State content: string = '';
  @State contact: string = '';
  @State isSubmitting: boolean = false;
  private feedbackRepository: FeedbackRepository = new FeedbackRepository();

  async submit() {
    if (!this.content.trim()) {
      promptAction.showToast({ message: '请输入反馈内容' });
      return;
    }

    this.isSubmitting = true;
    try {
      await this.feedbackRepository.submit(this.content, this.contact);
      promptAction.showToast({ message: '感谢您的反馈！' });
      setTimeout(() => {
        router.back();
      }, 1000);
    } catch (e) {
      Logger.error('FeedbackPage', 'Submit feedback failed', e);
      promptAction.showToast({ message: '提交失败，请稍后重试' });
      this.isSubmitting = false;
    }
  }

  build() {
    Column() {
      // Top Bar
      Row() {
        Image($r('app.media.ic_arrow_back'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.icon_primary'))
          .onClick(() => {
            RouterManager.getInstance().back();
          })
        Text('反馈建议')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)

      Column() {
        // Content Area
        Text('问题与建议')
          .fontSize(14)
          .fontColor('#666')
          .margin({ bottom: 8 })

        TextArea({ placeholder: '请输入您的反馈内容...', text: this.content })
          .height(150)
          .width('100%')
          .backgroundColor(Color.White)
          .padding(12)
          .borderRadius(8)
          .onChange((value) => {
            this.content = value;
          })

        Text('联系方式 (选填)')
          .fontSize(14)
          .fontColor('#666')
          .margin({ top: 20, bottom: 8 })

        TextInput({ placeholder: '手机号/邮箱', text: this.contact })
          .width('100%')
          .height(44)
          .backgroundColor(Color.White)
          .padding({ left: 12, right: 12 })
          .borderRadius(8)
          .onChange((value) => {
            this.contact = value;
          })

        Button(this.isSubmitting ? '提交中...' : '提交反馈')
          .width('100%')
          .height(44)
          .backgroundColor($r('app.color.accent'))
          .margin({ top: 40 })
          .enabled(!this.isSubmitting)
          .onClick(() => {
            this.submit();
          })

      }
      .padding(16)
      .width('100%')
      .layoutWeight(1)

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
