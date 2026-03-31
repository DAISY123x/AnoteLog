/**
 * @file PlaceManagementPage.ets
 * @brief 地点管理页
 * @description 管理用户自定义地点，支持查看和删除
 * @see PlaceService
 */
import router from '@ohos.router';
import { CustomPlace } from '../model/CustomPlaceModel';
import { PlaceService } from '../service/PlaceService';
import promptAction from '@ohos.promptAction';
import { Logger } from '../utils/Logger';

@Entry
@Component
struct PlaceManagementPage {
  @State places: CustomPlace[] = [];
  @State searchText: string = '';

  onPageShow() {
    this.loadPlaces();
  }

  async loadPlaces() {
    this.places = await PlaceService.getInstance().getPlaces(this.searchText);
  }

  build() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.ic_arrow_back'))
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('地点管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
        Text('导出')
          .fontSize(16)
          .fontColor(Color.Blue)
          .onClick(() => this.exportData())
      }
      .width('100%')
      .padding(16)
      .height(56)
      .backgroundColor(Color.White)

      // Search
      Search({ placeholder: '搜索地点名称...' })
        .width('95%')
        .height(40)
        .margin({ top: 10, bottom: 10 })
        .onChange((value) => {
          this.searchText = value;
          this.loadPlaces();
        })

      // List
      List() {
        ForEach(this.places, (item: CustomPlace) => {
          ListItem() {
            Row() {
              Column() {
                Text(item.name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text(item.address)
                  .fontSize(14)
                  .fontColor(Color.Gray)
                  .margin({ top: 4 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Row() {
                  Text(item.type)
                    .fontSize(12)
                    .fontColor(Color.Blue)
                    .backgroundColor('#E3F2FD')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(4)
                  
                  if (item.contact) {
                    Text(item.contact)
                      .fontSize(12)
                      .fontColor(Color.Gray)
                      .margin({ left: 8 })
                  }
                }
                .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Row({ space: 8 }) {
                Button('编辑')
                  .type(ButtonType.Normal)
                  .backgroundColor('#4CAF50')
                  .height(30)
                  .fontSize(12)
                  .borderRadius(4)
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/AddPlacePage',
                      params: { id: item.id }
                    });
                  })

                Button('删除')
                  .type(ButtonType.Normal)
                  .backgroundColor(Color.Red)
                  .height(30)
                  .fontSize(12)
                  .borderRadius(4)
                  .onClick(() => this.deletePlace(item.id!))
              }
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ bottom: 8 })
          }
        })
      }
      .width('95%')
      .layoutWeight(1)

      // Add Button
      Button('+ 添加新地点')
        .width('90%')
        .height(48)
        .margin({ bottom: 20 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/AddPlacePage' });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  async deletePlace(id: number) {
    try {
      await PlaceService.getInstance().deletePlace(id);
      this.loadPlaces();
      promptAction.showToast({ message: '删除成功' });
    } catch (e) {
      promptAction.showToast({ message: '删除失败' });
    }
  }

  async exportData() {
    try {
      const json = await PlaceService.getInstance().exportPlacesJson();
      Logger.info('PlaceManagementPage', `Export Data: ${json}`);
      promptAction.showToast({ message: '数据已导出到日志 (Console)' });
    } catch (e) {
      promptAction.showToast({ message: '导出失败' });
    }
  }
}
