import router from '@ohos.router';
import { RdbManager } from '../common/database/RdbManager';
import { Note } from '../model/NoteModel';
import { promptAction } from '@kit.ArkUI';

interface CardStyle {
  backgroundColor: Resource;
}

@Entry
@Component
struct NoteListPage {
  @State notes: Note[] = [];
  @State isRefreshing: boolean = false;
  @State isLoading: boolean = true;
  @State hasMore: boolean = true;
  private pageSize: number = 15;
  private currentPage: number = 0;

  aboutToAppear() {
    this.refreshData();
  }

  onPageShow() {
    this.refreshData();
  }

  async refreshData() {
    this.isRefreshing = true;
    this.currentPage = 0;
    this.hasMore = true;
    try {
      this.notes = await RdbManager.getInstance().getNotes(this.pageSize, 0);
      if (this.notes.length < this.pageSize) {
        this.hasMore = false;
      }
    } catch (e) {
      console.error('Refresh notes failed', e);
      promptAction.showToast({ message: '刷新失败' });
    } finally {
      this.isRefreshing = false;
      this.isLoading = false;
    }
  }

  async loadMore() {
    if (!this.hasMore || this.isLoading) {
      return;
    }
    this.isLoading = true;
    try {
      this.currentPage++;
      const offset = this.currentPage * this.pageSize;
      const newNotes = await RdbManager.getInstance().getNotes(this.pageSize, offset);
      if (newNotes.length < this.pageSize) {
        this.hasMore = false;
      }
      this.notes = this.notes.concat(newNotes);
    } catch (e) {
      console.error('Load more notes failed', e);
      this.currentPage--;
    } finally {
      this.isLoading = false;
    }
  }

