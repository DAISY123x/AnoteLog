export interface Note {
  id: number | null;
  title: string;
  location: string;
  content: string;
  createTime?: number;
  updateTime?: number;
  images?: string; // JSON string for image array
  coverImage?: string; // 封面图片名称
  category?: string;
  isShared?: boolean;
  tags?: string[];
}
