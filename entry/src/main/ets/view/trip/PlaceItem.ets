/**
 * @file PlaceItem.ets
 * @brief 行程地点项组件
 * @description 显示地点序号、图标、名称、类型，支持拖拽预览
 * @see TripPlace
 */
import router from '@ohos.router';

@Component
export struct PlaceItem {
  @Prop place: TripPlace;
  @Prop index: number;

  build() {
    Row() {
      Text(`${this.index + 1}`)
        .fontSize(14)
        .fontColor('#999')
        .width(24)
        .textAlign(TextAlign.Center)

      Image(this.place.icon || $r('app.media.ic_cat_sights'))
        .width(40)
        .height(40)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .margin({ left: 8, right: 12 })

      Column() {
        Text(this.place.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.place.type)
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.ic_cat_more'))
        .width(20)
        .height(20)
        .opacity(0.5)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
  }
}

/**
 * 地点滑动删除按钮
 */
@Component
export struct SwipeDelete {
  onDelete: () => void;

  build() {
    Row() {
      Text('删除')
        .fontColor(Color.White)
        .fontSize(14)
    }
    .width(80)
    .height('100%')
    .backgroundColor('#FF3B30')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.onDelete(); })
  }
}

/**
 * 地点拖拽预览样式
 */
@Component
export struct PlaceItemDragPreview {
  @Prop place: TripPlace;

  build() {
    Row() {
      Image(this.place.icon || $r('app.media.ic_cat_sights'))
        .width(40)
        .height(40)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .margin({ right: 12 })
      Text(this.place.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
    }
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .width(200)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)' })
  }
}
