/**
 * @file DayTabBar.ets
 * @brief 行程天数 Tab 栏 Builder
 * @description 横向 Tab：切换行程天数，支持添加新的一天
 * @see TripGroup
 */
import router from '@ohos.router';

@Component
export struct DayTabBar {
  @Prop groups: TripGroup[] = [];
  @Link activeGroupIndex: number;
  onAddDay: () => void;

  build() {
    List({ space: 10 }) {
      ForEach(this.groups, (group: TripGroup, index: number) => {
        ListItem() {
          Text(group.name)
            .fontColor(this.activeGroupIndex === index ? Color.White : '#333333')
            .fontSize(14)
            .backgroundColor(this.activeGroupIndex === index ? '#007DFF' : '#F5F5F5')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(16)
            .onClick(() => { this.activeGroupIndex = index; })
        }
      })

      ListItem() {
        Row() {
          Text('+').fontSize(16).fontColor('#007DFF')
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#F0F8FF')
        .borderRadius(16)
        .onClick(() => { this.onAddDay(); })
      }
    }
    .listDirection(Axis.Horizontal)
    .height(50)
    .width('100%')
    .scrollBar(BarState.Off)
    .padding({ left: 16, right: 16 })
  }
}
