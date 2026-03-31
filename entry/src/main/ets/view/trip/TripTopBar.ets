/**
 * @file TripTopBar.ets
 * @brief 行程编辑页顶部栏 Builder
 * @description 顶部栏：返回按钮 + 行程名称输入框 + 保存按钮
 * @see NewTripPage
 */
import router from '@ohos.router';

@Component
export struct TripTopBar {
  // 行程名称（双向绑定）
  @Link tripName: string;
  // 保存按钮回调
  onSave: () => void;

  build() {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Image($r('app.media.ic_arrow_back'))
          .width(24).height(24)
      }
      .width(40).height(40)
      .backgroundColor(Color.White)
      .onClick(() => router.back())
      .shadow({ radius: 4, color: '#20000000', offsetY: 2 })

      TextInput({ text: this.tripName, placeholder: '输入行程名称' })
        .onChange((value) => this.tripName = value)
        .layoutWeight(1).height(40)
        .margin({ left: 12, right: 12 })
        .backgroundColor(Color.White)
        .borderRadius(20)
        .shadow({ radius: 4, color: '#20000000', offsetY: 2 })
        .padding({ left: 16, right: 16 })

      Button('保存')
        .height(40).borderRadius(20)
        .backgroundColor('#007DFF')
        .onClick(() => this.onSave())
        .shadow({ radius: 4, color: '#20000000', offsetY: 2 })
    }
    .width('100%')
    .padding({ top: 12, left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .position({ x: 0, y: 40 })
  }
}
