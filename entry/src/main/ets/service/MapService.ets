import { site, navi, mapCommon } from '@kit.MapKit';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';

export interface Location {
  latitude: number;
  longitude: number;
}

export interface PlaceResult {
  id: string;
  name: string;
  address: string;
  location: Location;
  type?: string;
  icon?: string;
}

export interface RouteResult {
  points: Location[];
  distance: number;
  duration: number;
}

interface Route {
  steps?: Step[];
  distance?: number;
  duration?: number;
}

interface Step {
  roads?: Road[];
}

interface Road {
  polyline?: LatLng[];
}

interface LatLng {
  latitude: number;
  longitude: number;
}

export class MapService {
  private static instance: MapService;

  private constructor() {
  }

  public static getInstance(): MapService {
    if (!MapService.instance) {
      MapService.instance = new MapService();
    }
    return MapService.instance;
  }

  /**
   * Search places by keyword (using searchByText as per documentation)
   * @param query Address or place name
   * @param location Optional location
   * @returns List of places with coordinates
   */
  public async searchPlaces(query: string, location?: Location): Promise<PlaceResult[]> {
    if (!query) {
      return [];
    }

    const params: site.SearchByTextParams = {
      query: query,
      language: "zh-CN",
      location: location ? { latitude: location.latitude, longitude: location.longitude } : undefined,
      radius: 5000
    };

    try {
      console.info(`[MapService] Searching for: ${query} with params: ${JSON.stringify(params)}`);
      const result = await site.searchByText(params);
      console.info(`[MapService] Raw searchByText result: ${JSON.stringify(result)}`);

      if (result && result.sites) {
        console.info(`[MapService] Search found ${result.sites.length} results`);
        return result.sites.map((s: site.Site) => {
          // Clean up icon string: remove backticks and whitespace
          let iconUrl = '';
          if (s.poi && s.poi.icon) {
            iconUrl = s.poi.icon.replace(/[`\s]/g, '');
          }

          let typeStr = 'sights';
          if (s.poi && s.poi.poiTypes && s.poi.poiTypes.length > 0) {
            typeStr = s.poi.poiTypes[0];
          }

          let result: PlaceResult = {
            id: s.siteId || '',
            name: s.name || s.formatAddress || '',
            address: s.formatAddress || '',
            location: {
              latitude: s.location?.latitude || 0,
              longitude: s.location?.longitude || 0
            } as Location,
            type: typeStr,
            icon: iconUrl
          };
          return result;
        });
      }
      console.warn(`[MapService] Search returned no results`);
      return [];
    } catch (err) {
      const errorStr = JSON.stringify(err);
      console.error(`[MapService] Search failed: ${errorStr}`);
      // Fallback to geocode if searchByText fails (e.g. strict address)
      if (query.length > 0) {
        console.info('[MapService] Falling back to geocode');
        return this.geocode(query);
      }
      return [];
    }
  }

  private async geocode(query: string): Promise<PlaceResult[]> {
    const params: site.GeocodeParams = {
      query: query,
      language: "zh-CN"
    };
    try {
      const result = await site.geocode(params);
      if (result && result.sites) {
        return result.sites.map((s: site.Site) => {
          let iconUrl = '';
          if (s.poi && s.poi.icon) {
            iconUrl = s.poi.icon.replace(/[`\s]/g, '');
          }
          let typeStr = 'sights';
          if (s.poi && s.poi.poiTypes && s.poi.poiTypes.length > 0) {
            typeStr = s.poi.poiTypes[0];
          }
          let result: PlaceResult = {
            id: s.siteId || '',
            name: s.name || s.formatAddress || '',
            address: s.formatAddress || '',
            location: {
              latitude: s.location?.latitude || 0,
              longitude: s.location?.longitude || 0
            } as Location,
            type: typeStr,
            icon: iconUrl
          };
          return result;
        });
      }
      return [];
    } catch (e) {
      console.error('Geocode fallback failed', JSON.stringify(e));
      return [];
    }
  }

  /**
   * Search nearby places
   * @deprecated Not strictly in the provided doc reference, keeping as placeholder or removing if strictness requires.
   * For now, I'll comment it out or leave it if it's not used by NewTripPage.
   * NewTripPage uses searchPlaces.
   */
  // public async searchNearby(location: Location, type?: string): Promise<PlaceResult[]> { ... }

  /**
   * Search nearby places
   * @param location Center location
   * @param type POI Type (optional)
   */
  public async searchNearby(location: Location, type?: string): Promise<PlaceResult[]> {
    const params: site.NearbySearchParams = {
      location: { latitude: location.latitude, longitude: location.longitude } as Location,
      query: type, // Can be used as query filter
      radius: 1000,
      pageIndex: 1,
      pageSize: 20
    };

    try {
      const result = await site.nearbySearch(params);
      if (result && result.sites) {
        return result.sites.map((s: site.Site) => {
          let typeStr = 'other';
          if (s.poi && s.poi.poiTypes && s.poi.poiTypes.length > 0) {
            typeStr = s.poi.poiTypes[0];
          }

          let result: PlaceResult = {
            id: s.siteId || '',
            name: s.name || '',
            address: s.formatAddress || '',
            location: {
              latitude: s.location?.latitude || 0,
              longitude: s.location?.longitude || 0
            } as Location,
            type: typeStr
          };
          return result;
        });
      }
      return [];
    } catch (err) {
      console.error('MapService nearby search failed', JSON.stringify(err));
      throw new Error(JSON.stringify(err));
    }
  }

  public async planDrivingRoute(start: Location, end: Location, waypoints?: Location[]): Promise<RouteResult | null> {
    let waypointsParam: mapCommon.LatLng[] = [];
    if (waypoints && waypoints.length > 0) {
      waypointsParam = waypoints.map((w: Location): mapCommon.LatLng => {
        return {
          latitude: w.latitude,
          longitude: w.longitude
        } as mapCommon.LatLng;
      });
    }

    const params: navi.DrivingRouteParams = {
      origins: [{ latitude: start.latitude, longitude: start.longitude }],
      destination: { latitude: end.latitude, longitude: end.longitude },
      waypoints: waypointsParam
    };

    try {
      console.info('[MapService] Planning driving route...');
      const result = await navi.getDrivingRoutes(params);
      if (result && result.routes && result.routes.length > 0) {
        // Use type assertion to access route properties if needed, or define interfaces
        // Since navi.Route might be complex, we can use any temporarily but cast to known structure
        // Or better, define the interface locally if we know the structure.
        // Assuming Route structure based on docs: steps -> roads -> polyline

        const route = result.routes[0];
        let points: Location[] = [];

        // Safe access with type checks
        if (route.steps) {
          for (let i = 0; i < route.steps.length; i++) {
            const step = route.steps[i];
            if (step.roads) {
              for (let j = 0; j < step.roads.length; j++) {
                const road = step.roads[j];
                if (road.polyline) {
                  for (let k = 0; k < road.polyline.length; k++) {
                    const p = road.polyline[k];
                    points.push({ latitude: p.latitude, longitude: p.longitude });
                  }
                }
              }
            }
          }
        }
        console.info(`[MapService] Route planned with ${points.length} points`);
        return {
          points: points,
          distance: (route as Route).distance || 0,
          duration: (route as Route).duration || 0
        };
      }
      console.warn('[MapService] No routes found');
      return null;
    } catch (err) {
      console.error('[MapService] planDrivingRoute failed', JSON.stringify(err));
      // throw new Error(JSON.stringify(err));
      return null;
    }
  }
}
