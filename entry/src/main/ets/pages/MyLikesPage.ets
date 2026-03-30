import router from '@ohos.router';
import { RdbManager, DbPlace } from '../common/database/RdbManager';
import { RouterManager } from '../common/utils/RouterManager';
import { Note } from '../model/NoteModel';

@Entry
@Component
struct MyLikesPage {
  @State currentIndex: number = 0;
  @State notes: Note[] = [];
  @State places: DbPlace[] = [];
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.refreshData();
  }

  async refreshData() {
    this.isLoading = true;
    try {
      // MOCK DATA - Database operations removed for navigation testing
      // this.notes = await RdbManager.getInstance().getLikedNotes();
      // this.places = await RdbManager.getInstance().getLikedPlaces();
      this.notes = [];
      this.places = [];
    } catch (e) {
      console.error('Fetch likes failed', e);
    } finally {
      this.isLoading = false;
    }
  }

  @Builder TabBarItem(index: number, name: string) {
    Column() {
      Text(name)
        .fontSize(16)
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentIndex === index ? $r('app.color.accent') : '#666')
        .margin({ bottom: 8 })
      
      if (this.currentIndex === index) {
        Divider()
          .strokeWidth(2)
          .color($r('app.color.accent'))
          .width(20)
      } else {
        Divider()
          .strokeWidth(2)
          .color(Color.Transparent)
          .width(20)
      }
    }
    .width('50%')
    .height(40)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = index;
    })
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
            router.back();
          })
        Text('我的点赞')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)

      // Tabs
      Row() {
        this.TabBarItem(0, '笔记')
        this.TabBarItem(1, '景点')
      }
      .width('100%')
      .backgroundColor(Color.White)
      .margin({ bottom: 8 })

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        if (this.currentIndex === 0) {
          // Notes List
          if (this.notes.length === 0) {
            this.EmptyState('还没有点赞任何笔记')
          } else {
            List({ space: 12 }) {
              ForEach(this.notes, (note: Note) => {
                ListItem() {
                  this.NoteCard(note)
                }
              })
            }
            .layoutWeight(1)
            .padding(16)
          }
        } else {
          // Places List
          if (this.places.length === 0) {
            this.EmptyState('还没有点赞任何景点')
          } else {
            List({ space: 12 }) {
              ForEach(this.places, (place: DbPlace) => {
                ListItem() {
                  this.PlaceCard(place)
                }
              })
            }
            .layoutWeight(1)
            .padding(16)
          }
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder EmptyState(msg: string) {
    Column() {
      Image($r('app.media.ic_placeholder'))
        .width(100)
        .height(100)
        .opacity(0.5)
        .margin({ bottom: 16 })
      Text(msg)
        .fontSize(14)
        .fontColor('#999')
    }
    .width('100%')
    .height('80%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder NoteCard(note: Note) {
    Row() {
      // Cover (placeholder if no image)
      Image($r('app.media.journal_2')) // Use default or parse note.images
        .width(80)
        .height(80)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .margin({ right: 12 })

      Column() {
        Text(note.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 4 })
        
        Text(note.content)
          .fontSize(12)
          .fontColor('#666')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          
        Row() {
           Text(note.category || '经验')
             .fontSize(10)
             .fontColor($r('app.color.accent'))
             .backgroundColor('rgba(0,125,255,0.1)')
             .padding({ left: 4, right: 4, top: 2, bottom: 2 })
             .borderRadius(4)
             .margin({ right: 8 })
             
           Text(new Date(note.createTime || 0).toLocaleDateString())
             .fontSize(10)
             .fontColor('#999')
        }
      }
      .layoutWeight(1)
      .height(80)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/NoteDetailPage',
        params: { note: note }
      });
    })
  }

  @Builder PlaceCard(place: DbPlace) {
    Row() {
       Image($r('app.media.background11')) // Default place image
        .width(80)
        .height(80)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .margin({ right: 12 })
        
       Column() {
          Text(place.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .margin({ bottom: 4 })
            
          Row() {
            Image($r('app.media.ic_cat_sights'))
              .width(12)
              .height(12)
              .fillColor('#999')
              .margin({ right: 4 })
            Text(`${place.distanceKm?.toFixed(1) || 0} km`)
              .fontSize(12)
              .fontColor('#999')
          }
          .margin({ bottom: 4 })
          
          Text(place.note || '暂无描述')
            .fontSize(12)
            .fontColor('#666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
       }
       .layoutWeight(1)
       .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .onClick(() => {
      // Navigate to PlaceDetail
      const params: Record<string, Object> = {
        'id': place.id,
        'title': place.title,
        'type': place.type,
        'distanceKm': place.distanceKm ?? 0,
        'durationMin': place.durationMin ?? 0,
        'note': place.note ?? '',
        'latitude': place.latitude ?? 0,
        'longitude': place.longitude ?? 0
      };
      RouterManager.getInstance().push('pages/PlaceDetailPage', params);
    })
  }
}
