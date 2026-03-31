/**
 * @file NoteDetailPage.ets
 * @brief 笔记详情页
 * @description 查看笔记详情，支持点赞、分享、编辑和删除操作
 * @see NoteRepository, LikeRepository
 */
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NoteRepository } from '../repository/NoteRepository';
import { LikeRepository } from '../repository/LikeRepository';
import { Note } from '../model/NoteModel';
import { Logger } from '../utils/Logger';

@Entry
@Component
struct NoteDetailPage {
  @State note: Note | null = null;
  @State noteImages: string[] = [];
  @State isLiked: boolean = false;
  private noteRepository: NoteRepository = new NoteRepository();
  private likeRepository: LikeRepository = new LikeRepository();

  async checkLikeStatus() {
    if (this.note && this.note.id) {
      this.isLiked = await this.likeRepository.isLiked(this.note.id, 'note');
    }
  }

  async toggleLike() {
    if (this.note && this.note.id) {
      const liked = await this.likeRepository.toggleLike(this.note.id, 'note');
      this.isLiked = liked;
      if (liked) {
        promptAction.showToast({ message: '已点赞' });
      } else {
        promptAction.showToast({ message: '已取消点赞' });
      }
    }
  }

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['note']) {
      this.note = params['note'] as Note;
      try {
        if (this.note.images) {
          this.noteImages = JSON.parse(this.note.images);
        }
      } catch (e) {
        Logger.error('NoteDetailPage', 'Parse images failed', e);
        this.noteImages = [];
      }
      this.checkLikeStatus();
    }
  }

  async deleteNote() {
    if (!this.note || !this.note.id) {
      return;
    }

    promptAction.showDialog({
      title: '确认删除',
      message: '确定要删除这条笔记吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '删除', color: '#FF4D4F' }
      ]
    }).then(async (res) => {
      if (res.index === 1) {
        try {
          await this.noteRepository.delete(this.note!.id!);
          promptAction.showToast({ message: '删除成功' });
          router.back();
        } catch (e) {
          Logger.error('NoteDetailPage', 'Delete note failed', e);
          promptAction.showToast({ message: '删除失败' });
        }
      }
    });
  }

  editNote() {
    if (!this.note) {
      return;
    }
    router.pushUrl({
      url: 'pages/NoteEditPage',
      params: { note: this.note }
    });
  }

  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.EaseOut })
      .slide(SlideEffect.Right)
      .opacity(0)
    PageTransitionExit({ duration: 300, curve: Curve.EaseIn })
      .slide(SlideEffect.Right)
      .opacity(0)
  }

  @Builder
  Sidebar() {
    Column() {
      // 用户信息
      Row() {
        Image($r('app.media.girl22')) // 使用素材图作为头像
          .width(50)
          .height(50)
          .borderRadius(25)
          .objectFit(ImageFit.Cover)
          .border({ width: 2, color: Color.White })
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)' })

        Column() {
          Text('旅行达人')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text(new Date(this.note?.createTime || 0).toLocaleDateString())
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
        }
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ bottom: 24 })

      // 地点信息
      Row() {
        Image($r('app.media.ic_cat_sights'))
          .width(18)
          .height(18)
          .fillColor($r('app.color.accent'))
        Text(this.note?.location || '未知地点')
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 8 })
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('app.color.accent_soft'))
      .borderRadius(8)
      .margin({ bottom: 24 })

      // 分享按钮
      Button() {
        Row() {
          Image($r('app.media.ic_share'))
            .width(18)
            .height(18)
            .fillColor(Color.White)
            .margin({ right: 8 })
          Text('分享笔记')
            .fontColor(Color.White)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .height(44)
      .backgroundColor($r('app.color.danger'))
      .shadow({ radius: 8, color: 'rgba(255, 107, 107, 0.4)', offsetY: 4 })
      .onClick(() => {
        promptAction.showToast({ message: '分享功能开发中' });
      })
    }
    .padding(20)
    .backgroundColor('rgba(255, 255, 255, 0.8)')
    .backdropBlur(20)
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)' })
  }

  build() {
    Stack() {
      // 背景层
      Image($r('app.media.background11'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(0.15) // 淡化背景

      Column() {
        // 顶部导航栏
        Row() {
          Image($r('app.media.ic_arrow_back'))
            .width(24)
            .height(24)
            .fillColor($r('app.color.text_primary'))
            .onClick(() => {
              router.back();
            })

          Blank()

          Text('...') // More options
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .onClick(() => {
              promptAction.showDialog({
                title: '操作',
                buttons: [
                  { text: '编辑', color: '#007DFF' },
                  { text: '删除', color: '#FF0000' }
                ]
              }).then((res) => {
                if (res.index === 0) {
                  this.editNote();
                } else if (res.index === 1) {
                  this.deleteNote();
                }
              });
            })
        }
        .width('100%')
        .padding(16)
        // .backgroundColor(Color.White) // 透明导航栏

        if (this.note) {
          Scroll() {
            GridRow({ columns: 12, gutter: 20 }) {
              // 左侧/主要内容区
              GridCol({ span: { sm: 12, md: 8, lg: 8 } }) {
                Column() {
                  // 顶部装饰 - 日期徽章
                  Row() {
                    Column() {
                      Text(new Date(this.note?.createTime || 0).getDate().toString())
                        .fontSize(24)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.accent'))
                      Text(new Date(this.note?.createTime || 0).toLocaleString('default', { month: 'short' }))
                        .fontSize(12)
                        .fontColor($r('app.color.text_secondary'))
                    }
                    .alignItems(HorizontalAlign.Center)
                    .padding(8)
                    .backgroundColor($r('app.color.accent_soft'))
                    .borderRadius(8)
                    .margin({ right: 16 })

                    // 标题区域
                    Text(this.note.title)
                      .fontSize(24)
                      .fontFamily('serif')
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.text_primary'))
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .margin({ bottom: 20 })
                  .alignItems(VerticalAlign.Center)

                  Divider()
                    .color('rgba(0,0,0,0.05)')
                    .strokeWidth(2)
                    .margin({ bottom: 20 })

                  // 图片画廊
                  if (this.noteImages.length > 0) {
                    Swiper() {
                      ForEach(this.noteImages, (img: string, index: number) => {
                        Image(img)
                          .width('100%')
                          .height(350) // 稍微增加高度
                          .objectFit(ImageFit.Cover)
                          .borderRadius(12)
                          .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)', offsetY: 4 })
                          .sharedTransition(index === 0 ? `shared_image_${this.note?.id}` : 'ignore_shared_transition', {
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

                  // 正文内容
                  Text(this.note.content)
                    .fontSize(16)
                    .lineHeight(32) // 增加行高提升阅读体验
                    .fontColor($r('app.color.text_primary'))
                    .width('100%')
                    .textAlign(TextAlign.JUSTIFY)
                    .letterSpacing(1) // 增加字间距

                  // 底部装饰
                  Row() {
                    Image($r('app.media.ic_cat_tour'))
                      .width(24)
                      .height(24)
                      .fillColor('#E0E0E0')
                    Blank()
                    Text('— End —')
                      .fontSize(12)
                      .fontColor('#CCCCCC')
                    Blank()
                    Image($r('app.media.ic_cat_tour'))
                      .width(24)
                      .height(24)
                      .fillColor('#E0E0E0')
                  }
                  .width('100%')
                  .margin({ top: 40 })
                }
                .padding(32) // 增加内边距
                .backgroundColor('rgba(255, 255, 255, 0.95)') // 提高不透明度
                .borderRadius(24) // 增加圆角
                .shadow({ radius: 20, color: 'rgba(0,0,0,0.05)', offsetY: 8 })
            }

            // 右侧/侧边栏
            GridCol({ span: { sm: 12, md: 4, lg: 4 } }) {
              this.Sidebar()
            }
          }
          .padding({ left: 16, right: 16, bottom: 40 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      } else {
        // Loading or Error state
        Column() {
          LoadingProgress().width(32).height(32)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
  }
  .width('100%')
  .height('100%')
  .backgroundColor($r('app.color.app_bg'))
}
}
