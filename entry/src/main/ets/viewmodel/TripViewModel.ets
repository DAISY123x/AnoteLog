import { TripPlace } from '../model/TripModel';
import { PlaceResult } from '../service/MapService';
import { RouteService, RoutePoint } from '../service/RouteService';
import { Logger } from '../utils/Logger';

@Observed
export class TripGroup {
  id: number;
  name: string;
  places: TripPlace[];
  routePoints: RoutePoint[] = [];

  constructor(id: number, name: string, places: TripPlace[] = []) {
    this.id = id;
    this.name = name;
    this.places = places;
  }
}

@Observed
export class TripViewModel {
  groups: TripGroup[] = [];
  tripName: string = '';
  private readonly TAG = 'TripViewModel';

  constructor() {
    this.groups.push(new TripGroup(1, '第1天'));
  }

  loadTrip(tripName: string, places: TripPlace[]) {
    this.tripName = tripName;
    this.groups = [];

    if (places.length === 0) {
      this.groups.push(new TripGroup(1, '第1天'));
      return;
    }

    // Group by dayIndex
    const placesByDay = new Map<number, TripPlace[]>();
    let maxDayIndex = 0;

    places.forEach(p => {
      const day = p.dayIndex || 0;
      if (!placesByDay.has(day)) {
        placesByDay.set(day, []);
      }
      placesByDay.get(day)?.push(p);
      if (day > maxDayIndex) {
        maxDayIndex = day;
      }
    });

    for (let i = 0; i <= maxDayIndex; i++) {
      const dayPlaces = placesByDay.get(i) || [];
      // Sort by orderIndex
      dayPlaces.sort((a, b) => (a.orderIndex || 0) - (b.orderIndex || 0));
      this.groups.push(new TripGroup(i + 1, `第${i + 1}天`, dayPlaces));
      this.updateRoute(i);
    }
  }

  addPlace(place: PlaceResult, groupIndex: number = 0) {
    if (groupIndex < 0 || groupIndex >= this.groups.length) {
      Logger.warn(this.TAG, 'addPlace: Invalid group index', [groupIndex]);
      return;
    }

    Logger.info(this.TAG, 'addPlace: Adding place', [place.name]);

    const newPlace: TripPlace = {
      id: Date.now(), // Temporary ID for UI key
      tripId: 0,
      title: place.name,
      type: place.type || 'sights',
      distanceKm: 0,
      durationMin: 0,
      latitude: place.location.latitude,
      longitude: place.location.longitude,
      address: place.address,
      icon: place.icon,
      orderIndex: this.groups[groupIndex].places.length,
      dayIndex: groupIndex
    };

    this.groups[groupIndex].places = [...this.groups[groupIndex].places, newPlace];
    this.updateRoute(groupIndex);
  }

  removePlace(groupIndex: number, placeIndex: number) {
    if (groupIndex < 0 || groupIndex >= this.groups.length) {
      return;
    }
    if (placeIndex < 0 || placeIndex >= this.groups[groupIndex].places.length) {
      return;
    }

    Logger.info(this.TAG, 'removePlace: Removing place at index', [placeIndex]);

    const places = [...this.groups[groupIndex].places];
    places.splice(placeIndex, 1);
    this.groups[groupIndex].places = places;
    this.updateRoute(groupIndex);
  }

  addGroup() {
    const nextId = this.groups.length + 1;
    Logger.info(this.TAG, 'addGroup: Adding new group', [nextId]);
    this.groups.push(new TripGroup(nextId, `第${nextId}天`));
  }

  removeGroup(index: number) {
    if (index > 0 && index < this.groups.length) {
      Logger.info(this.TAG, 'removeGroup: Removing group at index', [index]);
      this.groups.splice(index, 1);
    }
  }

  getAllPlaces(): TripPlace[] {
    let all: TripPlace[] = [];
    this.groups.forEach(g => {
      all = all.concat(g.places);
    });
    return all;
  }

