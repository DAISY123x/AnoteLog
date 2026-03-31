/**
 * @file RecentTripsPage.ets
 * @brief 最近行程页
 * @description 展示行程列表，支持筛选、新建、编辑、删除和标记完成
 * @see TripRepository, TripCard, TripSwipeAction
 */
import router from '@ohos.router';
import { TripRepository } from '../repository/TripRepository';
import { Trip, TripPlace, TripViewModel } from '../model/TripModel';
import { promptAction } from '@kit.ArkUI';
import { Logger } from '../utils/Logger';
import { CreateTripDialog } from '../view/CreateTripDialog';
import { TripCard } from '../view/trip/TripCard';
import { TripSwipeAction } from '../view/trip/TripSwipeAction';

@Entry
@Component
struct RecentTripsPage {
  @State trips: TripViewModel[] = [];
  @State isRefreshing: boolean = false;
  @State isLoading: boolean = true;
  @State hasMore: boolean = true;
  private pageSize: number = 10;
  private currentPage: number = 0;
  private tripRepository: TripRepository = new TripRepository();
  @State filterStatus: string = 'all';
  @State searchText: string = '';
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

  /**
   * 新建行程并跳转到编辑页面
   */
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
      const newTripId = await this.tripRepository.insert(trip);
      promptAction.showToast({ message: '行程创建成功' });
      this.refreshData();
      trip.id = newTripId;
      router.pushUrl({ url: 'pages/NewTripPage', params: { trip: trip } });
    } catch (e) {
      Logger.error('RecentTripsPage', 'Create trip failed', e);
    }
  }

  aboutToAppear() {
    this.refreshData();
  }

  onPageShow() {
    if (this.trips.length === 0) {
      this.refreshData();
    }
  }

  /**
   * 刷新数据（重置分页并重新加载）
   */
  async refreshData() {
    this.isRefreshing = true;
    this.currentPage = 0;
    this.hasMore = true;
    try {
      const trips = await this.tripRepository.query({
        limit: this.pageSize,
        offset: 0,
        keyword: this.searchText,
        status: this.filterStatus
      });
      if (trips.length < this.pageSize) {
        this.hasMore = false;
      }
      this.trips = await this.enrichTrips(trips);
    } catch (e) {
      Logger.error('RecentTripsPage', 'Refresh trips failed', e);
    } finally {
      this.isRefreshing = false;
      this.isLoading = false;
    }
  }

  /**
   * 加载更多（分页追加）
   */
  async loadMore() {
    if (!this.hasMore || this.isLoading) return;
    this.isLoading = true;
    try {
      this.currentPage++;
      const offset = this.currentPage * this.pageSize;
      const newTrips = await this.tripRepository.query({
        limit: this.pageSize,
        offset: offset,
        keyword: this.searchText,
        status: this.filterStatus
      });
      if (newTrips.length < this.pageSize) {
        this.hasMore = false;
      }
      const enriched = await this.enrichTrips(newTrips);
      this.trips = this.trips.concat(enriched);
    } catch (e) {
      Logger.error('RecentTripsPage', 'Load more trips failed', e);
      this.currentPage--;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 补充行程地点信息，生成展示用视图模型
   */
  async enrichTrips(trips: Trip[]): Promise<TripViewModel[]> {
    const viewModels: TripViewModel[] = [];
    for (const trip of trips) {
      let places: TripPlace[] = [];
      if (trip.id) {
        try {
          places = await this.tripRepository.getTripPlaces(trip.id);
        } catch (e) {
          Logger.error('RecentTripsPage', `Failed to load places for trip ${trip.id}`, e);
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

  /**
   * 删除行程
   */
  async deleteTrip(id: number | null) {
    if (!id) return;
    try {
      await this.tripRepository.delete(id);
      promptAction.showToast({ message: '删除成功' });
      this.refreshData();
    } catch (e) {
      Logger.error('RecentTripsPage', 'Delete trip failed', e);
    }
  }

  /**
   * 标记行程为已完成
   */
  async markAsCompleted(id: number | null) {
    if (!id) return;
    try {
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
      await this.tripRepository.update(updatedTrip);
      promptAction.showToast({ message: '已标记为完成' });
      this.refreshData();
    } catch (e) {
      Logger.error('RecentTripsPage', 'Mark trip completed failed', e);
    }
  }

  /**
   * 确认删除（弹窗确认）
   */
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

  /**
   * 保存编辑结果
   */
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
      await this.tripRepository.update(updatedTrip);
      this.refreshData();
      promptAction.showToast({ message: '修改成功' });
    }
  }

  /**
   * 打开编辑弹窗
   */
  openEditDialog(trip: TripViewModel) {
    this.editingTrip = trip as Trip;
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

  /**
   * 筛选标签 Builder
   */
  @Builder
  FilterTab(text: string, status: string) {
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

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 顶部导航栏
        Row() {
          Image($r('app.media.ic_arrow_back'))
            .width(24).height(24).fillColor($r('app.color.icon_primary'))
            .onClick(() => { router.back(); })
          Text('最近行程')
            .fontSize(18).fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary')).margin({ left: 16 })
        }
        .width('100%').padding(16).backgroundColor(Color.White)

        // 搜索与筛选栏
        Column() {
          Search({ placeholder: '搜索行程...' })
            .width('100%').height(40).backgroundColor('#F5F5F5')
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

        // 内容区
        if (this.isLoading && this.trips.length === 0) {
          Column() {
            LoadingProgress().width(48).height(48).color($r('app.color.accent'))
          }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
        } else if (this.trips.length === 0) {
          Column() {
            Image($r('app.media.ic_placeholder'))
              .width(120).height(120).opacity(0.5).margin({ bottom: 16 })
            Text('暂无行程，开启一段新的旅程吧~')
              .fontSize(14).fontColor('#999')
          }
          .width('100%').height('80%').justifyContent(FlexAlign.Center)
        } else {
          Refresh({ refreshing: $$this.isRefreshing }) {
            List({ space: 16 }) {
              ForEach(this.trips, (trip: TripViewModel) => {
                ListItem() {
                  TripCard({
                    trip: trip,
                    onEdit: (t) => this.openEditDialog(t)
                  })
                }
                .swipeAction({
                  end: () => {
                    TripSwipeAction({
                      trip: trip,
                      onDelete: (id) => this.deleteTrip(id),
                      onComplete: (id) => this.markAsCompleted(id)
                    })
                  }
                })
              })

              if (this.isLoading && this.trips.length > 0) {
                ListItem() {
                  Row() {
                    LoadingProgress().width(24).height(24).margin({ right: 8 })
                    Text('加载中...').fontSize(14).fontColor('#999')
                  }
                  .width('100%').justifyContent(FlexAlign.Center).padding(16)
                }
              }
            }
            .layoutWeight(1)
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 80 })
            .onReachEnd(() => { this.loadMore(); })
          }
          .onRefreshing(() => { this.refreshData(); })
        }
      }
      .width('100%').height('100%').backgroundColor('#F5F5F5')

      // 新建行程悬浮按钮
      Button() {
        Text('+').fontSize(32).fontColor(Color.White).fontWeight(FontWeight.Lighter).margin({ bottom: 4 })
      }
      .width(56).height(56).borderRadius(28)
      .backgroundColor($r('app.color.accent'))
      .shadow({ radius: 8, color: 'rgba(0, 125, 255, 0.4)', offsetY: 4 })
      .margin({ right: 24, bottom: 32 })
      .onClick(() => { this.createDialogController.open(); })
    }
    .width('100%').height('100%')
  }
}
