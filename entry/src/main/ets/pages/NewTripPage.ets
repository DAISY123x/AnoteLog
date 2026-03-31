/**
 * @file NewTripPage.ets
 * @brief 新建/编辑行程页
 * @description 创建行程或编辑已有行程，管理行程天数和地点
 * @see TripRepository, TripTopBar, DayTabBar, PlaceItem, MapContainer
 */
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { TripViewModel, TripGroup } from '../viewmodel/TripViewModel';
import { MapContainer } from '../view/MapContainer';
import { TripPlace } from '../model/TripModel';
import { SearchResult } from './SearchPage';
import { PlaceResult } from '../service/MapService';
import { TripRepository } from '../repository/TripRepository';
import { Trip, TripPlace as DbTripPlace, TripWithPlaces } from '../model/TripModel';
import { Logger } from '../utils/Logger';
import { TripTopBar } from '../view/trip/TripTopBar';
import { DayTabBar } from '../view/trip/DayTabBar';
import { PlaceItem, SwipeDelete, PlaceItemDragPreview } from '../view/trip/PlaceItem';

@Entry
@Component
struct NewTripPage {
  @State viewModel: TripViewModel = new TripViewModel();
  @State activeGroupIndex: number = 0;
  @State isListExpanded: boolean = true;
  @StorageLink('selectedSearchResult') selectedSearchResult: SearchResult | null = null;
  private tripId: number | null = null;
  private readonly TAG = 'NewTripPage';
  private tripRepository: TripRepository = new TripRepository();

  aboutToAppear() {
    Logger.info(this.TAG, 'aboutToAppear: Entering NewTripPage');
    this.requestPermissions();
    this.loadExistingTrip();
  }

  onPageShow() {
    Logger.info(this.TAG, 'onPageShow: Page visible');
    if (this.selectedSearchResult) {
      Logger.info(this.TAG, 'onPageShow: Found selected search result', [this.selectedSearchResult.title]);
      this.addPlaceFromSearch(this.selectedSearchResult);
      AppStorage.setOrCreate('selectedSearchResult', null);
    }
  }

  requestPermissions() {
    Logger.info(this.TAG, 'requestPermissions: Requesting location permissions');
    let atManager = abilityAccessCtrl.createAtManager();
    let context = getContext(this) as common.UIAbilityContext;
    let permissions: Permissions[] = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'];

    atManager.requestPermissionsFromUser(context, permissions).then((data) => {
      let grantStatus: Array<number> = data.authResults;
      let length: number = grantStatus.length;
      let allGranted = true;
      for (let i = 0; i < length; i++) {
        if (grantStatus[i] !== 0) {
          allGranted = false;
          Logger.warn(this.TAG, 'requestPermissions: Permission denied', [permissions[i]]);
          promptAction.showToast({ message: '请授予定位权限以使用地图功能' });
          break;
        }
      }
      if (allGranted) {
        Logger.info(this.TAG, 'requestPermissions: All permissions granted');
      }
    }).catch((err: BusinessError) => {
      Logger.error(this.TAG, 'requestPermissions: Error requesting permissions', [err]);
    });
  }

