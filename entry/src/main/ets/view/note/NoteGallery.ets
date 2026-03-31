/**
 * @file NoteGallery.ets
 * @brief 笔记图片画廊组件
 * @description 横向轮播展示笔记中的多张图片
 */
import { Note } from '../../model/NoteModel';

@Component
export struct NoteGallery {
  @Prop images: string[] = [];
  @Prop noteId: number | null;

  build() {
    if (this.images.length > 0) {
      Swiper() {
        ForEach(this.images, (img: string, index: number) => {
          Image(img)
            .width('100%')
            .height(350)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)', offsetY: 4 })
            .sharedTransition(this.noteId ? `shared_image_${this.noteId}` : '', {
              duration: 300,
              curve: Curve.Linear,
              delay: 0
            })
        })
      }
      .width('100%')
      .height(350)
      .margin({ bottom: 24 })
      .indicator(Indicator.dot().color('rgba(255,255,255,0.5)').selectedColor($r('app.color.accent')))
    }
  }
}
