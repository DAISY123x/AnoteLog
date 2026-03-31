/**
 * @file SearchPage.ets
 * @brief 搜索页
 * @description 搜索地点，支持按关键字过滤
 * @see MapService
 */
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { Logger } from '../utils/Logger';

import { MapService, PlaceResult } from '../service/MapService';

export interface SearchResult {
  id: number | string;
  title: string;
  address: string;
  type: string;
  icon?: string;
  latitude?: number;
  longitude?: number;
}

@Entry
@Component
struct SearchPage {
  @State searchText: string = '';
  @State searchResults: SearchResult[] = [];
  @State recommendTags: string[] = ['故宫博物院', '环球影城', '天安门广场', '颐和园', '南锣鼓巷'];
  @StorageLink('selectedSearchResult') selectedSearchResult: SearchResult | null = null;
  @StorageLink('isNetworkAvailable') isNetworkAvailable: boolean = true;
  private searchTimer: number = -1;

  build() {
    Column() {
      // 顶部搜索栏
      Row() {
        Image($r('app.media.ic_arrow_back'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .onClick(() => {
            router.back();
          })
          .margin({ right: 12 })

        Row() {
          Image($r('app.media.ic_search'))
            .width(18)
            .height(18)
            .fillColor('#999999')
            .margin({ left: 12 })

          TextInput({ placeholder: '输入旅游地址或景点名称', text: this.searchText })
            .layoutWeight(1)
            .height(40)
            .backgroundColor(Color.Transparent)
            .placeholderColor('#999999')
            .fontSize(14)
            .enabled(this.isNetworkAvailable)
            .onChange((value: string) => {
              this.searchText = value;
              this.handleSearchInput(value);
            })
        }
        .layoutWeight(1)
        .height(40)
        .backgroundColor(this.isNetworkAvailable ? '#F5F5F5' : '#E0E0E0')
        .borderRadius(20)

        Text('搜索')
          .fontSize(16)
          .fontColor(this.isNetworkAvailable ? $r('app.color.accent') : '#999')
          .margin({ left: 12 })
          .enabled(this.isNetworkAvailable)
          .onClick(() => {
            this.performSearch(this.searchText);
          })
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 12,
        bottom: 12
      })
      .backgroundColor(Color.White)

      if (!this.isNetworkAvailable) {
        Text('当前网络不可用，搜索功能受限')
          .width('100%')
          .padding(8)
          .backgroundColor('#FFF0F0')
          .fontColor('#FF4D4F')
          .fontSize(12)
          .textAlign(TextAlign.Center)
      }

      // 内容区域
      if (this.searchText.length === 0) {
        // 推荐标签
        Column({ space: 16 }) {
          Text('热门推荐')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.recommendTags, (tag: string) => {
              Text(tag)
                .fontSize(13)
                .fontColor('#333333')
                .padding({
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 8
                })
                .backgroundColor('#F5F5F5')
                .borderRadius(18)
                .margin({ right: 10, bottom: 10 })
                .onClick(() => {
                  this.searchText = tag;
                  this.handleSearchInput(tag);
                })
            })
          }
        }
        .padding(20)
        .alignItems(HorizontalAlign.Start)
      } else {
        // 搜索结果列表
        List() {
          ForEach(this.searchResults, (item: SearchResult) => {
            ListItem() {
              Row() {
                // 占位图或实际图片
                Image(item.icon ? item.icon : $r('app.media.ic_placeholder'))
                  .width(80)
                  .height(80)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)
                  .backgroundColor('#F0F0F0')
                  .onError(() => {
                    // Fallback if load fails
                    Logger.warn('SearchPage', 'Failed to load icon: ' + item.icon);
                  })

                Column() {
                  Text(item.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                    .margin({ bottom: 4 })

                  Text(item.address)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ bottom: 4 })

                  Text(item.type)
                    .fontSize(10)
                    .fontColor('#007DFF')
                    .backgroundColor('#E0F0FF')
                    .padding({
                      left: 6,
                      right: 6,
                      top: 2,
                      bottom: 2
                    })
                    .borderRadius(4)
                }
                .layoutWeight(1)
                .margin({ left: 12 })
                .alignItems(HorizontalAlign.Start)
              }
              .padding({
                left: 16,
                right: 16,
                top: 12,
                bottom: 12
              })
              .backgroundColor(Color.White)
              .onClick(() => {
                // 点击跳转详情或直接选择
                // 这里我们直接选择，或者跳转详情后再选择
                // 为了简化流程，直接选择
                this.selectPlace(item);
              })
            }
          })
        }
        .layoutWeight(1)
        .divider({
          strokeWidth: 1,
          color: '#F0F0F0',
          startMargin: 88,
          endMargin: 0
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
  handleSearchInput(keyword: string) {
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
    }
    this.searchTimer = setTimeout(() => {
      // 使用箭头函数绑定this上下文
      this.performSearch(keyword);
    }, 300);
  }

  async performSearch(keyword: string) {
    if (!this.isNetworkAvailable) {
      Logger.warn('SearchPage', 'Network flag is false, attempting search anyway...');
      promptAction.showToast({ message: '网络状态不佳，正在尝试搜索...' });
      // Remove blocking return
    }
    if (!keyword) {
      this.searchResults = [];
      return;
    }
    try {
      Logger.info('SearchPage', `Starting search for: ${keyword}`);
      const places = await MapService.getInstance().searchPlaces(keyword);
      Logger.info('SearchPage', `Got ${places.length} results`);
      this.searchResults = places.map(p => {
        return {
          id: p.id,
          title: p.name,
          address: p.address,
          type: p.type || '其他',
          icon: p.icon,
          latitude: p.location.latitude,
          longitude: p.location.longitude
        } as SearchResult;
      });
    } catch (err) {
      Logger.error('SearchPage', `Search failed with error: ${JSON.stringify(err)}`);
      // Extract error message if possible
      let msg = '搜索失败，请重试';
      if (err instanceof Error) {
        msg = err.message;
      } else if (typeof err === 'string') {
        msg = err;
      }

      promptAction.showToast({ message: msg });
    }
  }

  selectPlace(place: SearchResult) {
    // Explicitly set AppStorage
    AppStorage.setOrCreate('selectedSearchResult', place);
    Logger.info('SearchPage', `Selected place: ${place.title}`);
    router.back();
  }
}
