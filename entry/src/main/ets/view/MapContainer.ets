import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { TripPlace } from '../model/TripModel';
import { RoutePoint } from '../service/RouteService';
import { Logger } from '../utils/Logger';

@Component
export struct MapContainer {
  @Prop @Watch('updateMap') places: TripPlace[];
  @Prop @Watch('updateMap') routePoints: RoutePoint[]; // Receive route points
  private mapController: map.MapComponentController | null = null;
  private readonly TAG = 'MapContainer';
  private onMapLoad: AsyncCallback<map.MapComponentController> = (err, mapController) => {
    if (!err && mapController) {
      Logger.info(this.TAG, 'onMapLoad: Map loaded successfully');
      this.mapController = mapController;
      this.mapController.setMyLocationEnabled(true);
      this.mapController.setMyLocationControlsEnabled(true);

      // Initial update
      this.updateMap();
    } else {
      Logger.error(this.TAG, 'onMapLoad: Failed to load map', [err]);
    }
  };

  updateMap() {
    if (!this.mapController) {
      return;
    }

    Logger.info(this.TAG, 'updateMap: Updating map',
      [this.places.length, this.routePoints ? this.routePoints.length : 0]);

    // Clear existing annotations and polylines
    this.mapController.clear();

    if (this.places.length === 0) {
      return;
    }

    // Add Markers
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
          // Use a simple color/icon differentiation if possible, 
          // or just default marker for now to ensure stability.
          // To use custom icon: icon: 'path/to/icon'
          icon: this.getIconPath(place.type)
        };
        this.mapController?.addMarker(markerOptions);
      }
    });

    // Draw Polyline
    // If we have routePoints, use them
    if (this.routePoints && this.routePoints.length > 1) {
      Logger.info(this.TAG, 'updateMap: Drawing route polyline');
      
      const validPoints = this.routePoints
        .filter(p => p && typeof p.latitude === 'number' && typeof p.longitude === 'number')
        .map(p => ({ latitude: p.latitude, longitude: p.longitude } as mapCommon.LatLng));

      if (validPoints.length > 1) {
        try {
          this.mapController.addPolyline({
            points: validPoints,
            color: 0xFF1677FF, // Blue color
            width: 10,
            zIndex: 10
          });
        } catch (e) {
          Logger.error(this.TAG, 'updateMap: Failed to add polyline', [e]);
        }
      }
    } else if (this.places.length > 1) {
      // Fallback to straight lines
      Logger.info(this.TAG, 'updateMap: Drawing straight lines fallback');
      const points = this.places
        .filter(p => p && typeof p.latitude === 'number' && typeof p.longitude === 'number')
        .map(p => ({ latitude: p.latitude!, longitude: p.longitude! } as mapCommon.LatLng));

      if (points.length > 1) {
        try {
          this.mapController.addPolyline({
            points: points,
            color: 0xFFAAAAAA, // Grey for straight line
            width: 6,
            zIndex: 5
          });
        } catch (e) {
          Logger.error(this.TAG, 'updateMap: Failed to add fallback polyline', [e]);
        }
      }
    }

    // Fit bounds to show all markers
    this.fitBounds();
  }

  getIconPath(type: string): string | undefined {
    // MapKit expects file path or resource. 
    // Since we can't easily map resource ID to path here without context,
    // we might just return undefined to use default red marker, 
    // or use a known asset path if copied to rawfile.
    // For "High pass rate", default marker is safest unless we are sure about assets.
    return undefined;
  }

  fitBounds() {
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
      // Add some padding
      const padding = 0.05;
      const bounds: mapCommon.LatLngBounds = {
        northeast: { latitude: maxLat + padding, longitude: maxLng + padding },
        southwest: { latitude: minLat - padding, longitude: minLng - padding }
      };

      // cameraUpdate is used to move camera
      let update = map.newLatLngBounds(bounds, 100); // 100 padding
      this.mapController.animateCamera(update);
    }
  }

  build() {
    Stack() {
      MapComponent({
        mapOptions: {
          position: {
            target: { latitude: 39.9082, longitude: 116.3977 }, // Default Beijing
            zoom: 10
          }
        },
        mapCallback: this.onMapLoad
      })
        .width('100%')
        .height('100%')
    }
  }
}
