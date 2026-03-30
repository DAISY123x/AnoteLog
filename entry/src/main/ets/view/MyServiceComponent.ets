import { RouterManager } from '../common/utils/RouterManager';

@Component
export struct MyServiceComponent {
  
  @Builder ServiceCard(title: string, desc: string, icon: ResourceStr, url: string) {
    Row() {
      // Icon Container
      Column() {
        Image(icon)
          .width(28)
          .height(28)
          .fillColor($r('app.color.accent'))
      }
      .width(56)
      .height(56)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor($r('app.color.accent_soft'))
      .borderRadius(16)
      .margin({ right: 16 })

      // Text Content
      Column() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 6 })
        Text(desc)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(18)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // Arrow Icon
      Image($r('app.media.ic_arrow_back')) 
        .width(20)
        .height(20)
        .fillColor($r('app.color.icon_secondary'))
        .rotate({ angle: 180 })
        .margin({ left: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.03)', offsetY: 4 })
    .margin({ bottom: 12 })
    .onClick(() => {
      RouterManager.getInstance().push(url);
    })
  }

  build() {
    Column() {
      // Title Section (Optional, if needed to separate from other sections)
      // Text('常用服务')
      //   .fontSize(18)
      //   .fontWeight(FontWeight.Bold)
      //   .margin({ bottom: 16, left: 4 })
      
      this.ServiceCard(
        '待完成的行程', 
        '查看和管理您正在进行或计划中的行程', 
        $r('app.media.ic_trip_normal'), 
        'pages/PendingTripsPage'
      )
      
      this.ServiceCard(
        '我的点赞', 
        '收藏您喜欢的笔记和景点', 
        $r('app.media.ic_home_normal'), 
        'pages/MyLikesPage'
      )
      
      this.ServiceCard(
        '设备同步', 
        '多端数据实时同步，随时随地查看', 
        $r('app.media.ic_share'), 
        'pages/DeviceSyncPage'
      )
      
      this.ServiceCard(
        '反馈建议', 
        '帮助我们改进产品体验', 
        $r('app.media.ic_func_advice'), 
        'pages/FeedbackPage'
      )

      this.ServiceCard(
        '地点管理', 
        '添加和管理您的自定义地点', 
        $r('app.media.ic_cat_sights'), 
        'pages/PlaceManagementPage'
      )
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8 })
  }
}
