/**
 * @file TripFeedBuilder.ets
 * @brief 首页旅行动态 Feed Builder
 * @description 首页下方推荐旅行笔记列表
 */
import router from '@ohos.router';
import { UserTripItem } from '../../common/types/CommonTypes';
import { PlaceDetailParams } from '../../pages/PlaceDetailPage';

@Component
export struct TripFeedBuilder {
  @Prop userTrips: UserTripItem[] = [];

  build() {
    List({ space: 20 }) {
      ForEach(this.userTrips, (item: UserTripItem) => {
        ListItem() {
          Column() {
            Image(item.imageSrc)
              .width('100%')
              .height(200)
              .objectFit(ImageFit.Cover)
              .borderRadius({ topLeft: 16, topRight: 16 })
              .backgroundColor('#E0E0E0')
              .alt($r('app.media.ic_placeholder'))

            Column() {
              Text(item.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Row() {
                Image($r('app.media.ic_cat_sights'))
                  .width(14)
                  .height(14)
                  .fillColor('#007DFF')
                  .margin({ right: 4 })
                Text(item.location)
                  .fontSize(13)
                  .fontColor('#666')

                Blank()

                Text(item.date)
                  .fontSize(12)
                  .fontColor('#999')
              }
              .width('100%')
              .margin({ top: 8, bottom: 16 })

              Row() {
                Image(item.userAvatar)
                  .width(32)
                  .height(32)
                  .borderRadius(16)
                  .margin({ right: 8 })
                  .border({ width: 1, color: '#EEE' })

                Text(item.userName)
                  .fontSize(14)
                  .fontColor('#333')
                  .fontWeight(FontWeight.Medium)

                Blank()

                Row() {
                  Image($r('app.media.ic_home_normal'))
                    .width(18)
                    .height(18)
                    .fillColor('#FF5E62')
                  Text(item.likes.toString())
                    .fontSize(13)
                    .fontColor('#666')
                    .margin({ left: 6 })
                }
                .backgroundColor('#FFF0F0')
                .padding({
                  left: 10,
                  right: 10,
                  top: 6,
                  bottom: 6
                })
                .borderRadius(14)
              }
              .width('100%')
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius({ bottomLeft: 16, bottomRight: 16 })
          }
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.06)', offsetY: 4 })
          .onClick(() => {
            const placeList = this.userTrips.map((t) => ({
              id: t.id,
              title: t.title,
              type: 'sights',
              distanceKm: 0,
              durationMin: 0,
              latitude: 0,
              longitude: 0,
              note: t.location
            } as PlaceDetailParams));

            router.pushUrl({
              url: 'pages/PlaceDetailPage',
              params: {
                placeList: placeList,
                initialIndex: this.userTrips.indexOf(item)
              }
            });
          })
        }
      })
    }
    .padding({ left: 20, right: 20, bottom: 30 })
  }
}
