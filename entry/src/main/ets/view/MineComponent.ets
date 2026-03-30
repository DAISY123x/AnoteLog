import { RouterManager } from '../common/utils/RouterManager';
import { MyServiceComponent } from './MyServiceComponent';
import { promptAction } from '@kit.ArkUI';

@Component
export struct MineComponent {
  @StorageLink('isLogin') isLogin: boolean = false;

  build() {
    Column() {
      // 1. 顶部用户信息区
      Stack({ alignContent: Alignment.TopEnd }) {
        Column() {
          Row() {
            Image(this.isLogin ? 'https://img.icons8.com/color/96/user-male-circle--v1.png' :
              $r('app.media.ic_placeholder'))
              .width(80)
              .height(80)
              .borderRadius(40)
              .backgroundColor('#FFF')
              .margin({ right: 16 })

            Column() {
              Text(this.isLogin ? '已登录用户' : '未登录')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333')
                .margin({ bottom: 8 })

              Text(this.isLogin ? '热爱生活，热爱旅行' : '登录后体验更多功能')
                .fontSize(14)
                .fontColor('#666')
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding({ top: 40, left: 24, bottom: 30 })
          .onClick(() => {
            if (!this.isLogin) {
              RouterManager.getInstance().push('pages/LoginPage');
            } else {
              RouterManager.getInstance().push('pages/ProfileEditPage');
            }
          })

          // 数据概览
          if (this.isLogin) {
            Row() {
              this.StatItem('城市', '12')
              this.StatItem('足迹', '56')
              this.StatItem('获赞', '1.2k')
              this.StatItem('粉丝', '328')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
            .padding({ bottom: 20 })
          }
        }
        .width('100%')
        .backgroundColor(Color.White)

        // 顶部设置与消息图标
        Row() {
          Image($r('app.media.ic_func_advice')) // Icon placeholder for Notification
            .width(24)
            .height(24)
            .fillColor('#333')
            .margin({ right: 20 })
            .onClick(() => {
              RouterManager.getInstance().push('pages/NotificationPage');
            })

          Image($r('app.media.ic_cat_more')) // Icon placeholder for Settings
            .width(24)
            .height(24)
            .fillColor('#333')
            .onClick(() => {
              promptAction.showToast({ message: '设置功能开发中' });
            })
        }
        .margin({ top: 16, right: 16 })
      }
      .margin({ bottom: 12 })

      // 2. 常用功能列表 (功能列表卡片) - 使用重构后的组件
      MyServiceComponent()

      // 3. 成就系统
      Column() {
        Row() {
          Text('我的成就')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
          
          Blank()

          Text('查看全部 >')
            .fontSize(12)
            .fontColor('#999')
        }
        .width('100%')
        .padding(16)

        List({ space: 12 }) {
          ListItem() {
            this.AchievementCard('旅行达人', '访问超过10个城市', '#FFD700')
          }

          ListItem() {
            this.AchievementCard('摄影大师', '发布超过50张照片', '#C0C0C0')
          }

          ListItem() {
            this.AchievementCard('早期用户', '注册时间超过1年', '#CD7F32')
          }
        }
        .listDirection(Axis.Horizontal)
        .width('100%')
        .height(100)
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .width('100%')
      .backgroundColor(Color.White)
      .margin({ top: 20 })

      if (this.isLogin) {
        Button('退出登录')
          .width('90%')
          .height(44)
          .margin({ top: 30 })
          .backgroundColor('#FFF')
          .fontColor('#FF4D4F')
          .onClick(() => {
            AppStorage.setOrCreate('isLogin', false);
            promptAction.showToast({ message: '已退出登录' });
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  StatItem(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ bottom: 4 })
      Text(label)
        .fontSize(12)
        .fontColor('#999')
    }
  }

  @Builder
  AchievementCard(title: string, desc: string, color: string) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .margin({ bottom: 4 })
      Text(desc)
        .fontSize(10)
        .fontColor('rgba(255,255,255,0.8)')
    }
    .width(140)
    .height(80)
    .backgroundColor(color)
    .borderRadius(8)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
    .padding(12)
  }
}
