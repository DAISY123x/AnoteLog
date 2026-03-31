/**
 * @file NoteDetailPage.ets
 * @brief 笔记详情页
 * @description 查看笔记详情，支持点赞、分享、编辑和删除操作
 * @see NoteRepository, LikeRepository, NoteSidebar, NoteGallery
 */
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NoteRepository } from '../repository/NoteRepository';
import { LikeRepository } from '../repository/LikeRepository';
import { Note } from '../model/NoteModel';
import { Logger } from '../utils/Logger';
import { NoteSidebar } from '../view/note/NoteSidebar';
import { NoteGallery } from '../view/note/NoteGallery';

@Entry
@Component
struct NoteDetailPage {
  @State note: Note | null = null;
  @State noteImages: string[] = [];
  @State isLiked: boolean = false;
  private noteRepository: NoteRepository = new NoteRepository();
  private likeRepository: LikeRepository = new LikeRepository();

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

  async checkLikeStatus() {
    if (this.note && this.note.id) {
      this.isLiked = await this.likeRepository.isLiked(this.note.id, 'note');
    }
  }

  async toggleLike() {
    if (this.note && this.note.id) {
      const liked = await this.likeRepository.toggleLike(this.note.id, 'note');
      this.isLiked = liked;
      promptAction.showToast({ message: liked ? '已点赞' : '已取消点赞' });
    }
  }

  async deleteNote() {
    if (!this.note || !this.note.id) return;
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
    if (!this.note) return;
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

  build() {
    Stack() {
      // 背景层
      Image($r('app.media.background11'))
        .width('100%').height('100%').objectFit(ImageFit.Cover).opacity(0.15)

      Column() {
        // 顶部导航栏
        Row() {
          Image($r('app.media.ic_arrow_back'))
            .width(24).height(24).fillColor($r('app.color.text_primary'))
            .onClick(() => { router.back(); })
          Blank()
          Text('...')
            .fontSize(24).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
            .onClick(() => {
              promptAction.showDialog({
                title: '操作',
                buttons: [
                  { text: '编辑', color: '#007DFF' },
                  { text: '删除', color: '#FF0000' }
                ]
              }).then((res) => {
                if (res.index === 0) this.editNote();
                else if (res.index === 1) this.deleteNote();
              });
            })
        }
        .width('100%').padding(16)

        if (this.note) {
          Scroll() {
            GridRow({ columns: 12, gutter: 20 }) {
              // 左侧/主要内容区
              GridCol({ span: { sm: 12, md: 8, lg: 8 } }) {
                Column() {
                  // 顶部装饰 - 日期徽章 + 标题
                  Row() {
                    Column() {
                      Text(new Date(this.note?.createTime || 0).getDate().toString())
                        .fontSize(24).fontWeight(FontWeight.Bold).fontColor($r('app.color.accent'))
                      Text(new Date(this.note?.createTime || 0).toLocaleString('default', { month: 'short' }))
                        .fontSize(12).fontColor($r('app.color.text_secondary'))
                    }
                    .alignItems(HorizontalAlign.Center).padding(8)
                    .backgroundColor($r('app.color.accent_soft')).borderRadius(8)
                    .margin({ right: 16 })

                    Text(this.note.title)
                      .fontSize(24).fontFamily('serif').fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.text_primary')).layoutWeight(1)
                  }
                  .width('100%').margin({ bottom: 20 }).alignItems(VerticalAlign.Center)

                  Divider().color('rgba(0,0,0,0.05)').strokeWidth(2).margin({ bottom: 20 })

                  // 图片画廊
                  NoteGallery({ images: this.noteImages, noteId: this.note.id })

                  // 正文内容
                  Text(this.note.content)
                    .fontSize(16).lineHeight(32).fontColor($r('app.color.text_primary'))
                    .width('100%').textAlign(TextAlign.JUSTIFY).letterSpacing(1)

                  // 底部装饰
                  Row() {
                    Image($r('app.media.ic_cat_tour')).width(24).height(24).fillColor('#E0E0E0')
                    Blank()
                    Text('— End —').fontSize(12).fontColor('#CCCCCC')
                    Blank()
                    Image($r('app.media.ic_cat_tour')).width(24).height(24).fillColor('#E0E0E0')
                  }
                  .width('100%').margin({ top: 40 })
                }
                .padding(32).backgroundColor('rgba(255, 255, 255, 0.95)')
                .borderRadius(24).shadow({ radius: 20, color: 'rgba(0,0,0,0.05)', offsetY: 8 })
              }

              // 右侧/侧边栏
              GridCol({ span: { sm: 12, md: 4, lg: 4 } }) {
                NoteSidebar({ note: this.note })
              }
            }
          }
          .padding({ left: 16, right: 16, bottom: 40 })
        } else {
          Column() {
            LoadingProgress().width(32).height(32)
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        }
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }
}
