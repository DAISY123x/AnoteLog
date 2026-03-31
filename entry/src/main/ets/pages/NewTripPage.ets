/**
 * @file NewTripPage.ets
 * @brief 新建/编辑行程页
 * @description 创建行程或编辑已有行程，管理行程天数和地点
 * @see TripRepository
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
        // Force UI update
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
    // Force UI update for nested object changes
    this.viewModel.groups = [...this.viewModel.groups];

    promptAction.showToast({ message: `已添加: ${result.title}` });
    Logger.info(this.TAG, 'addPlaceFromSearch: Place added and UI updated');
  }

  async saveTrip() {
    Logger.info(this.TAG, 'saveTrip: Starting save process');
    if (this.viewModel.groups.length === 0 || this.viewModel.getAllPlaces().length === 0) {
      Logger.warn(this.TAG, 'saveTrip: No places to save');
      promptAction.showToast({ message: '请至少添加一个地点' });
      return;
    }

    const tripName = this.viewModel.tripName || '我的行程';
    Logger.info(this.TAG, 'saveTrip: Trip name', [tripName]);

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

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 1. Map Layer
      Column() {
        if (this.viewModel.groups.length > 0 && this.activeGroupIndex < this.viewModel.groups.length) {
           MapContainer({
             places: this.viewModel.groups[this.activeGroupIndex].places,
             routePoints: this.viewModel.groups[this.activeGroupIndex].routePoints
           })
        }
      }
      .height('100%')
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // 2. Top Bar
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.ic_arrow_back'))
            .width(24)
            .height(24)
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.White)
        .onClick(() => router.back())
        .shadow({ radius: 4, color: '#20000000', offsetY: 2 })

        TextInput({ text: this.viewModel.tripName, placeholder: '输入行程名称' })
          .onChange((value) => this.viewModel.tripName = value)
          .layoutWeight(1)
          .height(40)
          .margin({ left: 12, right: 12 })
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 4, color: '#20000000', offsetY: 2 })
          .padding({ left: 16, right: 16 })

        Button('保存')
          .height(40)
          .borderRadius(20)
          .backgroundColor('#007DFF')
          .onClick(() => this.saveTrip())
          .shadow({ radius: 4, color: '#20000000', offsetY: 2 })
      }
      .width('100%')
      .padding({ top: 12, left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .position({ x: 0, y: 40 }) // Adjust for status bar

      // 3. Bottom Panel
      Column() {
        // Handle bar
        Row() {
          Divider()
            .width(40)
            .height(4)
            .color('#E0E0E0')
            .strokeWidth(4)
            .lineCap(LineCapStyle.Round)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8, bottom: 8 })
        .onClick(() => {
          animateTo({ duration: 300 }, () => {
             this.isListExpanded = !this.isListExpanded;
          })
        })

        // Group Tabs
        List({ space: 10 }) {
          ForEach(this.viewModel.groups, (group: TripGroup, index: number) => {
            ListItem() {
              Text(group.name)
                .fontColor(this.activeGroupIndex === index ? Color.White : '#333333')
                .fontSize(14)
                .backgroundColor(this.activeGroupIndex === index ? '#007DFF' : '#F5F5F5')
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .borderRadius(16)
                .onClick(() => {
                   this.activeGroupIndex = index;
                })
            }
          })

          ListItem() {
            Row() {
               Text('+').fontSize(16).fontColor('#007DFF')
            }
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor('#F0F8FF')
            .borderRadius(16)
            .onClick(() => {
               this.viewModel.addGroup();
               this.viewModel.groups = [...this.viewModel.groups];
               this.activeGroupIndex = this.viewModel.groups.length - 1;
            })
          }
        }
        .listDirection(Axis.Horizontal)
        .height(50)
        .width('100%')
        .scrollBar(BarState.Off)
        .padding({ left: 16, right: 16 })

        if (this.isListExpanded) {
           // Place List
           List() {
             ForEach(this.viewModel.groups[this.activeGroupIndex].places, (place: TripPlace, index: number) => {
               ListItem() {
                 this.PlaceItem(place, index)
               }
               .swipeAction({ end: this.SwipeDelete(index) })
               // Add simple click listener to avoid issues with drag interference
               .onClick(() => {})
             })
           }
           .onItemDragStart((event: ItemDragInfo, itemIndex: number) => {
              return this.PlaceItemDragPreview(this.viewModel.groups[this.activeGroupIndex].places[itemIndex]);
           })
           .onItemDrop((event: ItemDragInfo, itemIndex: number, insertIndex: number, isSuccess: boolean) => {
              if (isSuccess && insertIndex >= 0) {
                this.viewModel.swapPlaces(this.activeGroupIndex, itemIndex, insertIndex);
                this.viewModel.groups = [...this.viewModel.groups];
              }
           })
           .layoutWeight(1)
           .width('100%')
           .padding({ bottom: 80 }) // Space for bottom buttons
        }

        // Bottom Actions
        Row() {
          Button('AI智能规划')
            .backgroundColor('#E3F2FD')
            .fontColor('#007DFF')
            .layoutWeight(1)
            .margin({ right: 12 })
            .onClick(async () => {
               promptAction.showToast({ message: '正在进行智能规划...' });
               const success = await this.viewModel.optimizeRoute(this.activeGroupIndex);
               if (success) {
                  // Force UI update
                  this.viewModel.groups = [...this.viewModel.groups];
                  promptAction.showToast({ message: '路径已优化' });
               } else {
                  promptAction.showToast({ message: '规划失败或地点不足' });
               }
            })

          Button('添加景点')
            .backgroundColor('#007DFF')
            .fontColor(Color.White)
            .layoutWeight(1)
            .onClick(() => {
              router.pushUrl({ url: 'pages/SearchPage' });
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .position({ y: '100%' })
        .translate({ y: '-100%' })
      }
      .width('100%')
      .height(this.isListExpanded ? '50%' : '15%')
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .shadow({ radius: 16, color: '#1A000000', offsetY: -4 })
      .animation({ duration: 300, curve: Curve.EaseOut })
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F1F3F5')
  }

  @Builder
  PlaceItem(place: TripPlace, index: number) {
    Row() {
      Text(`${index + 1}`)
        .fontSize(14)
        .fontColor('#999')
        .width(24)
        .textAlign(TextAlign.Center)

      Image(place.icon || $r('app.media.ic_cat_sights')) // Fallback icon
        .width(40)
        .height(40)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .margin({ left: 8, right: 12 })

      Column() {
        Text(place.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(place.type)
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.ic_cat_more')) // Using more icon as drag handle indicator
        .width(20)
        .height(20)
        .opacity(0.5)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
  }

  @Builder
  SwipeDelete(index: number) {
    Row() {
      Text('删除')
        .fontColor(Color.White)
        .fontSize(14)
    }
    .width(80)
    .height('100%')
    .backgroundColor('#FF3B30')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.viewModel.removePlace(this.activeGroupIndex, index);
      this.viewModel.groups = [...this.viewModel.groups];
    })
  }

  @Builder
  PlaceItemDragPreview(place: TripPlace) {
    Row() {
      Image(place.icon || $r('app.media.ic_cat_sights'))
        .width(40)
        .height(40)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .margin({ right: 12 })
      Text(place.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
    }
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .width(200)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)' })
  }
}
