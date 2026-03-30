import relationalStore from '@ohos.data.relationalStore';
import { Trip, TripPlace } from '../../model/TripModel';
import { Note } from '../../model/NoteModel';
import { CustomPlace } from '../../model/CustomPlaceModel';
import common from '@ohos.app.ability.common';
import { Logger } from '../../utils/Logger';

// 数据库查询返回的场所接口，不包含trip相关字段
export interface DbPlace {
  id: number;
  title: string;
  type: string;
  distanceKm: number;
  durationMin: number;
  note?: string;
  latitude?: number;
  longitude?: number;
}

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'Anote.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

export class RdbManager {
  private static instance: RdbManager;
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: common.UIAbilityContext | null = null;

  private constructor() {
  }

  public static getInstance(): RdbManager {
    if (!RdbManager.instance) {
      RdbManager.instance = new RdbManager();
    }
    return RdbManager.instance;
  }

  public async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    if (this.rdbStore) {
      return;
    }

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      await this.createTables();
    } catch (err) {
      Logger.error('RdbManager', `init RdbStore failed, code is ${err.code}, message is ${err.message}`);
      console.error(`init RdbStore failed, code is ${err.code}, message is ${err.message}`);
    }
  }

  private async createTables(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }

    // Create Trip Table
    const createTripTable = `CREATE TABLE IF NOT EXISTS trip (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      start_date INTEGER,
      end_date INTEGER,
      cover_image TEXT,
      status TEXT,
      create_time INTEGER,
      update_time INTEGER
    )`;

    // Create TripPlace Table
    const createPlaceTable = `CREATE TABLE IF NOT EXISTS trip_place (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      trip_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      type TEXT,
      distance_km REAL,
      duration_min INTEGER,
      note TEXT,
      latitude REAL,
      longitude REAL,
      order_index INTEGER,
      day_index INTEGER
    )`;

    // Create Note Table
    const createNoteTable = `CREATE TABLE IF NOT EXISTS note (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      location TEXT,
      content TEXT,
      create_time INTEGER,
      update_time INTEGER,
      images TEXT,
      category TEXT,
      is_shared INTEGER
    )`;

    // Create user_like Table
    const createUserLikeTable = `CREATE TABLE IF NOT EXISTS user_like (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      target_id INTEGER NOT NULL,
      type TEXT NOT NULL,
      create_time INTEGER
    )`;

    // Create saved_place Table
    const createSavedPlaceTable = `CREATE TABLE IF NOT EXISTS saved_place (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      type TEXT,
      distance_km REAL,
      duration_min INTEGER,
      note TEXT,
      latitude REAL,
      longitude REAL
    )`;

    // Create feedback Table
    const createFeedbackTable = `CREATE TABLE IF NOT EXISTS feedback (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      content TEXT NOT NULL,
      contact TEXT,
      create_time INTEGER
    )`;

    // Create custom_place Table (New)
    const createCustomPlaceTable = `CREATE TABLE IF NOT EXISTS custom_place (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      address TEXT,
      latitude REAL,
      longitude REAL,
      type TEXT,
      contact TEXT,
      create_time INTEGER,
      update_time INTEGER
    )`;

    await this.rdbStore.executeSql(createTripTable);
    try {
      await this.rdbStore.executeSql('ALTER TABLE trip ADD COLUMN location TEXT');
    } catch (e) {
      // Column might already exist
    }
    try {
      await this.rdbStore.executeSql('ALTER TABLE trip ADD COLUMN status TEXT');
    } catch (e) {
      // Column might already exist
    }
    try {
      await this.rdbStore.executeSql('ALTER TABLE trip_place ADD COLUMN day_index INTEGER');
    } catch (e) {
      // Column might already exist
    }
    await this.rdbStore.executeSql(createPlaceTable);
    await this.rdbStore.executeSql(createNoteTable);
    await this.rdbStore.executeSql(createUserLikeTable);
    await this.rdbStore.executeSql(createSavedPlaceTable);
    await this.rdbStore.executeSql(createFeedbackTable);
    await this.rdbStore.executeSql(createCustomPlaceTable);

    try {
      await this.rdbStore.executeSql('ALTER TABLE note ADD COLUMN category TEXT');
    } catch (e) {
      // Column might already exist
    }
    try {
      await this.rdbStore.executeSql('ALTER TABLE note ADD COLUMN is_shared INTEGER');
    } catch (e) {
      // Column might already exist
    }
  }

  public async insertNote(note: Note): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }
    const valueBucket: relationalStore.ValuesBucket = {
      title: note.title || '',
      location: note.location || '',
      content: note.content || '',
      create_time: Date.now(),
      update_time: Date.now(),
      images: note.images || '[]',
      category: note.category || '经验',
      is_shared: note.isShared ? 1 : 0
    };

    return await this.rdbStore.insert('note', valueBucket);
  }

  public async updateNote(note: Note): Promise<number> {
    if (!this.rdbStore || !note.id) {
      return -1;
    }
    const valueBucket: relationalStore.ValuesBucket = {
      title: note.title || '',
      location: note.location || '',
      content: note.content || '',
      update_time: Date.now(),
      images: note.images || '[]',
      category: note.category || '经验',
      is_shared: note.isShared ? 1 : 0
    };

    let predicates = new relationalStore.RdbPredicates('note');
    predicates.equalTo('id', note.id);
    return await this.rdbStore.update(valueBucket, predicates);
  }

  public async deleteNote(id: number): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }
    let predicates = new relationalStore.RdbPredicates('note');
    predicates.equalTo('id', id);
    return await this.rdbStore.delete(predicates);
  }

  public async getNotes(limit?: number, offset?: number, isShared?: boolean, category?: string): Promise<Note[]> {
    if (!this.rdbStore) {
      return [];
    }

    let predicates = new relationalStore.RdbPredicates('note');

    if (isShared !== undefined) {
      predicates.equalTo('is_shared', isShared ? 1 : 0);
    }

    if (category && category !== '全部') {
      predicates.equalTo('category', category);
    }

    // Order by create_time desc
    predicates.orderByDesc('create_time');

    // Pagination support
    if (limit !== undefined) {
      predicates.limitAs(limit);
    }
    if (offset !== undefined) {
      predicates.offsetAs(offset);
    }

    let resultSet = await this.rdbStore.query(predicates);

    let notes: Note[] = [];
    while (resultSet.goToNextRow()) {
      notes.push({
        id: resultSet.getLong(resultSet.getColumnIndex('id')) || 0,
        title: resultSet.getString(resultSet.getColumnIndex('title')) || '',
        location: resultSet.getString(resultSet.getColumnIndex('location')) || '',
        content: resultSet.getString(resultSet.getColumnIndex('content')) || '',
        createTime: resultSet.getLong(resultSet.getColumnIndex('create_time')) || 0,
        updateTime: resultSet.getLong(resultSet.getColumnIndex('update_time')) || 0,
        images: resultSet.getString(resultSet.getColumnIndex('images')) || '[]',
        category: resultSet.getString(resultSet.getColumnIndex('category')) || '经验',
        isShared: (resultSet.getLong(resultSet.getColumnIndex('is_shared')) || 0) === 1
      });
    }
    resultSet.close();
    return notes;
  }

  public async insertTrip(trip: Trip): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }
    const valueBucket: relationalStore.ValuesBucket = {
      name: trip.name || '',
      start_date: trip.startDate || 0,
      end_date: trip.endDate || 0,
      cover_image: trip.coverImage || '',
      status: trip.status || 'planning',
      create_time: Date.now(),
      update_time: Date.now()
    };

    return await this.rdbStore.insert('trip', valueBucket);
  }

  public async getTrips(limit?: number, offset?: number, keyword?: string, status?: string): Promise<Trip[]> {
    if (!this.rdbStore) {
      return [];
    }

    let predicates = new relationalStore.RdbPredicates('trip');

    if (keyword && keyword.trim() !== '') {
      predicates.like('name', `%${keyword.trim()}%`);
    }

    if (status && status !== 'all') {
      predicates.equalTo('status', status);
    }

    predicates.orderByDesc('create_time');

    if (limit !== undefined) {
      predicates.limitAs(limit);
    }
    if (offset !== undefined) {
      predicates.offsetAs(offset);
    }

    let resultSet = await this.rdbStore.query(predicates);

    let trips: Trip[] = [];
    while (resultSet.goToNextRow()) {
      trips.push({
        id: resultSet.getLong(resultSet.getColumnIndex('id')) || 0,
        name: resultSet.getString(resultSet.getColumnIndex('name')) || '',
        location: resultSet.getString(resultSet.getColumnIndex('location')) || '',
        startDate: resultSet.getLong(resultSet.getColumnIndex('start_date')) || 0,
        endDate: resultSet.getLong(resultSet.getColumnIndex('end_date')) || 0,
        coverImage: resultSet.getString(resultSet.getColumnIndex('cover_image')) || '',
        status: resultSet.getString(resultSet.getColumnIndex('status')) as 'planning' | 'ongoing' | 'completed' ||
          'planning',
        createTime: resultSet.getLong(resultSet.getColumnIndex('create_time')) || 0,
        updateTime: resultSet.getLong(resultSet.getColumnIndex('update_time')) || 0
      });
    }
    resultSet.close();
    return trips;
  }

  public async updateTrip(trip: Trip): Promise<number> {
    if (!this.rdbStore || !trip.id) {
      return -1;
    }
    const valueBucket: relationalStore.ValuesBucket = {
      name: trip.name || '',
      location: trip.location || '',
      start_date: trip.startDate || 0,
      end_date: trip.endDate || 0,
      cover_image: trip.coverImage || '',
      status: trip.status || 'planning',
      update_time: Date.now()
    };

    let predicates = new relationalStore.RdbPredicates('trip');
    predicates.equalTo('id', trip.id);
    return await this.rdbStore.update(valueBucket, predicates);
  }

  public async deleteTrip(id: number): Promise<void> {
    if (!this.rdbStore) {
      return;
    }

    // Delete places first (cascade manually as RDB might not support FK cascade directly in this simple setup or to be safe)
    let placePredicates = new relationalStore.RdbPredicates('trip_place');
    placePredicates.equalTo('trip_id', id);
    await this.rdbStore.delete(placePredicates);

    // Delete trip
    let predicates = new relationalStore.RdbPredicates('trip');
    predicates.equalTo('id', id);
    await this.rdbStore.delete(predicates);
  }

  public async insertTripPlace(place: TripPlace): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }
    const valueBucket: relationalStore.ValuesBucket = {
      trip_id: place.tripId,
      title: place.title,
      type: place.type || 'sights',
      distance_km: place.distanceKm || 0,
      duration_min: place.durationMin || 0,
      note: place.note || '',
      latitude: place.latitude || 0,
      longitude: place.longitude || 0,
      order_index: place.orderIndex || 0,
      day_index: place.dayIndex || 0
    };
    return await this.rdbStore.insert('trip_place', valueBucket);
  }

  public async getTripPlaces(tripId: number): Promise<TripPlace[]> {
    if (!this.rdbStore) {
      return [];
    }

    let predicates = new relationalStore.RdbPredicates('trip_place');
    predicates.equalTo('trip_id', tripId);
    predicates.orderByAsc('order_index');

    let resultSet = await this.rdbStore.query(predicates);

    let places: TripPlace[] = [];
    while (resultSet.goToNextRow()) {
      places.push({
        id: resultSet.getLong(resultSet.getColumnIndex('id')) || 0,
        tripId: resultSet.getLong(resultSet.getColumnIndex('trip_id')) || 0,
        title: resultSet.getString(resultSet.getColumnIndex('title')) || '',
        type: resultSet.getString(resultSet.getColumnIndex('type')) || '',
        distanceKm: resultSet.getDouble(resultSet.getColumnIndex('distance_km')) || 0,
        durationMin: resultSet.getLong(resultSet.getColumnIndex('duration_min')) || 0,
        note: resultSet.getString(resultSet.getColumnIndex('note')) || '',
        latitude: resultSet.getDouble(resultSet.getColumnIndex('latitude')) || 0,
        longitude: resultSet.getDouble(resultSet.getColumnIndex('longitude')) || 0,
        orderIndex: resultSet.getLong(resultSet.getColumnIndex('order_index')) || 0,
        dayIndex: resultSet.getLong(resultSet.getColumnIndex('day_index')) || 0
      });
    }
    resultSet.close();
    return places;
  }

  public async updateTripPlace(place: TripPlace): Promise<number> {
    if (!this.rdbStore || !place.id) {
      return -1;
    }
    const valueBucket: relationalStore.ValuesBucket = {
      title: place.title,
      type: place.type,
      distance_km: place.distanceKm,
      duration_min: place.durationMin,
      note: place.note || null,
      latitude: place.latitude || null,
      longitude: place.longitude || null,
      order_index: place.orderIndex,
      day_index: place.dayIndex || 0
    };

    let predicates = new relationalStore.RdbPredicates('trip_place');
    predicates.equalTo('id', place.id);
    return await this.rdbStore.update(valueBucket, predicates);
  }

  public async deleteTripPlace(id: number): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }
    let predicates = new relationalStore.RdbPredicates('trip_place');
    predicates.equalTo('id', id);
    return await this.rdbStore.delete(predicates);
  }

  public async deleteTripPlacesByTripId(tripId: number): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }
    let predicates = new relationalStore.RdbPredicates('trip_place');
    predicates.equalTo('trip_id', tripId);
    return await this.rdbStore.delete(predicates);
  }

  // Like & SavedPlace Methods

  public async toggleLike(targetId: number, type: 'note' | 'place'): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    // Check if exists
    let predicates = new relationalStore.RdbPredicates('user_like');
    predicates.equalTo('target_id', targetId);
    predicates.equalTo('type', type);

    let resultSet = await this.rdbStore.query(predicates);
    if (resultSet.rowCount > 0) {
      // Unlike
      await this.rdbStore.delete(predicates);
      resultSet.close();
      return false;
    } else {
      // Like
      const valueBucket: relationalStore.ValuesBucket = {
        target_id: targetId,
        type: type,
        create_time: Date.now()
      };
      await this.rdbStore.insert('user_like', valueBucket);
      resultSet.close();
      return true;
    }
  }

  public async isLiked(targetId: number, type: 'note' | 'place'): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }
    let predicates = new relationalStore.RdbPredicates('user_like');
    predicates.equalTo('target_id', targetId);
    predicates.equalTo('type', type);
    let resultSet = await this.rdbStore.query(predicates);
    const isLiked = resultSet.rowCount > 0;
    resultSet.close();
    return isLiked;
  }

  public async getLikedNotes(): Promise<Note[]> {
    if (!this.rdbStore) {
      return [];
    }

    // Get all liked note IDs
    let predicates = new relationalStore.RdbPredicates('user_like');
    predicates.equalTo('type', 'note');
    let resultSet = await this.rdbStore.query(predicates);
    let ids: number[] = [];
    while (resultSet.goToNextRow()) {
      ids.push(resultSet.getLong(resultSet.getColumnIndex('target_id')));
    }
    resultSet.close();

    if (ids.length === 0) {
      return [];
    }

    // Get notes
    let notePredicates = new relationalStore.RdbPredicates('note');
    notePredicates.in('id', ids);
    notePredicates.orderByDesc('create_time');

    let noteSet = await this.rdbStore.query(notePredicates);
    let notes: Note[] = [];
    while (noteSet.goToNextRow()) {
      notes.push({
        id: noteSet.getLong(noteSet.getColumnIndex('id')) || 0,
        title: noteSet.getString(noteSet.getColumnIndex('title')) || '',
        location: noteSet.getString(noteSet.getColumnIndex('location')) || '',
        content: noteSet.getString(noteSet.getColumnIndex('content')) || '',
        createTime: noteSet.getLong(noteSet.getColumnIndex('create_time')) || 0,
        updateTime: noteSet.getLong(noteSet.getColumnIndex('update_time')) || 0,
        images: noteSet.getString(noteSet.getColumnIndex('images')) || '[]',
        category: noteSet.getString(noteSet.getColumnIndex('category')) || '经验',
        isShared: (noteSet.getLong(noteSet.getColumnIndex('is_shared')) || 0) === 1
      });
    }
    noteSet.close();
    return notes;
  }

  public async savePlace(place: DbPlace): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }

    // Check if same title exists to avoid dupes (simple logic)
    let predicates = new relationalStore.RdbPredicates('saved_place');
    predicates.equalTo('title', place.title);
    let resultSet = await this.rdbStore.query(predicates);
    if (resultSet.rowCount > 0) {
      resultSet.goToFirstRow();
      const id = resultSet.getLong(resultSet.getColumnIndex('id'));
      resultSet.close();
      return id;
    }
    resultSet.close();

    const valueBucket: relationalStore.ValuesBucket = {
      title: place.title || '',
      type: place.type || 'sights',
      distance_km: place.distanceKm || 0,
      duration_min: place.durationMin || 0,
      note: place.note || '',
      latitude: place.latitude || 0,
      longitude: place.longitude || 0
    };
    return await this.rdbStore.insert('saved_place', valueBucket);
  }

  public async getLikedPlaces(): Promise<DbPlace[]> {
    if (!this.rdbStore) {
      return [];
    }

    // Get liked place IDs
    let predicates = new relationalStore.RdbPredicates('user_like');
    predicates.equalTo('type', 'place');
    let resultSet = await this.rdbStore.query(predicates);
    let ids: number[] = [];
    while (resultSet.goToNextRow()) {
      ids.push(resultSet.getLong(resultSet.getColumnIndex('target_id')));
    }
    resultSet.close();

    if (ids.length === 0) {
      return [];
    }

    let placePredicates = new relationalStore.RdbPredicates('saved_place');
    placePredicates.in('id', ids);
    let placeSet = await this.rdbStore.query(placePredicates);
    let places: DbPlace[] = [];
    while (placeSet.goToNextRow()) {
      places.push({
        id: placeSet.getLong(placeSet.getColumnIndex('id')),
        title: placeSet.getString(placeSet.getColumnIndex('title')),
        type: placeSet.getString(placeSet.getColumnIndex('type')),
        distanceKm: placeSet.getDouble(placeSet.getColumnIndex('distance_km')),
        durationMin: placeSet.getLong(placeSet.getColumnIndex('duration_min')),
        note: placeSet.getString(placeSet.getColumnIndex('note')),
        latitude: placeSet.getDouble(placeSet.getColumnIndex('latitude')),
        longitude: placeSet.getDouble(placeSet.getColumnIndex('longitude'))
      });
    }
    placeSet.close();
    return places;
  }

  public async submitFeedback(content: string, contact: string): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }
    const valueBucket: relationalStore.ValuesBucket = {
      content: content,
      contact: contact,
      create_time: Date.now()
    };
    return await this.rdbStore.insert('feedback', valueBucket);
  }

  public async getCustomPlaceById(id: number): Promise<CustomPlace | null> {
    if (!this.rdbStore) {
      return null;
    }
    let predicates = new relationalStore.RdbPredicates('custom_place');
    predicates.equalTo('id', id);
    let resultSet = await this.rdbStore.query(predicates);
    
    if (resultSet.rowCount === 0) {
      resultSet.close();
      return null;
    }

    resultSet.goToFirstRow();
    const place: CustomPlace = {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      name: resultSet.getString(resultSet.getColumnIndex('name')),
      address: resultSet.getString(resultSet.getColumnIndex('address')),
      latitude: resultSet.getDouble(resultSet.getColumnIndex('latitude')),
      longitude: resultSet.getDouble(resultSet.getColumnIndex('longitude')),
      type: resultSet.getString(resultSet.getColumnIndex('type')),
      contact: resultSet.getString(resultSet.getColumnIndex('contact')),
      createTime: resultSet.getLong(resultSet.getColumnIndex('create_time')),
      updateTime: resultSet.getLong(resultSet.getColumnIndex('update_time'))
    };
    resultSet.close();
    return place;
  }

  public async insertCustomPlace(place: CustomPlace): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }
    const valueBucket: relationalStore.ValuesBucket = {
      name: place.name,
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
      type: place.type,
      contact: place.contact,
      create_time: place.createTime,
      update_time: place.updateTime
    };
    return await this.rdbStore.insert('custom_place', valueBucket);
  }

  public async updateCustomPlace(place: CustomPlace): Promise<number> {
    if (!this.rdbStore || !place.id) {
      return -1;
    }
    const valueBucket: relationalStore.ValuesBucket = {
      name: place.name,
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
      type: place.type,
      contact: place.contact,
      update_time: Date.now()
    };
    let predicates = new relationalStore.RdbPredicates('custom_place');
    predicates.equalTo('id', place.id);
    return await this.rdbStore.update(valueBucket, predicates);
  }

  public async deleteCustomPlace(id: number): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }
    let predicates = new relationalStore.RdbPredicates('custom_place');
    predicates.equalTo('id', id);
    return await this.rdbStore.delete(predicates);
  }

  public async getCustomPlaces(limit?: number, offset?: number, keyword?: string): Promise<CustomPlace[]> {
    if (!this.rdbStore) {
      return [];
    }
    let predicates = new relationalStore.RdbPredicates('custom_place');
    if (keyword) {
      predicates.like('name', `%${keyword}%`);
    }
    predicates.orderByDesc('create_time');
    if (limit !== undefined) {
      predicates.limitAs(limit);
    }
    if (offset !== undefined) {
      predicates.offsetAs(offset);
    }

    let resultSet = await this.rdbStore.query(predicates);
    let places: CustomPlace[] = [];
    while (resultSet.goToNextRow()) {
      places.push({
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        name: resultSet.getString(resultSet.getColumnIndex('name')),
        address: resultSet.getString(resultSet.getColumnIndex('address')),
        latitude: resultSet.getDouble(resultSet.getColumnIndex('latitude')),
        longitude: resultSet.getDouble(resultSet.getColumnIndex('longitude')),
        type: resultSet.getString(resultSet.getColumnIndex('type')),
        contact: resultSet.getString(resultSet.getColumnIndex('contact')),
        createTime: resultSet.getLong(resultSet.getColumnIndex('create_time')),
        updateTime: resultSet.getLong(resultSet.getColumnIndex('update_time'))
      });
    }
    resultSet.close();
    return places;
  }

  public async checkCustomPlaceDuplicate(name: string, lat: number, lng: number): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }
    let predicates = new relationalStore.RdbPredicates('custom_place');
    predicates.equalTo('name', name);
    // Use a small epsilon for float comparison if needed, but RDB equalTo is usually exact or close enough for this
    predicates.equalTo('latitude', lat);
    predicates.equalTo('longitude', lng);
    let resultSet = await this.rdbStore.query(predicates);
    let count = resultSet.rowCount;
    resultSet.close();
    return count > 0;
  }
}
