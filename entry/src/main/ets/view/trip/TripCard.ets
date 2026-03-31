/**
 * @file TripCard.ets
 * @brief 行程卡片组件
 * @description 可复用的行程卡片，支持显示日期、名称、地点、状态标签，点击进入编辑，编辑按钮触发回调
 * @see TripViewModel
 */
import router from '@ohos.router';

@Component
export struct TripCard {
  // 行程数据
  @Prop trip: TripViewModel;
  // 编辑按钮回调
  onEdit?: (trip: TripViewModel) => void;
  // 获取状态颜色
  getStatusColor: (status: string) => string = (status: string): string => {
    switch (status) {
      case 'ongoing': return '#4CAF50';
      case 'completed': return '#9E9E9E';
      default: return '#FF9800';
    }
  };
  // 获取状态文字
  getStatusText: (status: string) => string = (status: string): string => {
    switch (status) {
      case 'ongoing': return '进行中';
      case 'completed': return '已完成';
      default: return '计划中';
    }
  };

  build() {
    Column() {
      Row() {
        // 日期区域
        Column() {
          Text(new Date(this.trip.createTime || 0).getDate().toString())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.accent'))
          Text(new Date(this.trip.createTime || 0).toLocaleString('default', { month: 'short' }) + '月')
            .fontSize(12)
            .fontColor('#666')
        }
        .width(50)
        .height(50)
        .backgroundColor('rgba(0, 125, 255, 0.08)')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .margin({ right: 16 })

        // 信息区域
        Column() {
          Text(this.trip.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 6 })

          Row() {
            Image($r('app.media.ic_cat_sights'))
              .width(14)
              .height(14)
              .fillColor('#666')
              .margin({ right: 4 })
            Text(this.trip.location || '未知地区')
              .fontSize(13)
              .fontColor('#666')
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 操作区域：状态标签 + 编辑按钮
        Row() {
          Text(this.getStatusText(this.trip.status || 'planning'))
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor(this.getStatusColor(this.trip.status || 'planning'))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
            .margin({ right: 8 })

          Button('编辑')
            .fontSize(12)
            .height(28)
            .backgroundColor('#F0F0F0')
            .fontColor('#333')
            .onClick(() => {
              if (this.onEdit) {
                this.onEdit(this.trip);
              }
            })
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .onClick(() => {
        router.pushUrl({
          url: 'pages/NewTripPage',
          params: { trip: this.trip }
        });
      })
    }
    .width('100%')
    .borderRadius(16)
    .backgroundColor(Color.White)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
    .margin({ bottom: 16 })
  }
}