  loadExistingTrip() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['trip']) {
      const trip = params['trip'] as TripWithPlaces;
      if (trip) {
        Logger.info(this.TAG, 'loadExistingTrip: Loading trip', [trip.name]);
        this.tripId = trip.id;
        this.viewModel.loadTrip(trip.name, trip.places || []);
        this.activeGroupIndex = 0;
      }
    }
  }

  addPlaceFromSearch(result: SearchResult) {
    Logger.info(this.TAG, 'addPlaceFromSearch: Adding place', [result.title]);
    const placeResult: PlaceResult = {
      id: result.id.toString(),
      name: result.title,
      address: result.address || '',
      location: { latitude: result.latitude || 0, longitude: result.longitude || 0 },
      type: result.type,
      icon: result.icon
    };
    this.viewModel.addPlace(placeResult, this.activeGroupIndex);
    this.viewModel.groups = [...this.viewModel.groups];
    promptAction.showToast({ message: `已添加: ${result.title}` });
    Logger.info(this.TAG, 'addPlaceFromSearch: Place added and UI updated');
  }

  /**
   * 保存行程到数据库（包含地点列表）
   */
  async saveTrip() {
    Logger.info(this.TAG, 'saveTrip: Starting save process');
    if (this.viewModel.groups.length === 0 || this.viewModel.getAllPlaces().length === 0) {
      Logger.warn(this.TAG, 'saveTrip: No places to save');
      promptAction.showToast({ message: '请至少添加一个地点' });
      return;
    }

    const tripName = this.viewModel.tripName || '我的行程';
    const trip: Trip = {
      id: this.tripId,
      name: tripName,
      startDate: Date.now(),
      endDate: Date.now() + 86400000 * this.viewModel.groups.length,
      status: 'planning',
      createTime: Date.now(),
      updateTime: Date.now()
    };

    try {
      let id = this.tripId;
      if (id) {
        Logger.info(this.TAG, 'saveTrip: Updating existing trip', [id]);
        await this.tripRepository.update(trip);
        await this.tripRepository.clearPlaces(id);
      } else {
        Logger.info(this.TAG, 'saveTrip: Creating new trip');
        id = await this.tripRepository.insert(trip);
      }

      if (!id) {
        throw new Error('Failed to get trip ID');
      }

      Logger.info(this.TAG, 'saveTrip: Saving places for trip ID', [id]);

      let orderIndex = 0;
      for (const group of this.viewModel.groups) {
        for (const place of group.places) {
          const dbPlace: DbTripPlace = {
            id: null,
            tripId: id,
            title: place.title,
            type: place.type,
            distanceKm: place.distanceKm,
            durationMin: place.durationMin,
            note: place.note,
            latitude: place.latitude,
            longitude: place.longitude,
            orderIndex: orderIndex++,
            dayIndex: group.id - 1,
            address: place.address,
            icon: place.icon
          };
          await this.tripRepository.insertPlace(dbPlace);
        }
      }

      Logger.info(this.TAG, 'saveTrip: All places saved successfully');
      promptAction.showToast({ message: '行程保存成功' });
      router.back();

    } catch (e) {
      Logger.error(this.TAG, 'saveTrip: Failed to save trip', [e]);
      promptAction.showToast({ message: '保存失败' });
    }
  }

  /**
   * 添加新的一天
   */
  addNewDay(): void {
    this.viewModel.addGroup();
    this.viewModel.groups = [...this.viewModel.groups];
    this.activeGroupIndex = this.viewModel.groups.length - 1;
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 地图层
      Column() {
        if (this.viewModel.groups.length > 0 && this.activeGroupIndex < this.viewModel.groups.length) {
          MapContainer({
            places: this.viewModel.groups[this.activeGroupIndex].places,
            routePoints: this.viewModel.groups[this.activeGroupIndex].routePoints
          })
        }
      }
      .height('100%').width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // 顶部栏
      TripTopBar({
        tripName: this.viewModel.tripName,
        onSave: () => this.saveTrip()
      })

      // 底部面板
      Column() {
        // 拖拽手柄
        Row() {
          Divider()
            .width(40).height(4).color('#E0E0E0').strokeWidth(4).lineCap(LineCapStyle.Round)
        }
        .width('100%').justifyContent(FlexAlign.Center)
        .padding({ top: 8, bottom: 8 })
        .onClick(() => {
          animateTo({ duration: 300 }, () => {
            this.isListExpanded = !this.isListExpanded;
          })
        })

        // 天数 Tab 栏
        DayTabBar({
          groups: this.viewModel.groups,
          activeGroupIndex: this.activeGroupIndex,
          onAddDay: () => this.addNewDay()
        })

        // 地点列表（可折叠）
        if (this.isListExpanded) {
          List() {
            ForEach(this.viewModel.groups[this.activeGroupIndex].places, (place: TripPlace, index: number) => {
              ListItem() {
                PlaceItem({ place: place, index: index })
              }
              .swipeAction({ end: () => {
                SwipeDelete({ onDelete: () => {
                  this.viewModel.removePlace(this.activeGroupIndex, index);
                  this.viewModel.groups = [...this.viewModel.groups];
                }})
              }})
              .onClick(() => {})
            })
          }
          .onItemDragStart((event: ItemDragInfo, itemIndex: number) => {
            return PlaceItemDragPreview({ place: this.viewModel.groups[this.activeGroupIndex].places[itemIndex] });
          })
          .onItemDrop((event: ItemDragInfo, itemIndex: number, insertIndex: number, isSuccess: boolean) => {
            if (isSuccess && insertIndex >= 0) {
              this.viewModel.swapPlaces(this.activeGroupIndex, itemIndex, insertIndex);
              this.viewModel.groups = [...this.viewModel.groups];
            }
          })
          .layoutWeight(1).width('100%')
          .padding({ bottom: 80 })
        }

        // 底部操作按钮
        Row() {
          Button('AI智能规划')
            .backgroundColor('#E3F2FD').fontColor('#007DFF')
            .layoutWeight(1).margin({ right: 12 })
            .onClick(async () => {
              promptAction.showToast({ message: '正在进行智能规划...' });
              const success = await this.viewModel.optimizeRoute(this.activeGroupIndex);
              if (success) {
                this.viewModel.groups = [...this.viewModel.groups];
                promptAction.showToast({ message: '路径已优化' });
              } else {
                promptAction.showToast({ message: '规划失败或地点不足' });
              }
            })

          Button('添加景点')
            .backgroundColor('#007DFF').fontColor(Color.White)
            .layoutWeight(1)
            .onClick(() => { router.pushUrl({ url: 'pages/SearchPage' }); })
        }
        .width('100%').padding(16).backgroundColor(Color.White)
        .position({ y: '100%' }).translate({ y: '-100%' })
      }
      .width('100%')
      .height(this.isListExpanded ? '50%' : '15%')
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .shadow({ radius: 16, color: '#1A000000', offsetY: -4 })
      .animation({ duration: 300, curve: Curve.EaseOut })
    }
    .height('100%').width('100%')
    .backgroundColor('#F1F3F5')
  }
}
