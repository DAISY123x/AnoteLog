import { Trip, TripPlace } from '../model/TripModel';
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import router from '@ohos.router';
import { Logger } from '../utils/Logger';

@Component
export struct ItineraryEditComponent {
  @Link trip: Trip | null;
  @Link @Watch('onPlacesChange') places: TripPlace[];
  @State groupedPlaces: TripPlace[][] = [];
  @State currentDayIndex: number = 0;
  @State isMapError: boolean = false;
  @State sheetHeight: number = 350;
  @State isEditingTitle: boolean = false;
  @State titleDraft: string = '';
  
  // Map Controller
  private mapController: map.MapComponentController | null = null;
  private mapCallback?: AsyncCallback<map.MapComponentController>;
  // Callbacks
  onAddPlace?: (dayIndex: number) => void;
  onSave?: () => void;

  aboutToAppear() {
    this.groupPlaces();
    this.initMapCallback();
  }

  // Watch for changes in places to re-group
  onPlacesChange() {
    this.groupPlaces();
  }

  groupPlaces() {
    if (!this.places) {
      this.groupedPlaces = [];
      return;
    }

    // Determine max day index
    let maxDay = 0;
    this.places.forEach(p => {
      if ((p.dayIndex || 0) > maxDay) {
        maxDay = p.dayIndex || 0;
      }
    });

    // Create groups
    const groups: TripPlace[][] = [];
    for (let i = 0; i <= maxDay; i++) {
      groups.push(this.places.filter(p => (p.dayIndex || 0) === i));
    }
    this.groupedPlaces = groups;
    this.updateMapMarkers();
  }

  initMapCallback() {
    this.mapCallback = (err, controller) => {
      if (err || !controller) {
        Logger.error('ItineraryEditComponent', `Map init failed: ${err}`);
        console.error('Map init failed', err);
        this.isMapError = true;
        return;
      }
      this.mapController = controller;
      this.updateMapMarkers();
    };
  }

  updateMapMarkers() {
    if (!this.mapController || this.places.length === 0) {
      return;
    }

    // Clear existing markers (if API supports, otherwise just add new ones)
    // Note: In real app, we should manage markers more carefully.

    // For now, let's just focus the camera on the first place of the current day
    const currentPlaces = this.groupedPlaces[this.currentDayIndex] || [];
    if (currentPlaces.length > 0 && currentPlaces[0].latitude && currentPlaces[0].longitude) {
      const target: mapCommon.LatLng = {
        latitude: currentPlaces[0].latitude,
        longitude: currentPlaces[0].longitude
      };

      const cameraUpdate = map.newCameraPosition({
        target: target,
        zoom: 12
      });
      this.mapController.animateCamera(cameraUpdate);
    }
  }

