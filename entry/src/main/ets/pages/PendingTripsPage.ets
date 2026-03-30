import router from '@ohos.router';
import { RdbManager } from '../common/database/RdbManager';
import { Trip, TripPlace } from '../model/TripModel';
import { promptAction } from '@kit.ArkUI';
import { CreateTripDialog } from '../view/CreateTripDialog';
import { RouterManager } from '../common/utils/RouterManager';

interface TripViewModel extends Trip {
  places: TripPlace[];
  startPoint: string;
  endPoint: string;
}

interface RouteParams extends Record<string, Object> {
  trip: Trip;
}

@Entry
@Component
struct PendingTripsPage {
  @State trips: TripViewModel[] = [];
  @State isRefreshing: boolean = false;
  @State isLoading: boolean = true;
  @State hasMore: boolean = true;
  private pageSize: number = 10;
  private currentPage: number = 0;
  @State searchText: string = '';
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
      // MOCK DATA - Database operations removed for navigation testing
      // const trips = await RdbManager.getInstance().getTrips(100, 0, this.searchText, 'all');
      // const filtered = trips.filter(t => t.status === 'planning' || t.status === 'ongoing');
      // this.trips = await this.enrichTrips(filtered);

      this.trips = [
        {
          id: 1,
          name: '示例行程 (测试数据)',
          location: '巴黎',
          startDate: Date.now(),
          endDate: Date.now() + 86400000 * 3,
          status: 'planning',
          createTime: Date.now(),
          updateTime: Date.now(),
          coverImage: '',
          places: [],
          startPoint: '未设定',
          endPoint: '未设定'
        }
      ];
    } catch (e) {
      console.error('Refresh trips failed', e);
      promptAction.showToast({ message: '刷新失败' });
    } finally {
      this.isRefreshing = false;
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

  async markAsCompleted(id: number | null) {
    if (!id) {
      return;
    }
    try {
      const tripToUpdate = this.trips.find(t => t.id === id);
      if (!tripToUpdate) {
        return;
      }

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

  @Builder
  itemEnd(trip: TripViewModel) {
    Row() {
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

  @Builder
  TripCard(trip: TripViewModel) {
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
          Text(trip.status === 'ongoing' ? '进行中' : '计划中')
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor(trip.status === 'ongoing' ? '#4CAF50' : '#FF9800')
            .padding({
              left: 8,
              right: 8,
              top: 4,
              bottom: 4
            })
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
        const params: RouteParams = { trip: trip };
        RouterManager.getInstance().push('pages/NewTripPage', params);
      })
    }
    .width('100%')
    .borderRadius(16)
    .backgroundColor(Color.White)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
    .margin({ bottom: 16 })
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
        Text('待完成的行程')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
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
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.trips.length === 0) {
        // Empty State
        Column() {
          Image($r('app.media.ic_placeholder'))
            .width(120)
            .height(120)
            .opacity(0.5)
            .margin({ bottom: 16 })
          Text('没有待完成的行程')
            .fontSize(14)
            .fontColor('#999')
        }
        .width('100%')
        .layoutWeight(1)
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
          }
          .layoutWeight(1)
          .width('100%')
          .padding({
            left: 16,
            right: 16,
            top: 16,
            bottom: 80
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
  }
}
