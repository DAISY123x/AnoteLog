import { CustomPlace } from '../model/CustomPlaceModel';
import { RdbManager } from '../common/database/RdbManager';

export class PlaceService {
  private static instance: PlaceService;

  private constructor() {}

  public static getInstance(): PlaceService {
    if (!PlaceService.instance) {
      PlaceService.instance = new PlaceService();
    }
    return PlaceService.instance;
  }

  // "POST" interface simulation
  public async addPlace(place: CustomPlace): Promise<number> {
    console.info('[PlaceService] Adding place:', JSON.stringify(place));
    
    // 1. Data Validation
    if (!place.name || place.name.trim() === '') {
      throw new Error('Validation Failed: Name is required');
    }
    if (!place.address || place.address.trim() === '') {
      throw new Error('Validation Failed: Address is required');
    }
    if (place.latitude === undefined || place.longitude === undefined) {
      throw new Error('Validation Failed: Coordinates are required');
    }
    if (place.latitude < -90 || place.latitude > 90 || place.longitude < -180 || place.longitude > 180) {
      throw new Error('Validation Failed: Invalid coordinates');
    }

    // 2. Duplicate Check
    const isDuplicate = await RdbManager.getInstance().checkCustomPlaceDuplicate(place.name, place.latitude, place.longitude);
    if (isDuplicate) {
      throw new Error('Conflict: Place already exists with same name and location');
    }

    // 3. Storage
    try {
      const id = await RdbManager.getInstance().insertCustomPlace(place);
      console.info('[PlaceService] Place added successfully, id:', id);
      return id;
    } catch (e) {
      console.error('[PlaceService] DB Error:', e);
      throw new Error('Internal Server Error: Failed to save place');
    }
  }

  public async updatePlace(place: CustomPlace): Promise<void> {
    // 1. Data Validation
    if (!place.name || place.name.trim() === '') {
      throw new Error('Validation Failed: Name is required');
    }
    if (!place.address || place.address.trim() === '') {
      throw new Error('Validation Failed: Address is required');
    }
    if (place.latitude === undefined || place.longitude === undefined) {
      throw new Error('Validation Failed: Coordinates are required');
    }
    if (place.latitude < -90 || place.latitude > 90 || place.longitude < -180 || place.longitude > 180) {
      throw new Error('Validation Failed: Invalid coordinates');
    }

     if (!place.id) {
       throw new Error('Validation Failed: ID is required for update');
     }
     await RdbManager.getInstance().updateCustomPlace(place);
  }

  public async getPlaces(keyword?: string): Promise<CustomPlace[]> {
    return await RdbManager.getInstance().getCustomPlaces(undefined, undefined, keyword);
  }

  public async getPlaceById(id: number): Promise<CustomPlace | null> {
    return await RdbManager.getInstance().getCustomPlaceById(id);
  }
  
  public async deletePlace(id: number): Promise<void> {
    await RdbManager.getInstance().deleteCustomPlace(id);
  }

  // Import/Export Logic
  public async exportPlacesJson(): Promise<string> {
      const places = await this.getPlaces();
      return JSON.stringify(places, null, 2);
  }

  public async importPlacesJson(jsonStr: string): Promise<number> {
    try {
      const places = JSON.parse(jsonStr) as CustomPlace[];
      let count = 0;
      for (const p of places) {
        // Simple import: try insert, ignore if duplicate
        if (!await RdbManager.getInstance().checkCustomPlaceDuplicate(p.name, p.latitude, p.longitude)) {
           // Reset ID and Time
           p.id = undefined;
           p.createTime = Date.now();
           p.updateTime = Date.now();
           await RdbManager.getInstance().insertCustomPlace(p);
           count++;
        }
      }
      return count;
    } catch (err) {
      const e = err as Error;
      console.error('[PlaceService] Import failed', e);
      throw new Error('Import Failed: Invalid JSON format');
    }
  }
}
