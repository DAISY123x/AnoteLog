/**
 * @file PushStubPage.ets
 * @brief PushMessageAbility 占位页面
 * @description UIAbility 需加载页面；本页无可见 UI，仅满足系统对窗口生命周期的要求
 */
@Entry
@Component
struct PushStubPage {
  build() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('#00000000')
  }
}
