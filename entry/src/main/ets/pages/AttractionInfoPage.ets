import router from '@ohos.router';
import { AttractionDetail } from '../service/AIService';

@Entry
@Component
struct AttractionInfoPage {
  @State detail: AttractionDetail | null = null;
  @State title: string = '';

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      if (params['detail']) {
        this.detail = params['detail'] as AttractionDetail;
      }
      if (params['title']) {
        this.title = params['title'] as string;
      }
    }
  }

  @Builder
  InfoItem(label: string, content: string) {
    if (content) {
      Column() {
        Text(label)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ bottom: 4 })
        Text(content)
          .fontSize(16)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ bottom: 12 })
    }
  }

  build() {
    Column() {
      // Navigation Bar
      Row() {
        Image($r('app.media.ic_arrow_back'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .onClick(() => {
            router.back();
          })
        Text('景点详细信息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })
      .zIndex(100)

      if (this.detail) {
        Scroll() {
          Column() {
            // 1. Cover Image
            Image($r('app.media.background11')) 
                .width('100%')
                .height(260)
                .objectFit(ImageFit.Cover)

            Column() {
              // Title Area
              Text(this.title)
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12, top: 20 })
                .fontColor('#1A1A1A')

              // Description
              Text(this.detail.description)
                .fontSize(16)
                .lineHeight(26)
                .fontColor('#444444')
                .margin({ bottom: 24 })
                .textAlign(TextAlign.Start)

              Divider().color('#EEE').margin({ bottom: 20 })

              // Location Section
              Row() {
                Image($r('app.media.ic_cat_sights')) 
                  .width(20).height(20).fillColor('#007DFF').margin({ right: 8 })
                Text('地理位置')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
              }.margin({ bottom: 12 }).width('100%')
              
              Text(`地址: ${this.detail.address}`)
                .fontSize(15).margin({ bottom: 20 })

              // Operating Info Grid
              // Removed phone/duration/bestVisitTime/cost if not available in simplified model
              // But let's check what we kept in AttractionDetail
              // Kept: openingHours, address, tips
              
              // Opening Hours
              Text('营业时间')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 10, bottom: 8 })
              Text(this.detail.openingHours)
                .fontSize(15)
                .fontColor('#666')
                .margin({ bottom: 20 })

              Divider().color('#EEE').margin({ bottom: 20 })

              // Tips
              Text('专业游玩建议')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12 })
              Text(this.detail.tips)
                .fontSize(15)
                .lineHeight(24)
                .fontColor('#555')
                .backgroundColor('#F0F8FF')
                .padding(16)
                .borderRadius(12)
                .width('100%')

              // Bottom Spacer
              Blank().height(40)
            }
            .padding({ left: 20, right: 20 })
          }
        }
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      } else {
        Column() {
          LoadingProgress().width(50).height(50).color(Color.Blue)
          Text('加载详情数据中...')
            .margin({ top: 12 })
            .fontSize(14)
            .fontColor('#999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
