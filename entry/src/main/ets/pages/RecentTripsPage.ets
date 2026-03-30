import router from '@ohos.router';
import { RdbManager } from '../common/database/RdbManager';
import { Trip, TripPlace } from '../model/TripModel';
import { promptAction, AlertDialog } from '@kit.ArkUI';
import { CreateTripDialog } from '../view/CreateTripDialog';

interface TripViewModel extends Trip {
  places: TripPlace[];
  startPoint: string;
  endPoint: string;
}

@Entry
@Component
struct RecentTripsPage {
  @State trips: TripViewModel[] = [];
  @State isRefreshing: boolean = false;
  @State isLoading: boolean = true;
  @State hasMore: boolean = true;
  private pageSize: number = 10;
  private currentPage: number = 0;

  @State filterStatus: string = 'all'; // all, ongoing, completed
  @State searchText: string = '';
  
  // Expanded Trip ID for Accordion
  @State expandedTripId: number | null = null;

  @State editingTrip: Trip | null = null;
  
  editDialogController: CustomDialogController = new CustomDialogController({
    builder: CreateTripDialog({
      tripName: this.editingTrip?.name || '',
      selectedLocation: this.editingTrip?.location || '',
      confirm: (name: string, location: string) => this.saveEdit(name, location)
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: false,
    autoCancel: true
  });

  createDialogController: CustomDialogController = new CustomDialogController({
    builder: CreateTripDialog({
      tripName: '',
      selectedLocation: '',
      confirm: (name: string, location: string) => this.createTrip(name, location)
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: false,
    autoCancel: true
  });

  async createTrip(name: string, location: string): Promise<void> {
    try {
      const trip: Trip = {
        id: null,
        name: name,
        location: location,
        startDate: Date.now(),
        status: 'planning',
        createTime: Date.now(),
        updateTime: Date.now()
      };
      const newTripId = await RdbManager.getInstance().insertTrip(trip);
      promptAction.showToast({ message: '行程创建成功' });
      this.refreshData();
      
      // Navigate to NewTripPage for creation flow
      // Assign the new ID to the trip object before passing it
      trip.id = newTripId;
      router.pushUrl({
        url: 'pages/NewTripPage',
        params: { trip: trip }
      });
    } catch (e) {
      console.error('Create trip failed', e);
      promptAction.showToast({ message: '创建失败' });
    }
  }

  aboutToAppear() {
    this.refreshData();
  }

  onPageShow() {
    // Only refresh if we have no data, to avoid flickering or resetting state on every show
    if (this.trips.length === 0) {
      this.refreshData();
    }
  }

  async refreshData() {
    this.isRefreshing = true;
    this.currentPage = 0;
    this.hasMore = true;
    
    try {
      const trips = await RdbManager.getInstance().getTrips(this.pageSize, 0, this.searchText, this.filterStatus);
      if (trips.length < this.pageSize) {
        this.hasMore = false;
      }
      this.trips = await this.enrichTrips(trips);
    } catch (e) {
      console.error('Refresh trips failed', e);
      promptAction.showToast({ message: '刷新失败' });
    } finally {
      this.isRefreshing = false;
      this.isLoading = false;
    }
  }

  async loadMore() {
    if (!this.hasMore || this.isLoading) return;
    this.isLoading = true;
    try {
      this.currentPage++;
      const offset = this.currentPage * this.pageSize;
      const newTrips = await RdbManager.getInstance().getTrips(this.pageSize, offset, this.searchText, this.filterStatus);
      if (newTrips.length < this.pageSize) {
        this.hasMore = false;
      }
      const enriched = await this.enrichTrips(newTrips);
      this.trips = this.trips.concat(enriched);
    } catch (e) {
      console.error('Load more trips failed', e);
      this.currentPage--;
    } finally {
      this.isLoading = false;
    }
  }

  async enrichTrips(trips: Trip[]): Promise<TripViewModel[]> {
    const viewModels: TripViewModel[] = [];
    for (const trip of trips) {
       let places: TripPlace[] = [];
       if (trip.id) {
         try {
           places = await RdbManager.getInstance().getTripPlaces(trip.id);
         } catch (e) {
           console.error(`Failed to load places for trip ${trip.id}`, e);
         }
       }
       viewModels.push({
         id: trip.id,
         name: trip.name,
         location: trip.location,
         startDate: trip.startDate,
         endDate: trip.endDate,
         coverImage: trip.coverImage,
         status: trip.status,
         createTime: trip.createTime,
         updateTime: trip.updateTime,
         places: places,
         startPoint: places.length > 0 ? places[0].title : '未设定起点',
         endPoint: places.length > 0 ? places[places.length - 1].title : '未设定终点'
       });
    }
    return viewModels;
  }

  async deleteTrip(id: number | null) {
    if (!id) return;
    try {
      promptAction.showDialog({
        title: '确认删除',
        message: '确定要删除这个行程吗？删除后无法恢复。',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '删除', color: '#FF4D4F' }
        ]
      }).then(async (res) => {
        if (res.index === 1) {
          await RdbManager.getInstance().deleteTrip(id);
          promptAction.showToast({ message: '删除成功' });
          this.refreshData();
        }
      });
    } catch (e) {
      console.error('Delete trip failed', e);
    }
  }

  async markAsCompleted(id: number | null) {
    if (!id) return;
    try {
      // Find the trip first to keep other fields
      const tripToUpdate = this.trips.find(t => t.id === id);
      if (!tripToUpdate) return;

      const updatedTrip: Trip = {
        id: tripToUpdate.id,
        name: tripToUpdate.name,
        location: tripToUpdate.location,
        startDate: tripToUpdate.startDate,
        endDate: tripToUpdate.endDate,
        coverImage: tripToUpdate.coverImage,
        status: 'completed',
        createTime: tripToUpdate.createTime,
        updateTime: Date.now()
      };
      
      await RdbManager.getInstance().updateTrip(updatedTrip);
      promptAction.showToast({ message: '已标记为完成' });
      this.refreshData();
    } catch (e) {
      console.error('Mark trip completed failed', e);
      promptAction.showToast({ message: '操作失败' });
    }
  }

  @Builder itemEnd(trip: TripViewModel) {
    Row() {
      if (trip.status === 'completed') {
        Button({ type: ButtonType.Normal }) {
          Text('删除')
            .fontColor(Color.White)
            .fontSize(16)
        }
        .width(80)
        .height('100%')
        .backgroundColor('#FF4D4F')
        .onClick(() => {
          this.confirmDelete(trip);
        })
      } else {
        Button({ type: ButtonType.Normal }) {
          Text('完成')
            .fontColor(Color.White)
            .fontSize(16)
        }
        .width(80)
        .height('100%')
        .backgroundColor('#4CAF50')
        .onClick(() => {
          this.markAsCompleted(trip.id);
        })
      }
    }
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'ongoing': return '#4CAF50'; // Green
      case 'completed': return '#9E9E9E'; // Gray
      default: return '#FF9800'; // planning
    }
  }

  getStatusText(status: string): string {
    switch (status) {
      case 'ongoing': return '进行中';
      case 'completed': return '已完成';
      default: return '计划中';
    }
  }

  @Builder FilterTab(text: string, status: string) {
    Text(text)
      .fontSize(14)
      .fontColor(this.filterStatus === status ? Color.White : '#666')
      .padding({ left: 16, right: 16, top: 6, bottom: 6 })
      .backgroundColor(this.filterStatus === status ? $r('app.color.accent') : '#F5F5F5')
      .borderRadius(16)
      .margin({ right: 12 })
      .onClick(() => {
        this.filterStatus = status;
        this.refreshData(); 
      })
  }

  confirmDelete(trip: Trip) {
    promptAction.showDialog({
      title: '删除行程',
      message: '确定要删除这个行程吗？删除后无法恢复。',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '删除', color: '#FF4D4F' }
      ]
    }).then((res) => {
      if (res.index === 1 && trip.id) {
        this.deleteTrip(trip.id);
      }
    });
  }

  async saveEdit(name: string, location: string): Promise<void> {
    if (this.editingTrip && this.editingTrip.id) {
      const updatedTrip: Trip = {
        id: this.editingTrip.id,
        name: name,
        location: location,
        startDate: this.editingTrip.startDate,
        endDate: this.editingTrip.endDate,
        coverImage: this.editingTrip.coverImage,
        status: this.editingTrip.status,
        createTime: this.editingTrip.createTime,
        updateTime: Date.now()
      };
      await RdbManager.getInstance().updateTrip(updatedTrip);
      this.refreshData();
      promptAction.showToast({ message: '修改成功' });
    }
  }

  openEditDialog(trip: TripViewModel) {
    this.editingTrip = trip;
    this.editDialogController = new CustomDialogController({
      builder: CreateTripDialog({
        tripName: trip.name,
        selectedLocation: trip.location || '',
        confirm: (name: string, location: string) => this.saveEdit(name, location)
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: false,
      autoCancel: true
    });
    this.editDialogController.open();
  }

  @Builder TripCard(trip: TripViewModel) {
    Column() {
       Row() {
        // Date
        Column() {
          Text(new Date(trip.createTime || 0).getDate().toString())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.accent'))
          Text(new Date(trip.createTime || 0).toLocaleString('default', { month: 'short' }) + '月')
            .fontSize(12)
            .fontColor('#666')
        }
        .width(50)
        .height(50)
        .backgroundColor('rgba(0, 125, 255, 0.08)')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .margin({ right: 16 })

        // Info
        Column() {
          Text(trip.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 6 })
          
          Row() {
             Image($r('app.media.ic_cat_sights'))
               .width(14)
               .height(14)
               .fillColor('#666')
               .margin({ right: 4 })
             Text(trip.location || '未知地区')
               .fontSize(13)
               .fontColor('#666')
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // Actions
        Row() {
          Text(this.getStatusText(trip.status || 'planning'))
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor(this.getStatusColor(trip.status || 'planning'))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
            .margin({ right: 8 })

          Button('编辑')
            .fontSize(12)
            .height(28)
            .backgroundColor('#F0F0F0')
            .fontColor('#333')
            .onClick(() => this.openEditDialog(trip))
        }
       }
       .width('100%')
       .padding(16)
       .backgroundColor(Color.White)
       .onClick(() => {
          router.pushUrl({
              url: 'pages/NewTripPage',
              params: { trip: trip }
          });
       })
    }
    .width('100%')
    .borderRadius(16)
    .backgroundColor(Color.White)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
    .margin({ bottom: 16 })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
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
          Text('最近行程')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ left: 16 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        
        // Search & Filter Bar
        Column() {
           Search({ placeholder: '搜索行程...' })
             .width('100%')
             .height(40)
             .backgroundColor('#F5F5F5')
             .placeholderColor('#999')
             .onChange((value) => {
                this.searchText = value;
                this.refreshData(); 
              })
             .margin({ bottom: 12 })
             
           Row() {
             this.FilterTab('全部', 'all')
             this.FilterTab('进行中', 'ongoing')
             this.FilterTab('已完成', 'completed')
           }
           .width('100%')
        }
        .padding({ left: 16, right: 16, bottom: 8 })
        .backgroundColor(Color.White)

        if (this.isLoading && this.trips.length === 0) {
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
        } else if (this.trips.length === 0) {
          // Empty State
          Column() {
            Image($r('app.media.ic_placeholder'))
              .width(120)
              .height(120)
              .opacity(0.5)
              .margin({ bottom: 16 })
            Text('暂无行程，开启一段新的旅程吧~')
              .fontSize(14)
              .fontColor('#999')
          }
          .width('100%')
          .height('80%')
          .justifyContent(FlexAlign.Center)
        } else {
          Refresh({ refreshing: $$this.isRefreshing }) {
            List({ space: 16 }) {
              ForEach(this.trips, (trip: TripViewModel) => {
                ListItem() {
                   this.TripCard(trip)
                }
                .swipeAction({ end: this.itemEnd(trip) })
              })
              
              if (this.isLoading && this.trips.length > 0) {
                ListItem() {
                  Row() {
                    LoadingProgress().width(24).height(24).margin({ right: 8 })
                    Text('加载中...').fontSize(14).fontColor('#999')
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.Center)
                  .padding(16)
                }
              }
            }
            .layoutWeight(1)
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 80 })
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
      .backgroundColor('#F5F5F5')

      // FAB to create new trip
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
        this.createDialogController.open();
      })
    }
    .width('100%')
    .height('100%')
  }
}