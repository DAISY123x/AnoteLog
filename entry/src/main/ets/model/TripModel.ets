export interface Trip {
  id: number | null;
  name: string;
  location?: string;
  startDate?: number;
  endDate?: number;
  coverImage?: string;
  status?: 'planning' | 'ongoing' | 'completed';
  createTime?: number;
  updateTime?: number;
}

export interface TripPlace {
  id: number | null;
  tripId: number;
  title: string;
  type: string;
  distanceKm: number;
  durationMin: number;
  note?: string;
  latitude?: number;
  longitude?: number;
  orderIndex: number;
  dayIndex?: number; // 0 for day 1, 1 for day 2, etc.
  
  // New fields for refactoring
  icon?: string;
  address?: string;
  detailJson?: string; // Store full JSON for PlaceDetailPage
}

export interface TripWithPlaces extends Trip {
  places: TripPlace[];
}
