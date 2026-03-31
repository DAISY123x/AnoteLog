/**
 * @file MockService.ets
 * @brief Mock 数据服务
 * @description 当后端未部署或 enabled=true 时，提供 Mock 数据模拟真实 API 响应。
 *             数据来源于 resources/rawfile/mock-config.json，切换到真实后端只需设置 enabled=false。
 * @see resources/rawfile/mock-config.json
 */
import { Note } from '../../model/NoteModel';
import { Trip, TripPlace, TripWithPlaces } from '../../model/TripModel';
import { DbPlace } from '../database/RdbManager';
import { Logger } from '../../utils/Logger';
import resourceManager from '@ohos.resourceManager';

const TAG = 'MockService';

interface MockModules {
  note: boolean;
  trip: boolean;
  place: boolean;
  user: boolean;
  ai: boolean;
  map: boolean;
}

interface MockConfig {
  enabled: boolean;
  baseUrl: string;
  modules: MockModules;
  notes: Note[];
  trips: MockTripWithPlaces[];
  places: MockPlace[];
  banners: MockBanner[];
  notifications: MockNotification[];
}

interface MockTripWithPlaces {
  id: number;
  name: string;
  location: string;
  startDate: number;
  endDate: number;
  coverImage: string;
  status: 'planning' | 'ongoing' | 'completed';
  createTime: number;
  updateTime: number;
  places: TripPlace[];
}

interface MockPlace {
  id: number;
  title: string;
  type: string;
  address: string;
  latitude: number;
  longitude: number;
  distanceKm: number;
  durationMin: number;
}

interface MockBanner {
  id: number;
  imageSrc: string;
  title: string;
}

interface MockNotification {
  id: number;
  title: string;
  content: string;
  time: string;
  isRead: boolean;
}

// In-memory mutable store for CRUD operations
let mockNotes: Note[] = [];
let mockTrips: MockTripWithPlaces[] = [];
let mockPlaces: MockPlace[] = [];
let mockBanners: MockBanner[] = [];
let mockNotifications: MockNotification[] = [];
let configLoaded: boolean = false;

export class MockService {
  private static instance: MockService;
  private config: MockConfig | null = null;

  private constructor() {
  }

  public static getInstance(): MockService {
    if (!MockService.instance) {
      MockService.instance = new MockService();
    }
    return MockService.instance;
  }

  /**
   * 检查 Mock 模式是否启用
   */
  public isEnabled(): boolean {
    return this.config?.enabled ?? false;
  }

  /**
   * 检查指定模块是否启用 Mock
   */
  public isModuleEnabled(module: 'note' | 'trip' | 'place' | 'user' | 'ai' | 'map'): boolean {
    if (!this.config?.enabled) {
      return false;
    }
    switch (module) {
      case 'note':
        return this.config.modules.note ?? false;
      case 'trip':
        return this.config.modules.trip ?? false;
      case 'place':
        return this.config.modules.place ?? false;
      case 'user':
        return this.config.modules.user ?? false;
      case 'ai':
        return this.config.modules.ai ?? false;
      case 'map':
        return this.config.modules.map ?? false;
      default:
        return false;
    }
  }

  /**
   * 异步初始化，从 rawfile 加载配置
   * @param resourceManager 资源管理器
   */
  public async init(resourceManager: resourceManager.ResourceManager): Promise<void> {
    if (configLoaded) {
      return;
    }

    try {
      const rawData: Uint8Array = await resourceManager.getRawFileContent('mock-config.json');
      let jsonStr = '';
      for (let i = 0; i < rawData.length; i++) {
        jsonStr += String.fromCharCode(rawData[i]);
      }
      this.config = JSON.parse(jsonStr) as MockConfig;
      mockNotes = JSON.parse(JSON.stringify(this.config.notes));
      mockTrips = JSON.parse(JSON.stringify(this.config.trips));
      mockPlaces = JSON.parse(JSON.stringify(this.config.places || []));
      mockBanners = JSON.parse(JSON.stringify(this.config.banners));
      mockNotifications = JSON.parse(JSON.stringify(this.config.notifications));
      configLoaded = true;
      Logger.info(TAG, `MockService initialized, enabled: ${this.config.enabled}`);
    } catch (e) {
      Logger.error(TAG, `Failed to load mock-config.json: ${e}`);
      this.config = {
        enabled: false,
        baseUrl: '',
        modules: {
          note: false,
          trip: false,
          place: false,
          user: false,
          ai: false,
          map: false
        } as MockModules,
        notes: [],
        trips: [],
        places: [],
        banners: [],
        notifications: []
      } as MockConfig;
    }
  }

  // ==================== 笔记 Mock ====================

  public async getNotes(limit?: number, offset?: number, isShared?: boolean, category?: string): Promise<Note[]> {
    let result = [...mockNotes];
    if (isShared !== undefined) {
      result = result.filter(n => n.isShared === isShared);
    }
    if (category !== undefined && category !== '全部') {
      result = result.filter(n => n.category === category);
    }
    const start = offset ?? 0;
    const end = limit !== undefined ? start + limit : result.length;
    return result.slice(start, end);
  }

  public async getNoteById(id: number): Promise<Note | null> {
    return mockNotes.find(n => n.id === id) ?? null;
  }

