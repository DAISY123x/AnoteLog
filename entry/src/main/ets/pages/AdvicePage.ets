/**
 * @file AdvicePage.ets
 * @brief 旅游建议页
 * @description 展示已分享的笔记（旅游建议），支持分类筛选
 * @see NoteRepository
 */
import router from '@ohos.router';
import { NoteRepository } from '../repository/NoteRepository';
import { Note } from '../model/NoteModel';
import { Logger } from '../utils/Logger';

@Entry
@Component
struct AdvicePage {
  @State selectedCategory: string = '全部';
  @State categories: string[] = ['全部', '经验', '美食', '住宿', '交通', '景点'];
  @State advices: Note[] = [];
  @State isLoading: boolean = false;
  private noteRepository: NoteRepository = new NoteRepository();

  aboutToAppear() {
    this.refreshData();
  }

  onPageShow() {
    this.refreshData();
  }

  async refreshData() {
    this.isLoading = true;
    try {
      const category = this.selectedCategory === '全部' ? undefined : this.selectedCategory;
      this.advices = await this.noteRepository.getSharedNotes(category);
    } catch (e) {
      Logger.error('AdvicePage', 'Fetch advice failed', e);
    } finally {
      this.isLoading = false;
    }
  }

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
        Text('旅游建议')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)

      // 分类筛选
      List({ space: 10 }) {
        ForEach(this.categories, (item: string) => {
          ListItem() {
            Text(item)
              .fontSize(14)
              .fontColor(this.selectedCategory === item ? Color.White : '#666')
              .padding({
                left: 16,
                right: 16,
                top: 6,
                bottom: 6
              })
              .backgroundColor(this.selectedCategory === item ? $r('app.color.accent') : '#F0F0F0')
              .borderRadius(16)
              .onClick(() => {
                this.selectedCategory = item;
                this.refreshData();
              })
          }
        })
      }
      .listDirection(Axis.Horizontal)
      .width('100%')
      .height(40)
      .padding({ left: 16, right: 16 })
      .margin({ top: 8, bottom: 8 })

      // 建议列表
      if (this.advices.length === 0) {
        Column() {
          Image($r('app.media.ic_placeholder'))
            .width(120)
            .height(120)
            .opacity(0.5)
            .margin({ bottom: 16 })
          Text('暂无相关建议，去分享一条笔记吧~')
            .fontSize(14)
            .fontColor('#999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.advices, (item: Note) => {
            ListItem() {
              Column() {
                Row() {
                  Text(item.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333')
                    .layoutWeight(1)

                  Text(item.category || '经验')
                    .fontSize(12)
                    .fontColor($r('app.color.accent'))
                    .padding({
                      left: 6,
                      right: 6,
                      top: 2,
                      bottom: 2
                    })
                    .backgroundColor('rgba(0,125,255,0.1)')
                    .borderRadius(4)
                    .margin({ left: 8 })
                }
                .width('100%')

                Text(item.content)
                  .fontSize(14)
                  .fontColor('#666')
                  .margin({ top: 8 })
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Row() {
                  Image($r('app.media.ic_cat_sights')) // Location icon placeholder
                    .width(14)
                    .height(14)
                    .fillColor('#999')
                    .margin({ right: 4 })
                  Text(item.location || '未知地点')
                    .fontSize(12)
                    .fontColor('#999')
                  
                  Blank()

                  Text(new Date(item.createTime || 0).toLocaleDateString())
                    .fontSize(12)
                    .fontColor('#999')
                }
                .width('100%')
                .margin({ top: 12 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .margin({ bottom: 12 })
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/NoteDetailPage',
                  params: { note: item }
                });
              })
            }
            .padding({ left: 16, right: 16 })
          })
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
