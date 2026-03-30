import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct ProfileEditPage {
  @State nickname: string = '已登录用户';
  @State signature: string = '热爱生活，热爱旅行';
  @State gender: string = '保密';

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
        Text('编辑资料')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 16 })
          
        Blank()
        
        Text('保存')
          .fontSize(16)
          .fontColor($r('app.color.accent'))
          .onClick(() => {
            promptAction.showToast({ message: '保存成功' });
            router.back();
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)

      Column({ space: 1 }) {
        // 头像
        Row() {
          Text('头像')
            .fontSize(16)
            .fontColor('#333')
          
          Blank()
          
          Image('https://img.icons8.com/color/96/user-male-circle--v1.png')
            .width(50)
            .height(50)
            .borderRadius(25)
          
          Image($r('app.media.ic_arrow_back')) // Chevron right placeholder (using back icon rotated or just generic)
            .width(16)
            .height(16)
            .fillColor('#999')
            .margin({ left: 8 })
            .rotate({ angle: 180 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .onClick(() => {
          promptAction.showToast({ message: '更换头像功能开发中' });
        })

        // 昵称
        Row() {
          Text('昵称')
            .fontSize(16)
            .fontColor('#333')
          
          Blank()
          
          TextInput({ text: this.nickname, placeholder: '请输入昵称' })
            .textAlign(TextAlign.End)
            .backgroundColor(Color.Transparent)
            .layoutWeight(1)
            .onChange((value) => { this.nickname = value; })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)

        // 签名
        Row() {
          Text('个性签名')
            .fontSize(16)
            .fontColor('#333')
          
          Blank()
          
          TextInput({ text: this.signature, placeholder: '请输入签名' })
            .textAlign(TextAlign.End)
            .backgroundColor(Color.Transparent)
            .layoutWeight(1)
            .onChange((value) => { this.signature = value; })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        
        // 性别
        Row() {
          Text('性别')
            .fontSize(16)
            .fontColor('#333')
          
          Blank()
          
          Text(this.gender)
            .fontSize(16)
            .fontColor('#666')
            .onClick(() => {
              promptAction.showActionMenu({
                title: '选择性别',
                buttons: [
                  { text: '男', color: '#000000' },
                  { text: '女', color: '#000000' },
                  { text: '保密', color: '#000000' }
                ]
              }).then((res) => {
                 if (res.index === 0) this.gender = '男';
                 else if (res.index === 1) this.gender = '女';
                 else this.gender = '保密';
              });
            })
            
          Image($r('app.media.ic_arrow_back'))
            .width(16)
            .height(16)
            .fillColor('#999')
            .margin({ left: 8 })
            .rotate({ angle: 180 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
      }
      .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
