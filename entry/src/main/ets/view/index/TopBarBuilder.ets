/**
 * @file TopBarBuilder.ets
 * @brief 首页顶部搜索栏 Builder
 * @description 首页顶部搜索栏组件，支持登录状态显示和跳转
 */
import router from '@ohos.router';

@Component
export struct TopBarBuilder {
  @StorageLink('isLogin') isLogin: boolean = false;
  @BuilderParam onLoginClick?: () => void;

  build() {
    Row() {
      Row() {
        Image($r('app.media.ic_search'))
          .width(18)
          .height(18)
          .fillColor($r('app.color.search_icon'))
          .margin({ right: 8 })
        Text('搜索目的地/景点')
          .fontSize(14)
          .fontColor($r('app.color.text_tertiary'))
      }
      .height(40)
      .layoutWeight(1)
      .backgroundColor($r('app.color.search_bg'))
      .border({ width: 1, color: $r('app.color.search_border') })
      .borderRadius(20)
      .padding({ left: 16 })
      .shadow({ radius: 10, color: 'rgba(0, 125, 255, 0.10)', offsetY: 2 })
      .onClick(() => {
        router.pushUrl({ url: 'pages/SearchPage' });
      })

      if (!this.isLogin) {
        Button('登录 / 注册')
          .height(36)
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#007DFF')
          .borderRadius(18)
          .margin({ left: 16 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/LoginPage' });
          })
          .shadow({ radius: 8, color: 'rgba(0, 125, 255, 0.3)', offsetY: 2 })
      } else {
        Image('https://img.icons8.com/color/48/user-male-circle--v1.png')
          .width(40)
          .height(40)
          .borderRadius(20)
          .margin({ left: 16 })
          .border({ width: 2, color: Color.White })
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)', offsetY: 2 })
          .onClick(() => {
            if (this.onLoginClick) {
              this.onLoginClick();
            }
          })
      }
    }
    .width('100%')
    .padding({
      left: 20,
      right: 20,
      top: 12,
      bottom: 12
    })
  }
}
