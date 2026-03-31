/**
 * @file NotificationPage.ets
 * @brief 通知页
 * @description 展示系统通知列表
 */
import router from '@ohos.router';

interface NotificationItem {
  id: number;
  title: string;
  content: string;
  time: string;
  isRead: boolean;
}

@Entry
@Component
struct NotificationPage {
  @State notifications: NotificationItem[] = [
    {
      id: 1,
      title: '系统通知',
      content: '欢迎使用旅游攻略助手！',
      time: '10:00',
      isRead: false
    },
    {
      id: 2,
      title: '行程提醒',
      content: '您的"夏威夷之旅"即将开始。',
      time: '昨天',
      isRead: true
    },
    {
      id: 3,
      title: '互动消息',
      content: 'Alice 赞了你的笔记。',
      time: '前天',
      isRead: true
    }
  ];

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_arrow_back'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.icon_primary'))
          .onClick(() => {
            router.back();
          })
        Text('消息通知')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)

      // 消息列表
      List() {
        ForEach(this.notifications, (item: NotificationItem) => {
          ListItem() {
            Row() {
              // 图标
              Image($r('app.media.ic_func_advice')) // 复用图标
                .width(40)
                .height(40)
                .padding(8)
                .backgroundColor('#F0F0F0')
                .borderRadius(20)
                .fillColor($r('app.color.accent'))

              Column() {
                Row() {
                  Text(item.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))

                  Blank()

                  Text(item.time)
                    .fontSize(12)
                    .fontColor('#999')
                }
                .width('100%')

                Text(item.content)
                  .fontSize(14)
                  .fontColor('#666')
                  .margin({ top: 4 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .margin({ left: 12 })

              // 未读红点
              if (!item.isRead) {
                Circle({ width: 8, height: 8 })
                  .fill(Color.Red)
                  .margin({ left: 8 })
              }
            }
            .width('100%')
            .padding({
              left: 16,
              right: 16,
              top: 12,
              bottom: 12
            })
            .backgroundColor(Color.White)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 1, color: '#F0F0F0', startMargin: 68 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