  async deleteNote(id: number | null) {
    if (!id) {
      return;
    }

    try {
      promptAction.showDialog({
        title: '确认删除',
        message: '确定要删除这条笔记吗？此操作不可恢复。',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '删除', color: '#FF4D4F' }
        ]
      }).then(async (res) => {
        if (res.index === 1) {
          await RdbManager.getInstance().deleteNote(id);
          promptAction.showToast({ message: '删除成功' });
          this.refreshData();
        }
      });
    } catch (e) {
      console.error('Delete note failed', e);
    }
  }

  @Builder
  itemEnd(id: number | null) {
    Row() {
      Button({ type: ButtonType.Normal }) {
        Text('删除')
          .fontColor(Color.White)
          .fontSize(16)
      }
      .width(80)
      .height('100%')
      .backgroundColor('#FF4D4F')
      .onClick(() => {
        this.deleteNote(id);
      })
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.EaseOut })
      .slide(SlideEffect.Right)
      .opacity(0)
    PageTransitionExit({ duration: 300, curve: Curve.EaseIn })
      .slide(SlideEffect.Right)
      .opacity(0)
  }

  getCoverImage(note: Note): ResourceStr {
    try {
      // 优先使用笔记中的第二张图片作为封面
      if (note.images) {
        const images = JSON.parse(note.images) as string[];
        if (images && images.length >= 2) {
          return images[1];
        }
      }
      
      // 兼容旧逻辑：如果有coverImage字段且有效
      if (note.coverImage) {
        return $r(`app.media.${note.coverImage}`);
      }
    } catch (e) {
      console.error('Get cover image failed', e);
    }
    // 系统默认封面图片
    return $r('app.media.journal_2');
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
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
          Text('新建笔记')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ left: 16 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.surface'))

        if (this.isLoading && this.notes.length === 0) {
          // Loading State
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color($r('app.color.accent'))
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.notes.length === 0) {
          // Empty State
          Column() {
            Image($r('app.media.ic_placeholder'))
              .width(120)
              .height(120)
              .opacity(0.5)
              .margin({ bottom: 16 })
            Text('暂无笔记，快去创建吧~')
              .fontSize(14)
              .fontColor($r('app.color.text_tertiary'))
          }
          .width('100%')
          .height('80%')
          .justifyContent(FlexAlign.Center)
        } else {
          Refresh({ refreshing: $$this.isRefreshing }) {
            List({ space: 12 }) {
              ForEach(this.notes, (note: Note) => {
                ListItem() {
                  Column() {
                    // 封面图
                    Image(this.getCoverImage(note))
                      .width('100%')
                      .height(160)
                      .objectFit(ImageFit.Cover)
                      .borderRadius({ topLeft: 16, topRight: 16 })
                      .backgroundColor('#E0E0E0')
                      // 添加共享元素转场
                      .sharedTransition(`shared_image_${note.id}`, {
                        duration: 300,
                        curve: Curve.Linear,
                        delay: 0
                      })

                    // 内容区
                    Column() {
                      Text(note.title)
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.text_primary'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Row() {
                        // 标签：地点
                        if (note.location) {
                          Row() {
                            Image($r('app.media.ic_cat_sights'))
                              .width(14)
                              .height(14)
                              .fillColor($r('app.color.accent'))
                              .margin({ right: 4 })
                            Text(note.location)
                              .fontSize(12)
                              .fontColor($r('app.color.accent'))
                          }
                          .backgroundColor($r('app.color.accent_soft'))
                          .padding({
                            left: 8,
                            right: 8,
                            top: 4,
                            bottom: 4
                          })
                          .borderRadius(4)
                          .margin({ right: 8 })
                        }

                        // 标签：时间
                        Text(new Date(note.createTime || 0).toLocaleDateString())
                          .fontSize(12)
                          .fontColor($r('app.color.text_tertiary'))
                      }
                      .width('100%')
                      .margin({ top: 12 })
                    }
                    .padding(16)
                    .width('100%')
                    .backgroundColor($r('app.color.card_bg'))
                    .borderRadius({ bottomLeft: 16, bottomRight: 16 })
                  }
                  .width('100%')
                  .borderRadius(16)
                  // 移除默认白色背景，由内部控制
                  // .backgroundColor(Color.White)
                  .stateStyles({
                    pressed: {
                      scale: { x: 0.98, y: 0.98 }
                    },
                    normal: {
                      scale: { x: 1, y: 1 }
                    }
                  })
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/NoteDetailPage',
                      params: { note: note }
                    });
                  })
                  .gesture(
                    LongPressGesture()
                      .onAction(() => {
                        router.pushUrl({
                          url: 'pages/NoteEditPage',
                          params: { note: note }
                        });
                      })
                  )
                }
                .swipeAction({ end: this.itemEnd(note.id) })
              })

              if (this.isLoading && this.notes.length > 0) {
                ListItem() {
                  Row() {
                    LoadingProgress().width(24).height(24).margin({ right: 8 })
                    Text('加载中...').fontSize(14).fontColor($r('app.color.text_tertiary'))
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.Center)
                  .padding(16)
                }
              }
            }
            .lanes({ minLength: 300, maxLength: 600 }) // 响应式布局：根据屏幕宽度自动调整列数
            .layoutWeight(1)
            .width('100%')
            .padding({
              left: 16,
              right: 16,
              top: 12,
              bottom: 80
            })
            .onReachEnd(() => {
              this.loadMore();
            })
          }
          .onRefreshing(() => {
            this.refreshData();
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.app_bg'))

      // 悬浮加号按钮 (FAB)
      Button() {
        Text('+')
          .fontSize(32)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Lighter)
          .margin({ bottom: 4 })
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backgroundColor($r('app.color.accent'))
      .shadow({ radius: 8, color: 'rgba(0, 125, 255, 0.4)', offsetY: 4 })
      .margin({ right: 24, bottom: 32 })
      .onClick(() => {
        router.pushUrl({ url: 'pages/NoteEditPage' });
      })
    }
    .width('100%')
    .height('100%')
  }
}