  deletePlace(place: TripPlace) {
    const index = this.places.indexOf(place);
    if (index !== -1) {
      this.places.splice(index, 1);
      // Trigger update manually if needed, but @Watch should handle if reference changes or array mutation is observed
      // For @Link array mutation, sometimes we need to reassign.
      // But splice on @Link usually works.
      this.groupPlaces(); 
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 1. Map Area
        Stack({ alignContent: Alignment.TopStart }) {
          if (!this.isMapError) {
            MapComponent({
              mapOptions: {
                position: {
                  target: {
                    latitude: 39.9,
                    longitude: 116.4
                  },
                  zoom: 10
                }
              }, mapCallback: this.mapCallback
            })
              .width('100%')
              .height('100%')
          } else {
            // Fallback if map fails
            Column() {
              Text('地图加载失败')
                .fontColor(Color.Gray)
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#F0F0F0')
            .justifyContent(FlexAlign.Center)
          }

          // Back Button & Title
          Row() {
            // Back Icon (Mocked here, usually handled by parent router)
            Image($r('app.media.ic_arrow_back'))
               .width(24).height(24).fillColor(Color.Black)
               .margin({ right: 12 })
               .onClick(() => {
                  router.back();
               })

            if (this.isEditingTitle) {
              TextInput({ text: this.trip?.name })
                .onChange((value) => {
                  this.titleDraft = value;
                })
                .onSubmit(() => {
                  if (this.trip) {
                    this.trip.name = this.titleDraft;
                  }
                  this.isEditingTitle = false;
                })
                .onBlur(() => {
                  if (this.trip && this.titleDraft) {
                    this.trip.name = this.titleDraft;
                  }
                  this.isEditingTitle = false;
                })
                .backgroundColor(Color.White)
                .height(40)
                .layoutWeight(1)
                .borderRadius(8)
            } else {
              Row() {
                Text(this.trip?.name || '行程详情')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.Black)
                  .layoutWeight(1)
                
                Image($r('app.media.ic_cat_more')) // Edit icon placeholder
                  .width(16).height(16).fillColor('#666')
                  .margin({ left: 8 })
              }
              .backgroundColor(Color.White)
              .padding({
                left: 12,
                right: 12,
                top: 8,
                bottom: 8
              })
              .borderRadius(8)
              .shadow({ radius: 4, color: '#22000000', offsetY: 2 })
              .onClick(() => {
                this.titleDraft = this.trip?.name || '';
                this.isEditingTitle = true;
              })
              .layoutWeight(1)
            }
          }
          .width('90%')
          .margin({ top: 48, left: 16 })
        }
        .width('100%')
        .layoutWeight(1)

        // 2. Bottom Sheet (Itinerary List)
        Column() {
          // Drag Handle
          Row() {
            Divider()
              .width(40)
              .strokeWidth(4)
              .color('#CCCCCC')
              .lineCap(LineCapStyle.Round)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 8, bottom: 8 })

          // Day Tabs
          Scroll() {
            Row({ space: 12 }) {
              ForEach(this.groupedPlaces, (group: TripPlace[], index: number) => {
                Text(`第${index + 1}天`)
                  .fontSize(14)
                  .fontColor(this.currentDayIndex === index ? Color.White : '#666666')
                  .backgroundColor(this.currentDayIndex === index ? '#007DFF' : '#F5F5F5')
                  .padding({
                    left: 16,
                    right: 16,
                    top: 6,
                    bottom: 6
                  })
                  .borderRadius(16)
                  .onClick(() => {
                    this.currentDayIndex = index;
                    this.updateMapMarkers();
                  })
              })

              // Add Day Button
              Image($r('app.media.ic_cat_more')) // Reuse an icon for now or use Text '+'
                .width(28)
                .height(28)
                .backgroundColor('#F5F5F5')
                .padding(6)
                .borderRadius(14)
                .onClick(() => {
                  // Add new day logic
                  const newDayIndex = this.groupedPlaces.length;
                  this.groupedPlaces.push([]);
                  this.currentDayIndex = newDayIndex;
                })
            }
            .padding({ left: 16, right: 16 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
          .height(50)

          // Places List
          List() {
            if (this.groupedPlaces[this.currentDayIndex] && this.groupedPlaces[this.currentDayIndex].length > 0) {
              ForEach(this.groupedPlaces[this.currentDayIndex], (place: TripPlace, index: number) => {
                ListItem() {
                  Row() {
                    // Icon based on type
                    Image(this.getIconForType(place.type))
                      .width(40)
                      .height(40)
                      .backgroundColor('#F0F0F0')
                      .borderRadius(8)
                      .padding(8)

                    Column() {
                      Text(place.title)
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                      Row() {
                        Text(place.type)
                          .fontSize(12)
                          .fontColor('#999999')
                          .margin({ right: 8 })
                        if (place.distanceKm) {
                          Text(`距离 ${place.distanceKm}km`)
                            .fontSize(12)
                            .fontColor('#999999')
                        }
                      }
                      .margin({ top: 4 })
                    }
                    .layoutWeight(1)
                    .margin({ left: 12 })
                    .alignItems(HorizontalAlign.Start)

                    // Delete action
                    Text('删除')
                      .fontColor(Color.Red)
                      .fontSize(12)
                      .padding(8)
                      .onClick(() => {
                         this.deletePlace(place);
                      })
                  }
                  .padding({
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 12
                  })
                  .backgroundColor(Color.White)
                  .borderRadius(12)
                  .margin({ bottom: 8 })
                }
              })
            } else {
              ListItem() {
                Column() {
                  Text('暂无行程')
                    .fontSize(14)
                    .fontColor('#999999')
                    .margin({ bottom: 12 })
                }
                .width('100%')
                .padding({ top: 32, bottom: 32 })
                .alignItems(HorizontalAlign.Center)
              }
            }
          }
          .layoutWeight(1)
          .width('100%')
          .padding({ left: 16, right: 16 })

          // Actions
          Row() {
            Button('AI 规划')
              .backgroundColor('#E0F0FF')
              .fontColor('#007DFF')
              .layoutWeight(1)
              .margin({ right: 12 })
              .onClick(() => {
                promptAction.showToast({ message: 'AI 智能规划中...' });
              })

            Button('添加地点')
              .backgroundColor('#007DFF')
              .fontColor(Color.White)
              .layoutWeight(1)
              .onClick(() => {
                if (this.onAddPlace) {
                  this.onAddPlace(this.currentDayIndex);
                }
              })
          }
          .padding({ left: 16, right: 16, bottom: 30 }) // Increased bottom padding
          .width('100%')

        }
        .width('100%')
        .height(this.sheetHeight) // Adjustable height
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 24, topRight: 24 })
        .shadow({ radius: 16, color: '#11000000', offsetY: -4 })
      }
      .height('100%')
      .backgroundColor('#F5F5F5')

      // Floating Save Button
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Image($r('app.media.ic_func_new_trip')) // Placeholder for Save Icon
          .width(24).height(24).fillColor(Color.White)
      }
      .width(56)
      .height(56)
      .backgroundColor('#007DFF')
      .shadow({ radius: 8, color: '#44007DFF', offsetY: 4 })
      .position({ x: '80%', y: '85%' })
      .onClick(() => {
        if (this.onSave) {
          this.onSave();
        }
      })
    }
  }

  getIconForType(type: string): Resource {
    switch (type) {
      case 'hotel':
        return $r('app.media.ic_cat_hotel');
      case 'food':
        return $r('app.media.ic_cat_food');
      case 'sights':
        return $r('app.media.ic_cat_sights');
      case 'guide':
        return $r('app.media.ic_cat_guide');
      case 'tour':
        return $r('app.media.ic_cat_tour');
      case 'train':
        return $r('app.media.ic_cat_train');
      case 'flight':
        return $r('app.media.ic_cat_flight');
      default:
        return $r('app.media.ic_cat_more');
    }
  }
}
