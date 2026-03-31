/**
 * @file PlaceDetailPage.ets
 * @brief 景点详情页
 * @description 展示景点详情，支持 AI 生成介绍、点赞收藏功能
 * @see LikeRepository, PlaceRepository, AIService, PlaceCard
 */
import router from '@ohos.router';
import { RouterManager } from '../common/utils/RouterManager';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import vibrator from '@ohos.vibrator';
import { AIService, AttractionDetail } from '../service/AIService';
import mediaquery from '@ohos.mediaquery';
import { Logger } from '../utils/Logger';
import { PlaceCard } from '../view/place/PlaceCard';

// 定义路由参数接口
export interface PlaceDetailParams {
  id: number;
  title: string;
  type: string;
  distanceKm: number;
  durationMin: number;
  note?: string;
  latitude?: number;
  longitude?: number;
  icon?: string;
  address?: string;
  detailJson?: string;
}

interface RouterParams {
  placeList?: PlaceDetailParams[];
  initialIndex?: number;
  // For backward compatibility or single item passed
  id?: number;
  title?: string;
  type?: string;
  distanceKm?: number;
  durationMin?: number;
  note?: string;
  latitude?: number;
  longitude?: number;
  icon?: string;
  address?: string;
  detailJson?: string;
}

@Entry
@Component
struct PlaceDetailPage {
  @State placeList: PlaceDetailParams[] = [];
  @State currentIndex: number = 0;
  @State currentPlace: PlaceDetailParams | null = null;
  @State detailInfo: AttractionDetail | null = null;
  @State isLoading: boolean = false;

  // Preloading
  private loadedDetails: Map<string, AttractionDetail> = new Map();
  private pendingRequests: Set<string> = new Set();

  // Responsive State
  @State currentBreakpoint: string = 'sm';
  private listenerSm = mediaquery.matchMediaSync('(0vp<=width<768vp)');
  private listenerMd = mediaquery.matchMediaSync('(768vp<=width<1024vp)');
  private listenerLg = mediaquery.matchMediaSync('(width>=1024vp)');
  // Swiper controller
  private swiperController: SwiperController = new SwiperController();

  // 页面转场配置
  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.Smooth })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 300, curve: Curve.Smooth })
      .slide(SlideEffect.Right)
  }

  aboutToAppear() {
    // Register media query listeners
    this.listenerSm.on('change', (result) => {
      if (result.matches) { this.currentBreakpoint = 'sm'; }
    });
    this.listenerMd.on('change', (result) => {
      if (result.matches) { this.currentBreakpoint = 'md'; }
    });
    this.listenerLg.on('change', (result) => {
      if (result.matches) { this.currentBreakpoint = 'lg'; }
    });

    const params = RouterManager.getInstance().getParams() as RouterParams;
    if (params) {
      if (params.placeList && params.placeList.length > 0) {
        this.placeList = params.placeList;
        this.currentIndex = params.initialIndex || 0;
      } else if (params.title) {
        this.placeList = [{
          id: params.id || 0,
          title: params.title,
          type: params.type || 'sights',
          distanceKm: params.distanceKm || 0,
          durationMin: params.durationMin || 0,
          note: params.note,
          latitude: params.latitude,
          longitude: params.longitude
        }];
        this.currentIndex = 0;
      }

      if (this.placeList.length > 0) {
        this.currentPlace = this.placeList[this.currentIndex];
        this.handleIndexChange(this.currentIndex);
      }
    }
  }

  /**
   * 预加载景点详情：当前页立即加载，相邻页提前缓存
   */
  async preloadAttraction(index: number) {
    if (index < 0 || index >= this.placeList.length) return;
    const place = this.placeList[index];
    const title = place.title;

    if (this.loadedDetails.has(title)) {
      if (index === this.currentIndex) {
        this.detailInfo = this.loadedDetails.get(title) || null;
      }
      return;
    }

    if (this.pendingRequests.has(title)) return;

    this.pendingRequests.add(title);
    if (index === this.currentIndex) { this.isLoading = true; }

    try {
      const details = await AIService.getInstance().getAttractionDetails(title);
      if (details) {
        this.loadedDetails.set(title, details);
        if (index === this.currentIndex) {
          this.detailInfo = details;
        }
      }
    } catch (e) {
      Logger.error('PlaceDetailPage', `Preload failed for ${title}`);
    } finally {
      this.pendingRequests.delete(title);
      if (index === this.currentIndex) { this.isLoading = false; }
    }
  }

  /**
   * 取消预加载请求（滑动离开时调用）
   */
  cancelPreload(index: number) {
    if (index < 0 || index >= this.placeList.length) return;
    const title = this.placeList[index].title;
    AIService.getInstance().cancelRequest(title);
    this.pendingRequests.delete(title);
  }

  /**
   * 处理 Swiper 索引变化：加载当前、预加载下一、取消旧请求
   */
  handleIndexChange(index: number) {
    this.currentIndex = index;
    this.currentPlace = this.placeList[index];
    this.preloadAttraction(index);
    this.preloadAttraction(index + 1);
    this.cancelPreload(index - 2);
    this.cancelPreload(index + 2);
  }

  /**
   * 单个景点详情视图（含背景、遮罩、卡片、返回按钮）
   */
  @Builder
  DetailView(place: PlaceDetailParams, index: number) {
    Stack() {
      // 全屏背景图（模糊处理）
      Image($r('app.media.background11'))
        .width('100%').height('100%').objectFit(ImageFit.Cover).blur(15)

      // 半透明黑色遮罩
      Column().width('100%').height('100%').backgroundColor('rgba(0, 0, 0, 0.40)')

      // 悬浮卡片组件
      PlaceCard({
        place: place,
        detailInfo: index === this.currentIndex ? this.detailInfo : (this.loadedDetails.get(place.title) || null),
        breakpoint: this.currentBreakpoint,
        isLoading: index === this.currentIndex ? this.isLoading : false
      })

      // 顶部返回按钮
      Row() {
        Image($r('app.media.ic_arrow_back')).width(24).height(24).fillColor(Color.White)
        Text('景点详情').fontColor('#ddd')
      }
      .onClick(() => { router.back(); })
      .position({ x: 0, y: 0 })
      .padding({ left: 20, top: 28 })
      .zIndex(10)
    }
    .width('100%').height('100%')
  }

  build() {
    Swiper(this.swiperController) {
      ForEach(this.placeList, (place: PlaceDetailParams, index: number) => {
        this.DetailView(place, index)
      })
    }
    .index(this.currentIndex)
    .width('100%').height('100%')
    .loop(false)
    .indicator(false)
    .onChange((index: number) => { this.handleIndexChange(index); })
  }
}
