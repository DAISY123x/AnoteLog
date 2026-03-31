/**
 * @file NoteSidebar.ets
 * @brief 笔记详情页侧边栏组件
 * @description 显示用户信息、地点、分享按钮
 * @see Note
 */
import { promptAction } from '@kit.ArkUI';

@Component
export struct NoteSidebar {
  @Prop note: Note | null;

  build() {
    Column() {
      // 用户信息
      Row() {
        Image($r('app.media.girl22'))
          .width(50).height(50).borderRadius(25).objectFit(ImageFit.Cover)
          .border({ width: 2, color: Color.White })
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)' })

        Column() {
          Text('旅行达人')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          Text(new Date(this.note?.createTime || 0).toLocaleDateString())
            .fontSize(12).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
        }
        .margin({ left: 12 }).alignItems(HorizontalAlign.Start)
      }
      .width('100%').margin({ bottom: 24 })

      // 地点信息
      Row() {
        Image($r('app.media.ic_cat_sights'))
          .width(18).height(18).fillColor($r('app.color.accent'))
        Text(this.note?.location || '未知地点')
          .fontSize(14).fontColor($r('app.color.text_primary')).margin({ left: 8 })
      }
      .width('100%').padding(12)
      .backgroundColor($r('app.color.accent_soft')).borderRadius(8)
      .margin({ bottom: 24 })

      // 分享按钮
      Button() {
        Row() {
          Image($r('app.media.ic_share'))
            .width(18).height(18).fillColor(Color.White).margin({ right: 8 })
          Text('分享笔记').fontColor(Color.White).fontSize(16).fontWeight(FontWeight.Medium)
        }
      }
      .width('100%').height(44)
      .backgroundColor($r('app.color.danger'))
      .shadow({ radius: 8, color: 'rgba(255, 107, 107, 0.4)', offsetY: 4 })
      .onClick(() => { promptAction.showToast({ message: '分享功能开发中' }); })
    }
    .padding(20)
    .backgroundColor('rgba(255, 255, 255, 0.8)')
    .backdropBlur(20)
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)' })
  }
}
