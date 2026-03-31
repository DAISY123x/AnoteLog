/**
 * @file TripDetailPage.ets
 * @brief 行程详情页
 * @description 查看和编辑行程详情，支持添加/删除/排序景点
 * @see TripRepository, ItineraryEditComponent
 */
import router from '@ohos.router';
import { BusinessError } from '@ohos.base';
import { RouterManager } from '../common/utils/RouterManager';
import { Trip, TripPlace } from '../model/TripModel';
import { TripRepository } from '../repository/TripRepository';
import { promptAction } from '@kit.ArkUI';
import { ItineraryEditComponent } from '../view/ItineraryEditComponent';
import { SearchResult } from './SearchPage';
import { Logger } from '../utils/Logger';

@Entry
@Component
struct TripDetailPage {
  @State trip: Trip | null = null;
  @State allPlaces: TripPlace[] = [];
  @State isLoading: boolean = true;
  @State editingDayIndex: number = 0;
  @StorageLink('selectedSearchResult') selectedSearchResult: SearchResult | null = null;
  private tripRepository: TripRepository = new TripRepository();

  aboutToAppear() {
    const params = RouterManager.getInstance().getParams() as Record<string, Object>;
    if (params && params['trip']) {
      this.trip = params['trip'] as Trip;
      this.loadPlaces();
    } else {
      this.isLoading = false;
    }
  }

  async loadPlaces() {
    if (!this.trip || !this.trip.id) {
      return;
    }
    try {
      this.allPlaces = await this.tripRepository.getTripPlaces(this.trip.id);
    } catch (e) {
      Logger.error('TripDetailPage', 'Load places failed', e);
    } finally {
      this.isLoading = false;
    }
  }

  onSearchResult() {
    if (this.selectedSearchResult && this.trip) {
      const newPlace: TripPlace = {
        id: null,
        tripId: this.trip.id!,
        title: this.selectedSearchResult.title,
        type: this.selectedSearchResult.type,
        distanceKm: 0,
        durationMin: 60,
        note: this.selectedSearchResult.address,
        latitude: 39.9087 + Math.random() * 0.01,
        longitude: 116.3975 + Math.random() * 0.01,
        orderIndex: 999,
        dayIndex: this.editingDayIndex
      };
      this.allPlaces.push(newPlace);
      this.selectedSearchResult = null;
    }
  }

  async saveTrip() {
    if (!this.trip || !this.trip.id) {
      return;
    }
    try {
      const dbPlaces = await this.tripRepository.getTripPlaces(this.trip.id);
      const dbIds = dbPlaces.map(p => p.id).filter(id => id !== null) as number[];
      const currentIds = this.allPlaces.map(p => p.id).filter(id => id !== null && id !== undefined) as number[];
      const toDelete = dbIds.filter(id => !currentIds.includes(id));
      for (const id of toDelete) {
        await this.tripRepository.deletePlace(id);
      }

      for (let i = 0; i < this.allPlaces.length; i++) {
        const p = this.allPlaces[i];
        if (p.id) {
          await this.tripRepository.updatePlace(p);
        } else {
          const newId = await this.tripRepository.insertPlace(p);
          p.id = newId;
        }
      }

      this.trip.updateTime = Date.now();
      await this.tripRepository.update(this.trip);

      promptAction.showToast({ message: '保存成功' });
    } catch (e) {
      Logger.error('TripDetailPage', 'Save failed', e);
    }
  }

  build() {
    Column() {
      if (this.trip) {
        ItineraryEditComponent({
          trip: $trip,
          places: $allPlaces,
          onAddPlace: (dayIndex) => {
            this.editingDayIndex = dayIndex;
            router.pushUrl({ url: 'pages/SearchPage' })
              .then(() => {
                Logger.info('TripDetailPage', 'Succeeded in jumping to the second page.')
              })
              .catch((err: BusinessError) => {
                Logger.error('TripDetailPage', `Failed to jump to the second page.Code is ${err.code}, message is ${err.message}`)
              })
          },
          onSave: () => {
            this.saveTrip();
          }
        })
      } else {
        LoadingProgress().width(50).height(50)
          .color(Color.Blue)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F0F0F0')
  }
}
