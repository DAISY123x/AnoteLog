import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { TripPlace } from '../model/TripModel';
import { RoutePoint } from '../service/RouteService';
import { Logger } from '../utils/Logger';

@Component
export struct MapContainer {
  @Prop @Watch('updateMap') places: TripPlace[];
  @Prop @Watch('updateMap') routePoints: RoutePoint[];
  private mapController: map.MapComponentController | null = null;
  private mapOptions: mapCommon.MapOptions | undefined = undefined;
  private mapCallback: AsyncCallback<map.MapComponentController> | undefined = undefined;

  aboutToAppear(): void {
    // Initialize map options
    this.mapOptions = {
      position: {
        target: { latitude: 39.9082, longitude: 116.3977 },
        zoom: 10
      }
    };

    // Initialize callback - using regular method to avoid 'this' context issues in @Component struct
    this.mapCallback = (err: BusinessError, mapController: map.MapComponentController): void => {
      if (!err && mapController) {
        Logger.info('MapContainer', 'onMapLoad: Map loaded successfully');
        this.mapController = mapController;
        this.mapController.setMyLocationEnabled(true);
        this.mapController.setMyLocationControlsEnabled(true);
        this.updateMap();
      } else {
        Logger.error('MapContainer', 'onMapLoad: Failed to load map', [err?.code, err?.message]);
      }
    };
  }

  aboutToDisappear(): void {
    this.mapController = null;
    this.mapCallback = undefined;
  }

  updateMap(): void {
    if (!this.mapController) {
      return;
    }

    Logger.info('MapContainer', 'updateMap: Updating map',
      [this.places.length, this.routePoints ? this.routePoints.length : 0]);

    this.mapController.clear();

    if (this.places.length === 0) {
      return;
    }

    this.places.forEach((place, index) => {
      if (place.latitude !== undefined && place.longitude !== undefined) {
        let markerOptions: mapCommon.MarkerOptions = {
          position: {
            latitude: place.latitude,
            longitude: place.longitude
          },
          title: place.title,
          snippet: place.address,
          clickable: true,
          icon: this.getIconPath(place.type)
        };
        this.mapController?.addMarker(markerOptions);
      }
    });

    if (this.routePoints && this.routePoints.length > 1) {
      Logger.info('MapContainer', 'updateMap: Drawing route polyline');

      const validPoints = this.routePoints
        .filter(p => p && typeof p.latitude === 'number' && typeof p.longitude === 'number')
        .map(p => ({ latitude: p.latitude, longitude: p.longitude } as mapCommon.LatLng));

      if (validPoints.length > 1) {
        try {
          this.mapController.addPolyline({
            points: validPoints,
            color: 0xFF1677FF,
            width: 10,
            zIndex: 10
          });
        } catch (e) {
          Logger.error('MapContainer', 'updateMap: Failed to add polyline', [e]);
        }
      }
    } else if (this.places.length > 1) {
      Logger.info('MapContainer', 'updateMap: Drawing straight lines fallback');
      const points = this.places
        .filter(p => p && typeof p.latitude === 'number' && typeof p.longitude === 'number')
        .map(p => ({ latitude: p.latitude!, longitude: p.longitude! } as mapCommon.LatLng));

      if (points.length > 1) {
        try {
          this.mapController.addPolyline({
            points: points,
            color: 0xFFAAAAAA,
            width: 6,
            zIndex: 5
          });
        } catch (e) {
          Logger.error('MapContainer', 'updateMap: Failed to add fallback polyline', [e]);
        }
      }
    }

    this.fitBounds();
  }

  getIconPath(type: string): string | undefined {
    return undefined;
  }

  fitBounds(): void {
    if (this.places.length === 0 || !this.mapController) {
      return;
    }

    let minLat = 90;
    let maxLat = -90;
    let minLng = 180;
    let maxLng = -180;
    let hasValidLocation = false;

    this.places.forEach(p => {
      if (p.latitude !== undefined && p.longitude !== undefined) {
        if (p.latitude < minLat) {
          minLat = p.latitude;
        }
        if (p.latitude > maxLat) {
          maxLat = p.latitude;
        }
        if (p.longitude < minLng) {
          minLng = p.longitude;
        }
        if (p.longitude > maxLng) {
          maxLng = p.longitude;
        }
        hasValidLocation = true;
      }
    });

    if (hasValidLocation) {
      const padding = 0.05;
      let update = map.newLatLngBounds({
        northeast: { latitude: maxLat + padding, longitude: maxLng + padding },
        southwest: { latitude: minLat - padding, longitude: minLng - padding }
      }, 100);
      this.mapController.animateCamera(update);
    }
  }

  build() {
    Stack() {
      if (this.mapOptions && this.mapCallback) {
        MapComponent({
          mapOptions: this.mapOptions,
          mapCallback: this.mapCallback
        })
          .width('100%')
          .height('100%')
      }
    }
  }
}