  swapPlaces(groupIndex: number, fromIndex: number, toIndex: number) {
    if (groupIndex < 0 || groupIndex >= this.groups.length) {
      return;
    }
    const places = [...this.groups[groupIndex].places];
    if (fromIndex < 0 || fromIndex >= places.length || toIndex < 0 || toIndex >= places.length) {
      return;
    }

    Logger.info(this.TAG, 'swapPlaces: Swapping places', [fromIndex, toIndex]);

    const temp = places[fromIndex];
    places[fromIndex] = places[toIndex];
    places[toIndex] = temp;

    // Update orderIndex
    places.forEach((p, index) => p.orderIndex = index);

    // Trigger update
    this.groups[groupIndex].places = places;
    this.updateRoute(groupIndex);
  }

  /**
   * AI Intelligent Planning: Sorts places by nearest neighbor distance
   */
  async optimizeRoute(groupIndex: number): Promise<boolean> {
    if (groupIndex < 0 || groupIndex >= this.groups.length) {
      return false;
    }

    Logger.info(this.TAG, 'optimizeRoute: Starting optimization for group', [groupIndex]);

    const originalPlaces = [...this.groups[groupIndex].places];
    if (originalPlaces.length <= 2) {
      Logger.info(this.TAG, 'optimizeRoute: Not enough places to optimize');
      return true;
    }

    // Simple Greedy TSP
    const sorted: TripPlace[] = [];
    const unvisited = [...originalPlaces];

    // Start with the first one (assume user wants to start there)
    let current = unvisited.shift();
    if (current) {
      sorted.push(current);
    }

    while (unvisited.length > 0 && current) {
      let nearestIndex = -1;
      let minDist = Number.MAX_VALUE;

      for (let i = 0; i < unvisited.length; i++) {
        const p = unvisited[i];
        if (current.latitude && current.longitude && p.latitude && p.longitude) {
          const dist = this.calculateDistance(current.latitude, current.longitude, p.latitude, p.longitude);
          if (dist < minDist) {
            minDist = dist;
            nearestIndex = i;
          }
        }
      }

      if (nearestIndex !== -1) {
        current = unvisited.splice(nearestIndex, 1)[0];
        sorted.push(current);
      } else {
        // Fallback if no valid coordinates
        current = unvisited.shift();
        if (current) {
          sorted.push(current);
        }
      }
    }

    Logger.info(this.TAG, 'optimizeRoute: Optimization complete');
    this.groups[groupIndex].places = sorted;
    await this.updateRoute(groupIndex);
    return true;
  }

  async updateRoute(groupIndex: number) {
    if (groupIndex < 0 || groupIndex >= this.groups.length) {
      return;
    }
    const places = this.groups[groupIndex].places;

    if (places.length < 2) {
      this.groups[groupIndex].routePoints = [];
      return;
    }

    const validPlaces = places.filter(p => p.latitude !== undefined && p.longitude !== undefined);
    if (validPlaces.length < 2) {
      this.groups[groupIndex].routePoints = [];
      return;
    }

    try {
      Logger.info(this.TAG, 'updateRoute: Planning route', [validPlaces.length]);
      const start = { latitude: validPlaces[0].latitude!, longitude: validPlaces[0].longitude! } as RoutePoint;
      const end = {
        latitude: validPlaces[validPlaces.length-1].latitude!,
        longitude: validPlaces[validPlaces.length-1].longitude!
      } as RoutePoint;
      const waypoints = validPlaces.slice(1, validPlaces.length - 1)
        .map(p => ({ latitude: p.latitude!, longitude: p.longitude! } as RoutePoint));

      const result = await RouteService.getInstance().planDrivingRoute(start, end, waypoints);
      Logger.info(this.TAG, 'updateRoute: Route planned successfully', [result.points.length]);

      // Force update logic (create new array ref?)
      // Since TripGroup is observed, updating property should work if we use assignment?
      // But routePoints is an array.
      this.groups[groupIndex].routePoints = result.points;
    } catch (e) {
      Logger.error(this.TAG, 'updateRoute: Failed to plan route', [e]);
      this.groups[groupIndex].routePoints = [];
    }
  }

  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Radius of the earth in km
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const d = R * c; // Distance in km
    return d;
  }

  private deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }
}