  public async insertNote(note: Note): Promise<number> {
    let maxId = 0;
    for (let i: number = 0; i < mockNotes.length; i++) {
      const currentId: number = mockNotes[i].id ?? 0;
      if (currentId > maxId) {
        maxId = currentId;
      }
    }
    const newId = mockNotes.length > 0 ? maxId + 1 : 1;
    const newNote: Note = {
      id: newId,
      title: note.title,
      location: note.location ?? '',
      content: note.content,
      category: note.category,
      tags: note.tags,
      isShared: note.isShared,
      coverImage: note.coverImage,
      createTime: Date.now(),
      updateTime: Date.now()
    };
    mockNotes.unshift(newNote);
    return newId;
  }

  public async updateNote(note: Note): Promise<number> {
    const idx = mockNotes.findIndex(n => n.id === note.id);
    if (idx >= 0) {
      mockNotes[idx] = {
        id: mockNotes[idx].id,
        title: note.title ?? mockNotes[idx].title,
        location: note.location ?? mockNotes[idx].location,
        content: note.content ?? mockNotes[idx].content,
        category: note.category ?? mockNotes[idx].category,
        tags: note.tags ?? mockNotes[idx].tags,
        isShared: note.isShared ?? mockNotes[idx].isShared,
        coverImage: note.coverImage ?? mockNotes[idx].coverImage,
        createTime: mockNotes[idx].createTime,
        updateTime: Date.now()
      };
      return 1;
    }
    return 0;
  }

  public async deleteNote(id: number): Promise<number> {
    const idx = mockNotes.findIndex(n => n.id === id);
    if (idx >= 0) {
      mockNotes.splice(idx, 1);
      return 1;
    }
    return 0;
  }

  // ==================== 行程 Mock ====================

  public async getTrips(limit?: number, offset?: number, keyword?: string, status?: string): Promise<Trip[]> {
    let result: Trip[] = mockTrips.map((t: MockTripWithPlaces): Trip => ({
      id: t.id,
      name: t.name,
      location: t.location,
      startDate: t.startDate,
      endDate: t.endDate,
      coverImage: t.coverImage,
      status: t.status,
      createTime: t.createTime,
      updateTime: t.updateTime
    } as Trip));
    if (keyword) {
      result =
        result.filter((t: Trip): boolean => (t.name ?? '').includes(keyword) || (t.location ?? '').includes(keyword));
    }
    if (status && status !== 'all') {
      result = result.filter(t => t.status === status);
    }

    const start = offset ?? 0;
    const end = limit !== undefined ? start + limit : result.length;
    return result.slice(start, end);
  }

  public async getTripWithPlaces(id: number): Promise<TripWithPlaces | null> {
    const trip = mockTrips.find(t => t.id === id);
    if (!trip) {
      return null;
    }
    return {
      id: trip.id,
      name: trip.name,
      location: trip.location,
      startDate: trip.startDate,
      endDate: trip.endDate,
      coverImage: trip.coverImage,
      status: trip.status,
      createTime: trip.createTime,
      updateTime: trip.updateTime,
      places: trip.places || []
    };
  }

  public async insertTrip(trip: Trip): Promise<number> {
    const newId = mockTrips.length > 0 ? Math.max(...mockTrips.map(t => t.id)) + 1 : 1;
    const newTrip: MockTripWithPlaces = {
      id: newId,
      name: trip.name,
      location: trip.location ?? '',
      startDate: trip.startDate ?? Date.now(),
      endDate: trip.endDate ?? Date.now() + 86400000, // 默认加1天
      coverImage: trip.coverImage ?? '',
      status: trip.status ?? 'planning',
      createTime: Date.now(),
      updateTime: Date.now(),
      places: []
    };
    mockTrips.unshift(newTrip);
    return newId;
  }

  public async updateTrip(trip: Trip): Promise<number> {
    const idx = mockTrips.findIndex(t => t.id === trip.id);
    if (idx >= 0) {
      mockTrips[idx] = {
        id: mockTrips[idx].id,
        name: trip.name ?? mockTrips[idx].name,
        location: trip.location ?? mockTrips[idx].location,
        startDate: trip.startDate ?? mockTrips[idx].startDate,
        endDate: trip.endDate ?? mockTrips[idx].endDate,
        coverImage: trip.coverImage ?? mockTrips[idx].coverImage,
        status: trip.status ?? mockTrips[idx].status,
        createTime: mockTrips[idx].createTime,
        updateTime: Date.now(),
        places: mockTrips[idx].places
      } as MockTripWithPlaces;
      return 1;
    }
    return 0;
  }

  public async deleteTrip(id: number): Promise<void> {
    const idx = mockTrips.findIndex(t => t.id === id);
    if (idx >= 0) {
      mockTrips.splice(idx, 1);
    }
  }

  public async getTripPlaces(tripId: number): Promise<TripPlace[]> {
    const trip = mockTrips.find(t => t.id === tripId);
    return trip?.places || [];
  }

  // ==================== 收藏地点 Mock ====================
  public async getSavedPlaces(): Promise<DbPlace[]> {
    return mockPlaces.map((p: MockPlace): DbPlace => ({
      id: p.id,
      title: p.title,
      type: p.type,
      distanceKm: p.distanceKm,
      durationMin: p.durationMin
    } as DbPlace));
  }

  // ==================== Banner Mock ====================

  public getBanners(): MockBanner[] {
    return [...mockBanners];
  }

  // ==================== 通知 Mock ====================

  public getNotifications(): MockNotification[] {
    return [...mockNotifications];
  }
}
