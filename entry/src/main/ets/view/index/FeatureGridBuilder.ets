/**
 * @file FeatureGridBuilder.ets
 * @brief 首页功能四宫格 Builder
 * @description 首页四大功能入口（新建行程、新建笔记、旅游建议、最近行程）
 */
import { promptAction } from '@kit.ArkUI';
import router from '@ohos.router';
import { FunctionalCardItem } from '../../common/types/CommonTypes';

@Component
export struct FeatureGridBuilder {
  @Prop functionalCards: FunctionalCardItem[] = [];
  @BuilderParam onCreateTrip?: () => void;

  /**
   * 卡片按下样式（缩小效果）
   */
  @Styles
  cardPressed(): void {
    .scale({ x: 0.96, y: 0.96 })
  }

  /**
   * 卡片默认样式（正常大小）
   */
  @Styles
  cardNormal(): void {
    .scale({ x: 1, y: 1 })
  }

  build() {
    Column() {
      Row() {
        Text('核心功能')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))

        Blank()

        Row() {
          Text('查看更多')
            .fontSize(14)
            .fontColor($r('app.color.text_tertiary'))
          Image($r('app.media.ic_cat_more'))
            .width(14)
            .height(14)
            .fillColor($r('app.color.icon_secondary'))
            .margin({ left: 4 })
        }
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        bottom: 16,
        top: 30
      })

      Grid() {
        ForEach(this.functionalCards, (item: FunctionalCardItem) => {
          GridItem() {
            Stack({ alignContent: Alignment.TopStart }) {
              Column()
                .width('100%')
                .height('100%')
                .linearGradient({ angle: 135, colors: item.colors })
                .borderRadius(20)
                .shadow({ radius: 10, color: item.shadowColor, offsetY: 6 })

              Circle()
                .width(100)
                .height(100)
                .fill('rgba(255,255,255,0.1)')
                .position({ x: -30, y: -30 })

              Circle()
                .width(20)
                .height(20)
                .fill('rgba(255,255,255,0.2)')
                .position({ x: '80%', y: '70%' })

              Column() {
                Column() {
                  Image(item.icon)
                    .width(32)
                    .height(32)
                    .objectFit(ImageFit.Contain)
                    .fillColor(Color.White)
                }
                .width(56)
                .height(56)
                .borderRadius(28)
                .backgroundColor('rgba(255,255,255,0.2)')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)

                Blank()

                Text(item.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .letterSpacing(1)
              }
              .width('100%')
              .height('100%')
              .padding(16)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .height(140)
            .stateStyles({
              pressed: this.cardPressed,
              normal: this.cardNormal
            })
            .animation({ duration: 200 })
            .onClick(() => {
              if (item.id === 1) {
                if (this.onCreateTrip) {
                  this.onCreateTrip();
                }
              } else if (item.id === 2) {
                router.pushUrl({ url: 'pages/NoteListPage' });
              } else if (item.id === 3) {
                router.pushUrl({ url: 'pages/AdvicePage' });
              } else if (item.id === 4) {
                router.pushUrl({ url: 'pages/RecentTripsPage' });
              } else {
                promptAction.showToast({ message: item.title + ' 功能开发中' });
              }
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(16)
      .rowsGap(16)
      .height(296)
      .padding({ left: 20, right: 20 })
    }
  }
}
