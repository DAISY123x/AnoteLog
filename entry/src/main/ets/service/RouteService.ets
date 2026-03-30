import { navi, mapCommon } from '@kit.MapKit';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { Logger } from '../utils/Logger';

export interface RoutePoint {
  latitude: number;
  longitude: number;
}

export interface RouteResult {
  points: RoutePoint[];
  distance: number;
  duration: number;
}

// Define interfaces for MapKit route objects
interface StepWithPolyline {
  polyline?: RoutePoint[];
}

interface ErrorWithMessage {
  message?: string;
}

interface RouteWithDistance {
  distance?: number;
  duration?: number;
}


export class RouteService {
  private static instance: RouteService;
  private readonly TAG = 'RouteService';

  private constructor() {
  }

  public static getInstance(): RouteService {
    if (!RouteService.instance) {
      RouteService.instance = new RouteService();
    }
    return RouteService.instance;
  }

  /**
   * Plan a driving route between points
   * @param start Start location
   * @param end End location
   * @param waypoints Intermediate waypoints
   * @returns Route result with points for polyline
   */
  public async planDrivingRoute(start: RoutePoint, end: RoutePoint,
    waypoints: RoutePoint[] = []): Promise<RouteResult> {
    try {
      Logger.info(this.TAG, 'planDrivingRoute: Requesting route', [start, end, waypoints.length]);
      const startLatLng: mapCommon.LatLng = { latitude: start.latitude, longitude: start.longitude };
      const endLatLng: mapCommon.LatLng = { latitude: end.latitude, longitude: end.longitude };
      const wayLatLngs: mapCommon.LatLng[] =
        waypoints.map(p => ({ latitude: p.latitude, longitude: p.longitude } as mapCommon.LatLng));

      const params: navi.DrivingRouteParams = {
        origins: [startLatLng],
        destination: endLatLng,
        waypoints: wayLatLngs,
        language: "zh-CN"
      };

      // Note: The actual API for navi might be slightly different depending on version.
      // Based on common MapKit usage:
      const result = await navi.getDrivingRoutes(params);

      if (result && result.routes && result.routes.length > 0) {
        const route = result.routes[0];
        // Convert steps/polyline to points
        let points: RoutePoint[] = [];

        // Overview polyline is often provided
        if (route.overviewPolyline) {
          points = route.overviewPolyline.map(p => ({ latitude: p.latitude, longitude: p.longitude } as RoutePoint));
        } else if (route.steps) {
          // Fallback to steps
          route.steps.forEach((step) => {
            const stepWithPolyline = step as StepWithPolyline;
            if (stepWithPolyline.polyline) {
              stepWithPolyline.polyline.forEach((p) => points.push({
                latitude: p.latitude,
                longitude: p.longitude
              } as RoutePoint));
            }
          });
        }
        const routeWithDistance = route as RouteWithDistance;
        Logger.info(this.TAG, 'planDrivingRoute: Success',
          [points.length, routeWithDistance.distance || 0, routeWithDistance.duration || 0]);
        return {
          points: points,
          distance: routeWithDistance.distance || 0,
          duration: routeWithDistance.duration || 0
        };
      }

      Logger.warn(this.TAG, 'planDrivingRoute: No routes found');
      return { points: [], distance: 0, duration: 0 };
    } catch (e) {
      Logger.error(this.TAG, 'planDrivingRoute: Failed', [e]);
      throw new Error(typeof e === 'object' && e !== null && (e as ErrorWithMessage).message !== undefined ?
        (e as Error).message : String(e));
    }
  }
}
