/**
 * @file BannerViewBuilder.ets
 * @brief 首页 Banner 轮播图 Builder
 * @description 首页顶部轮播 Banner，支持自动播放和指示器
 */
import router from '@ohos.router';
import { BannerItem } from '../../common/types/CommonTypes';
import { PlaceDetailParams } from '../../pages/PlaceDetailPage';

@Component
export struct BannerViewBuilder {
  @Prop banners: BannerItem[] = [];

  build() {
    Column() {
      Text('必玩推荐')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ left: 20, bottom: 16, top: 8 })
        .width('100%')

      Swiper() {
        ForEach(this.banners, (item: BannerItem) => {
          Stack({ alignContent: Alignment.BottomStart }) {
            Image(item.imageSrc)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .borderRadius(20)
              .backgroundColor('#E0E0E0')
              .alt($r('app.media.ic_placeholder'))

            Column()
              .width('100%')
              .height('50%')
              .linearGradient({
                angle: 180,
                colors: [['rgba(0,0,0,0)', 0], ['rgba(0,0,0,0.7)', 1]]
              })
              .borderRadius({ bottomLeft: 20, bottomRight: 20 })

            Text(item.title)
              .fontColor(Color.White)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 20, bottom: 20 })
              .textShadow({ radius: 4, color: 'rgba(0,0,0,0.5)' })
          }
          .width('100%')
          .height(220)
          .padding({ left: 20, right: 20 })
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.1)', offsetY: 4 })
          .onClick(() => {
            const placeList = this.banners.map((b, idx) => ({
              id: b.id,
              title: b.title,
              type: 'sights',
              distanceKm: 0,
              durationMin: 120,
              latitude: 0,
              longitude: 0,
              note: b.title
            } as PlaceDetailParams));

            router.pushUrl({
              url: 'pages/PlaceDetailPage',
              params: {
                placeList: placeList,
                initialIndex: this.banners.indexOf(item)
              }
            });
          })
        })
      }
      .autoPlay(true)
      .interval(4000)
      .indicator(
        Indicator.dot()
          .itemWidth(6)
          .itemHeight(6)
          .selectedItemWidth(24)
          .selectedItemHeight(6)
          .color('rgba(255,255,255,0.4)')
          .selectedColor(Color.White)
          .bottom(12)
      )
    }
    .margin({ top: 8 })
  }
}
