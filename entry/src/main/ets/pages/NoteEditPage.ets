import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { RdbManager } from '../common/database/RdbManager';
import { Note } from '../model/NoteModel';
import { Logger } from '../utils/Logger';

@Entry
@Component
struct NoteEditPage {
  @State noteId: number | null = null;
  @State title: string = '';
  @State location: string = '';
  @State content: string = '';
  @State createTime: number = 0;
  @State category: string = '经验';
  @State isShared: boolean = false;
  
  private categories: string[] = ['经验', '美食', '住宿', '交通', '景点'];

  aboutToAppear() {
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params && params['note']) {
        const note = params['note'] as Note;
        this.noteId = note.id;
        this.title = note.title;
        this.location = note.location;
        this.content = note.content;
        this.createTime = note.createTime || Date.now();
        this.category = note.category || '经验';
        this.isShared = note.isShared || false;
      }
    } catch (e) {
      Logger.error('NoteEditPage', 'Parse router params failed');
    } catch (e) {
      console.error('Parse router params failed', e);
    }
  }

  async saveNote() {
    if (!this.title.trim() && !this.content.trim()) {
       return; // Empty note, don't save
    }
    
    // If title is empty but content exists, use first few chars of content as title
    let saveTitle = this.title.trim();
    if (!saveTitle && this.content.trim()) {
      saveTitle = this.content.substring(0, 10) + (this.content.length > 10 ? '...' : '');
    }
    // If still empty (both empty), stop
    if (!saveTitle) return;

    const note: Note = {
      id: this.noteId,
      title: saveTitle,
      location: this.location,
      content: this.content,
      createTime: this.createTime || Date.now(),
      updateTime: Date.now(),
      category: this.category,
      isShared: this.isShared
    };

    try {
      if (this.noteId) {
        await RdbManager.getInstance().updateNote(note);
        promptAction.showToast({ message: '笔记已更新' });
      } else {
        await RdbManager.getInstance().insertNote(note);
        promptAction.showToast({ message: '笔记已保存' });
      }
    } catch (err) {
      Logger.error('NoteEditPage', 'Save note failed');
    } catch (err) {
      console.error('Save note failed', err);
    }
  }

  onBackPress() {
    this.saveNote();
  }

  build() {
    Stack() {
      // 背景图 - 使用第一张素材图并模糊处理
      Image($r('app.media.journal_2'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .blur(30) // 增加模糊度以突显内容
        
      // 遮罩层，提升文字可读性
      Rect()
        .width('100%')
        .height('100%')
        .fill('rgba(255, 255, 255, 0.4)')

      Column() {
        // 顶部导航栏
        Row() {
          Image($r('app.media.ic_arrow_back'))
            .width(24)
            .height(24)
            .fillColor($r('app.color.text_primary'))
            .onClick(() => {
              this.saveNote();
              router.back();
            })
          Text(this.noteId ? '编辑笔记' : '新建笔记')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ left: 16 })
            
          Blank()
          
          Button('保存')
            .fontSize(14)
            .fontColor(Color.White)
            .height(32)
            .backgroundColor($r('app.color.accent'))
            .borderRadius(16)
            .onClick(async () => {
               await this.saveNote();
               router.back();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('rgba(255, 255, 255, 0.6)') // 半透明导航栏
        .backdropBlur(10)

        Scroll() {
          Column({ space: 20 }) {
            // 标题输入区域
            Column() {
              TextInput({ placeholder: '给笔记起个标题...', text: this.title })
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .placeholderColor('rgba(0,0,0,0.4)')
                .backgroundColor(Color.Transparent)
                .padding(0)
                .maxLength(50)
                .onChange((value) => {
                  this.title = value;
                })
              
              Divider()
                .color('rgba(0,0,0,0.1)')
                .margin({ top: 8, bottom: 8 })
                
              // 地点输入
              Row() {
                Image($r('app.media.ic_cat_sights'))
                  .width(16)
                  .height(16)
                  .fillColor($r('app.color.accent'))
                  .margin({ right: 8 })
                
                TextInput({ placeholder: '添加地点', text: this.location })
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .placeholderColor('rgba(0,0,0,0.4)')
                  .backgroundColor(Color.Transparent)
                  .layoutWeight(1)
                  .padding(0)
                  .onChange((value) => {
                    this.location = value;
                  })
              }

              Divider()
                .color('rgba(0,0,0,0.1)')
                .margin({ top: 8, bottom: 8 })

              // 分类选择
              Row() {
                Text('分类')
                  .fontSize(14)
                  .fontColor('#666')
                  .margin({ right: 12 })
                
                List({ space: 8 }) {
                  ForEach(this.categories, (item: string) => {
                    ListItem() {
                      Text(item)
                        .fontSize(12)
                        .fontColor(this.category === item ? Color.White : '#666')
                        .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                        .backgroundColor(this.category === item ? $r('app.color.accent') : '#F0F0F0')
                        .borderRadius(12)
                        .onClick(() => {
                          this.category = item;
                        })
                    }
                  })
                }
                .listDirection(Axis.Horizontal)
                .layoutWeight(1)
                .height(30)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .margin({ top: 4, bottom: 4 })

              Divider()
                .color('rgba(0,0,0,0.1)')
                .margin({ top: 8, bottom: 8 })

              // 分享开关
              Row() {
                Column() {
                  Text('分享到旅游建议')
                    .fontSize(14)
                    .fontColor('#333')
                  Text('分享后将根据标签归类显示在建议列表中')
                    .fontSize(10)
                    .fontColor('#999')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                
                Blank()
                
                Toggle({ type: ToggleType.Switch, isOn: this.isShared })
                  .selectedColor($r('app.color.accent'))
                  .onChange((isOn: boolean) => {
                    this.isShared = isOn;
                  })
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
            }
            .padding(20)
            .backgroundColor('rgba(255, 255, 255, 0.8)')
            .borderRadius(16)
            .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)' })

            // 内容输入区域
            Column() {
              TextArea({ placeholder: '记录此时此刻的想法...', text: this.content })
                .height(400)
                .fontSize(16)
                .lineHeight(24)
                .backgroundColor(Color.Transparent)
                .padding(0)
                .align(Alignment.TopStart)
                .onChange((value) => {
                  this.content = value;
                })
            }
            .padding(20)
            .backgroundColor('rgba(255, 255, 255, 0.8)')
            .borderRadius(16)
            .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)' })
            
            // 提示信息
            Row() {
              Image($r('app.media.ic_cat_flight')) // 装饰图标
                .width(20)
                .height(20)
                .fillColor($r('app.color.text_tertiary'))
                .margin({ right: 8 })
              Text('生活不止眼前的苟且，还有诗和远方')
                .fontSize(12)
                .fontColor($r('app.color.text_tertiary'))
                .fontStyle(FontStyle.Italic)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 20, bottom: 40 })
          }
          .padding(16)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }
}
