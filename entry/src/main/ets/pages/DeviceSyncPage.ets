import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { MyServiceWrapper } from '../service/MyServiceWrapper';
import { Device } from '../service/DeviceService';
import { RouterManager } from '../common/utils/RouterManager';

@Entry
@Component
struct DeviceSyncPage {
  @State devices: Device[] = [];
  @State isSyncing: boolean = false;
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadDevices();
  }

  async loadDevices() {
    this.isLoading = true;
    try {
      this.devices = await MyServiceWrapper.getInstance().getBoundDevices();
    } catch (e) {
      console.error('Failed to load devices', e);
      promptAction.showToast({ message: '加载设备列表失败' });
    } finally {
      this.isLoading = false;
    }
  }

  async startSync() {
    if (this.isSyncing) {
      return;
    }
    this.isSyncing = true;
    try {
      await MyServiceWrapper.getInstance().syncDevices();
      // Update local last sync time for display
      this.devices = this.devices.map((d: Device): Device => {
        return {
          id: d.id,
          name: d.name,
          type: d.type,
          lastSyncTime: Date.now(),
          isCurrent: d.isCurrent
        };
      });
      promptAction.showToast({ message: '同步完成' });
    } catch (e) {
      console.error('Sync failed', e);
      promptAction.showToast({ message: '同步失败' });
    } finally {
      this.isSyncing = false;
    }
  }

  getIcon(type: string): Resource {
    switch (type) {
      case 'tablet':
        return $r('app.media.ic_home_normal'); // Placeholder
      case 'watch':
        return $r('app.media.ic_cat_more'); // Placeholder
      case 'pc':
        return $r('app.media.ic_func_notes'); // Placeholder
      default:
        return $r('app.media.ic_trip_normal'); // Placeholder
    }
  }

  @Builder
  DeviceCard(device: Device) {
    Row() {
      // Icon
      Image(this.getIcon(device.type))
        .width(40)
        .height(40)
        .fillColor('#666')
        .margin({ right: 16 })
        .padding(8)
        .backgroundColor('#F0F0F0')
        .borderRadius(20)

      Column() {
        Row() {
          Text(device.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
          if (device.isCurrent) {
            Text('本机')
              .fontSize(10)
              .fontColor($r('app.color.accent'))
              .backgroundColor('rgba(0,125,255,0.1)')
              .padding({
                left: 4,
                right: 4,
                top: 2,
                bottom: 2
              })
              .borderRadius(4)
              .margin({ left: 8 })
          }
        }
        .margin({ bottom: 4 })

        Text(`上次同步: ${new Date(device.lastSyncTime).toLocaleString()}`)
          .fontSize(12)
          .fontColor('#999')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (device.isCurrent) {
        Text('已连接')
          .fontSize(12)
          .fontColor('#4CAF50')
      } else {
        Text('云端同步')
          .fontSize(12)
          .fontColor('#999')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  build() {
    Column() {
      // Top Bar
      Row() {
        Image($r('app.media.ic_arrow_back'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.icon_primary'))
          .onClick(() => {
            RouterManager.getInstance().back();
          })
        Text('设备同步')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)

      // Main Content
      Column() {
        // Sync Status Circle
        Column() {
          if (this.isSyncing) {
            LoadingProgress()
              .width(80)
              .height(80)
              .color(Color.White)
          } else {
            Image($r('app.media.ic_share')) // Sync icon
              .width(60)
              .height(60)
              .fillColor(Color.White)
          }

          Text(this.isSyncing ? '正在同步数据...' : '多端数据已同步')
            .fontSize(16)
            .fontColor(Color.White)
            .margin({ top: 16 })

          Text('确保您的数据在所有设备上保持最新')
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.8)')
            .margin({ top: 8 })
        }
        .width('100%')
        .height(200)
        .backgroundColor($r('app.color.accent'))
        .justifyContent(FlexAlign.Center)

        // Device List
        Text('我的设备')
          .fontSize(14)
          .fontColor('#666')
          .width('100%')
          .padding({ left: 16, top: 20, bottom: 8 })

        if (this.isLoading) {
          LoadingProgress()
            .width(40)
            .height(40)
            .margin({ top: 20 })
        } else {
          List({ space: 12 }) {
            ForEach(this.devices, (device: Device) => {
              ListItem() {
                this.DeviceCard(device)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16 })
        }

        // Sync Button
        Button(this.isSyncing ? '同步中...' : '立即同步')
          .width('90%')
          .height(44)
          .backgroundColor($r('app.color.accent'))
          .margin({ bottom: 32, top: 16 })
          .enabled(!this.isSyncing)
          .onClick(() => {
            this.startSync();
          })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
