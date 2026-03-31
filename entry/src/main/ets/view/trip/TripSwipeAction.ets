/**
 * @file TripSwipeAction.ets
 * @brief 行程滑动操作按钮组件
 * @description 滑出时显示删除（已完成行程）或完成（未完成行程）按钮
 * @see TripViewModel
 */
import { promptAction } from '@kit.ArkUI';

@Component
export struct TripSwipeAction {
  // 行程数据
  @Prop trip: TripViewModel;
  // 删除回调
  onDelete?: (id: number | null) => void;
  // 标记完成回调
  onComplete?: (id: number | null) => void;
  // 确认删除弹窗
  confirmDelete(): void {
    promptAction.showDialog({
      title: '删除行程',
      message: '确定要删除这个行程吗？删除后无法恢复。',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '删除', color: '#FF4D4F' }
      ]
    }).then((res) => {
      if (res.index === 1) {
        if (this.onDelete) {
          this.onDelete(this.trip.id);
        }
      }
    });
  }

  build() {
    Row() {
      if (this.trip.status === 'completed') {
        Button({ type: ButtonType.Normal }) {
          Text('删除')
            .fontColor(Color.White)
            .fontSize(16)
        }
        .width(80)
        .height('100%')
        .backgroundColor('#FF4D4F')
        .onClick(() => {
          this.confirmDelete();
        })
      } else {
        Button({ type: ButtonType.Normal }) {
          Text('完成')
            .fontColor(Color.White)
            .fontSize(16)
        }
        .width(80)
        .height('100%')
        .backgroundColor('#4CAF50')
        .onClick(() => {
          if (this.onComplete) {
            this.onComplete(this.trip.id);
          }
        })
      }
    }
  }
}
