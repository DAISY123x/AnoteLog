/**
 * @file TripRepository.ets
 * @brief 行程数据访问层
 * @description 负责 Trip 和 TripPlace 实体的完整 CRUD 及关联查询
 * @see RdbManager, Trip, TripPlace, TripWithPlaces
 */
import { Trip, TripPlace, TripWithPlaces } from '../model/TripModel';
import { RdbManager } from '../common/database/RdbManager';
import { Logger } from '../utils/Logger';
interface QueryParams {
  id?: number;
  keyword?: string;
  status?: string;
  limit?: number;
  offset?: number;
}

const TAG = 'TripRepository';

export class TripRepository {
  /**
   * 根据 ID 获取行程（含关联地点）
   * @param id 行程 ID
   * @returns TripWithPlaces 或 null
   */
  async getById(id: number): Promise<TripWithPlaces | null> {
    const queryParams: QueryParams = { id: id, limit: 1 };
    const trips = await this.query(queryParams);
    if (trips.length === 0) {
      return null;
    }
    const trip = trips[0];
    const places = await this.getTripPlaces(id);
    const tripWithPlaces: TripWithPlaces = {
      id: trip.id,
      name: trip.name,
      location: trip.location,
      startDate: trip.startDate,
      endDate: trip.endDate,
      coverImage: trip.coverImage,
      status: trip.status,
      createTime: trip.createTime,
      updateTime: trip.updateTime,
      places: places
    };
    return tripWithPlaces;
  }

  /**
   * 获取所有行程（不含地点）
   * @returns Trip[]
   */
  async getAll(): Promise<Trip[]> {
    const queryParams: QueryParams = {};
    return this.query(queryParams);
  }

  /**
   * 新增行程
   * @param trip 行程实体
   * @returns 新记录 ID
   */
  async insert(trip: Trip): Promise<number> {
    Logger.info(TAG, `insert: Creating trip "${trip.name}"`);
    return RdbManager.getInstance().insertTrip(trip);
  }

  /**
   * 更新行程
   * @param trip 行程实体
   * @returns 受影响行数
   */
  async update(trip: Trip): Promise<number> {
    Logger.info(TAG, `update: Updating trip ${trip.id}`);
    return RdbManager.getInstance().updateTrip(trip);
  }

  /**
   * 删除行程（级联删除关联地点）
   * @param id 行程 ID
   */
  async delete(id: number): Promise<void> {
    Logger.info(TAG, `delete: Deleting trip ${id}`);
    return RdbManager.getInstance().deleteTrip(id);
  }

  /**
   * 分页 + 筛选查询行程
   * @param params 查询参数
   * @param params.keyword 搜索关键词
   * @param params.status 行程状态（planning/ongoing/completed/all）
   * @param params.limit 每页数量
   * @param params.offset 偏移量
   * @returns Trip[]
   */
  async query(params: QueryParams): Promise<Trip[]> {
    return RdbManager.getInstance().getTrips(params.limit, params.offset, params.keyword, params.status);
  }

  /**
   * 获取待完成行程（planning + ongoing）
   * @returns Trip[]
   */
  async getPendingTrips(): Promise<Trip[]> {
    const queryParams: QueryParams = { status: 'all' };
    const allTrips = await this.query(queryParams);
    return allTrips.filter(t => t.status === 'planning' || t.status === 'ongoing');
  }

  /**
   * 获取行程关联地点
   * @param tripId 行程 ID
   * @returns TripPlace[]
   */
  async getTripPlaces(tripId: number): Promise<TripPlace[]> {
    return RdbManager.getInstance().getTripPlaces(tripId);
  }

  /**
   * 新增行程地点
   * @param place 地点实体
   * @returns 新记录 ID
   */
  async insertPlace(place: TripPlace): Promise<number> {
    Logger.info(TAG, `insertPlace: Adding place "${place.title}" to trip ${place.tripId}`);
    return RdbManager.getInstance().insertTripPlace(place);
  }

  /**
   * 更新行程地点
   * @param place 地点实体
   * @returns 受影响行数
   */
  async updatePlace(place: TripPlace): Promise<number> {
    Logger.info(TAG, `updatePlace: Updating place ${place.id}`);
    return RdbManager.getInstance().updateTripPlace(place);
  }

  /**
   * 删除行程地点
   * @param id 地点 ID
   * @returns 受影响行数
   */
  async deletePlace(id: number): Promise<number> {
    Logger.info(TAG, `deletePlace: Deleting place ${id}`);
    return RdbManager.getInstance().deleteTripPlace(id);
  }

  /**
   * 清空行程所有地点（用于重新规划）
   * @param tripId 行程 ID
   * @returns 受影响行数
   */
  async clearPlaces(tripId: number): Promise<number> {
    Logger.info(TAG, `clearPlaces: Clearing all places for trip ${tripId}`);
    return RdbManager.getInstance().deleteTripPlacesByTripId(tripId);
  }

  /**
   * 保存行程（含地点，原子操作）
   * @param trip 行程实体
   * @param places 地点列表
   * @returns 新行程 ID
   */
  async saveWithPlaces(trip: Trip, places: TripPlace[]): Promise<number> {
    const tripId = await this.insert(trip);
    for (const place of places) {
      const placeWithTripId: TripPlace = {
        id: place.id,
        tripId: tripId,
        title: place.title,
        type: place.type,
        distanceKm: place.distanceKm,
        durationMin: place.durationMin,
        note: place.note,
        latitude: place.latitude,
        longitude: place.longitude,
        orderIndex: place.orderIndex,
        dayIndex: place.dayIndex,
        icon: place.icon,
        address: place.address,
        detailJson: place.detailJson
      };
      await this.insertPlace(placeWithTripId);
    }
    return tripId;
  }
}
