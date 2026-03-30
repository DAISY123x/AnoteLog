import router from '@ohos.router';
import { BusinessError } from '@ohos.base';
import { RouterManager } from '../common/utils/RouterManager';
import { Trip, TripPlace } from '../model/TripModel';
import { RdbManager } from '../common/database/RdbManager';
import { promptAction } from '@kit.ArkUI';
import { ItineraryEditComponent } from '../view/ItineraryEditComponent';
import { SearchResult } from './SearchPage';

@Entry
@Component
struct TripDetailPage {
  @State trip: Trip | null = null;
  @State allPlaces: TripPlace[] = [];
  @State isLoading: boolean = true;
  @State editingDayIndex: number = 0;
  @StorageLink('selectedSearchResult') selectedSearchResult: SearchResult | null = null;

  aboutToAppear() {
    // Note: RouterManager doesn't wrap getParams yet, using router directly or adding helper
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
      this.allPlaces = await RdbManager.getInstance().getTripPlaces(this.trip.id);
    } catch (e) {
      console.error('Load places failed', e);
    } finally {
      this.isLoading = false;
    }
  }

  onSearchResult() {
    if (this.selectedSearchResult && this.trip) {
      // Add the selected place
      const newPlace: TripPlace = {
        id: null, // New place
        tripId: this.trip.id!,
        title: this.selectedSearchResult.title,
        type: this.selectedSearchResult.type,
        distanceKm: 0,
        durationMin: 60,
        note: this.selectedSearchResult.address,
        latitude: 39.9087 + Math.random() * 0.01, // Mock location if not provided
        longitude: 116.3975 + Math.random() * 0.01,
        orderIndex: 999,
        dayIndex: this.editingDayIndex
      };

      // Update UI
      this.allPlaces.push(newPlace);

      // Clear selection
      this.selectedSearchResult = null;
    }
  }

  async saveTrip() {
    if (!this.trip || !this.trip.id) {
      return;
    }
    try {
      // 1. Get current DB places to find deletions
      const dbPlaces = await RdbManager.getInstance().getTripPlaces(this.trip.id);
      const dbIds = dbPlaces.map(p => p.id).filter(id => id !== null) as number[];
      const currentIds = this.allPlaces.map(p => p.id).filter(id => id !== null && id !== undefined) as number[];

      // Find IDs to delete
      const toDelete = dbIds.filter(id => !currentIds.includes(id));
      for (const id of toDelete) {
        await RdbManager.getInstance().deleteTripPlace(id);
      }

      // 2. Upsert
      for (let i = 0; i < this.allPlaces.length; i++) {
        const p = this.allPlaces[i];
        // Update order index based on current list order? 
        // Note: allPlaces order might not reflect grouped order if user dragged items in groups.
        // But ItineraryEditComponent updates `groupedPlaces`, not `allPlaces` order directly usually.
        // Actually, ItineraryEditComponent.groupPlaces() is derived from places.
        // If we want to support reordering, ItineraryEditComponent should update the `places` array or we should reconstruct it from `groupedPlaces`.
        // Currently ItineraryEditComponent modifies `groupedPlaces`.
        // We need `ItineraryEditComponent` to sync back to `allPlaces` or expose the updated list.
        // Since `places` is a @Link, modifying it inside component works.
        // BUT `ItineraryEditComponent` currently only reads `places` to group them.
        // Let's assume for now we trust `allPlaces` contains the content.
        // Re-ordering logic in `ItineraryEditComponent` needs to update the `@Link places`.

        if (p.id) {
          await RdbManager.getInstance().updateTripPlace(p);
        } else {
          const newId = await RdbManager.getInstance().insertTripPlace(p);
          p.id = newId;
        }
      }

      // Update Trip Info (e.g. updateTime)
      this.trip.updateTime = Date.now();
      await RdbManager.getInstance().updateTrip(this.trip);

      promptAction.showToast({ message: '保存成功' });
    } catch (e) {
      console.error('Save failed', e);
      promptAction.showToast({ message: '保存失败' });
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
                console.info('Succeeded in jumping to the second page.')
              })
              .catch((err: BusinessError) => {
                console.error(`Failed to jump to the second page.Code is ${err.code}, message is ${err.message}`)
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
