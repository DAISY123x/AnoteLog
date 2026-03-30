import router from '@ohos.router';
import { RouterManager } from '../common/utils/RouterManager';
import { BusinessError } from '@kit.BasicServicesKit';
import { RdbManager, DbPlace } from '../common/database/RdbManager';
import { promptAction } from '@kit.ArkUI';
import vibrator from '@ohos.vibrator';
import { AIService, AttractionDetail } from '../service/AIService';
import mediaquery from '@ohos.mediaquery';

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

interface CardStyle {
  width: string;
  height: string;
  radius: number;
  bgColor: Color;
}

interface LayoutStyle {
  padding: number;
  textBtnGap: number;
  titleAlign: TextAlign;
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
      if (result.matches) {
        this.currentBreakpoint = 'sm';
      }
    });
    this.listenerMd.on('change', (result) => {
      if (result.matches) {
        this.currentBreakpoint = 'md';
      }
    });
    this.listenerLg.on('change', (result) => {
      if (result.matches) {
        this.currentBreakpoint = 'lg';
      }
    });

    const params = RouterManager.getInstance().getParams() as RouterParams;
    if (params) {
      if (params.placeList && params.placeList.length > 0) {
        this.placeList = params.placeList;
        this.currentIndex = params.initialIndex || 0;
      } else if (params.title) {
        // Single item passed, wrap in list
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
        // Trigger initial load
        this.handleIndexChange(this.currentIndex);
      }
    }
  }

  // Preload Logic
  async preloadAttraction(index: number) {
    if (index < 0 || index >= this.placeList.length) return;
    const place = this.placeList[index];
    const title = place.title;

    // Check if already loaded
    if (this.loadedDetails.has(title)) {
        if (index === this.currentIndex) {
            this.detailInfo = this.loadedDetails.get(title) || null;
        }
        return;
    }

    // Check if already pending
    if (this.pendingRequests.has(title)) return;

    this.pendingRequests.add(title);
    if (index === this.currentIndex) {
        this.isLoading = true;
    }

    try {
        const details = await AIService.getInstance().getAttractionDetails(title);
        if (details) {
            this.loadedDetails.set(title, details);
            if (index === this.currentIndex) {
                this.detailInfo = details;
            }
        }
    } catch (e) {
        console.error(`Preload failed for ${title}`, e);
    } finally {
        this.pendingRequests.delete(title);
        if (index === this.currentIndex) {
            this.isLoading = false;
        }
    }
  }

  cancelPreload(index: number) {
    if (index < 0 || index >= this.placeList.length) return;
    const title = this.placeList[index].title;
    // Only cancel if it's pending and NOT the current one (user might have just scrolled back)
    // But requirement says "cancel unfinished requests".
    // We should probably cancel anything that is NOT current or next.
    AIService.getInstance().cancelRequest(title);
    this.pendingRequests.delete(title);
  }

  handleIndexChange(index: number) {
    this.currentIndex = index;
    this.currentPlace = this.placeList[index];
    
    // 1. Load Current
    this.preloadAttraction(index);

    // 2. Preload Next
    this.preloadAttraction(index + 1);

    // 3. Cancel Previous (e.g. index - 2) or Next Next (index + 2) if we want to be aggressive
    // For now, let's just cancel index - 2 and index + 2 to keep it clean
    this.cancelPreload(index - 2);
    this.cancelPreload(index + 2);
  }

  @Builder
  DetailView(place: PlaceDetailParams, index: number) {
    Stack() {
      // 1. 全屏背景图（模糊处理）
      Image($r('app.media.background11'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .blur(15) // 增强模糊

      // 半透明黑色遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.40)')

      // 2. 悬浮卡片组件
      PlaceCard({
        place: place,
        detailInfo: index === this.currentIndex ? this.detailInfo : (this.loadedDetails.get(place.title) || null),
        breakpoint: this.currentBreakpoint,
        isLoading: index === this.currentIndex ? this.isLoading : false
      })

      // 顶部返回按钮
      Row() {
        Image($r('app.media.ic_arrow_back'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
        Text('景点详情')
          .fontColor('#ddd')

      }
      .onClick(() => {
        router.back();
      })
      .position({ x: 0, y: 0 })
      .padding({ left: 20, top: 28 })
      .zIndex(10)
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Swiper(this.swiperController) {
      ForEach(this.placeList, (place: PlaceDetailParams, index: number) => {
        this.DetailView(place, index)
      })
    }
    .index(this.currentIndex)
    .width('100%')
    .height('100%')
    .loop(false)
    .indicator(false)
    .onChange((index: number) => {
      this.handleIndexChange(index);
    })
  }
}

@Component
struct PlaceCard {
  @Prop place: PlaceDetailParams;
  @Prop detailInfo: AttractionDetail | null;
  @Prop breakpoint: string; // 'sm', 'md', 'lg'
  @Prop isLoading: boolean;
  
  @State isHovering: boolean = false;
  @State isLiked: boolean = false;
  @State isButtonLoading: boolean = false;

  aboutToAppear() {
    this.checkLikeStatus();
  }

  async checkLikeStatus() {
    try {
      this.isLiked = await RdbManager.getInstance().isLiked(this.place.id, 'place');
    } catch (e) {
      console.error('Check like status failed', e);
    }
  }

  async toggleLike() {
    try {
      // 1. Save place if needed (since PlaceDetailParams might not be in saved_place DB)
      let targetId = this.place.id;
      if (!targetId || targetId === 0) {
        // Save place first
        targetId = await RdbManager.getInstance().savePlace(this.place as DbPlace);
      }

      if (targetId && targetId > 0) {
        const liked = await RdbManager.getInstance().toggleLike(targetId, 'place');
        this.isLiked = liked;
        if (liked) {
          promptAction.showToast({ message: '已添加到我的点赞' });
        } else {
          promptAction.showToast({ message: '已取消点赞' });
        }
      }
    } catch (e) {
      console.error('Toggle like failed', e);
    }
  }

  // =================================================================
  // MODIFIABLE AREA START - 用户可自定义样式区域
  // =================================================================
  // 1. 尺寸与圆角 (对应 .card-container, .card)
  private readonly cardStyle: CardStyle = {
    width: '80%', // 宽度 (width: 90vw)
    height: '80%', // 高度 (height: 90vh)
    radius: 16, // 圆角半径 (border-radius: 16px)
    bgColor: Color.Transparent, // 背景色 (background-color: transparent)
  };
  // 2. 布局与间距 (对应 .content-wrapper)
  private readonly layoutStyle: LayoutStyle = {
    padding: 24, // 内边距
    textBtnGap: 24, // 文字与按钮间距 (margin-bottom: 24px)
    titleAlign: TextAlign.Start // 标题对齐 (text-align: left)
  };

  // =================================================================
  // MODIFIABLE AREA END
  // =================================================================

  // 响应式辅助方法 (保留以备后续扩展)
  private getTitleSize(): number {
    switch (this.breakpoint) {
      case 'sm':
        return 24; // 移动端稍微调大
      case 'md':
        return 28;
      case 'lg':
        return 32;
      default:
        return 24;
    }
  }

  async handleInfoClick() {
      if (this.detailInfo) {
         router.pushUrl({
             url: 'pages/AttractionInfoPage',
             params: { detail: this.detailInfo, title: this.place.title }
         });
         return;
      }

      // If not loaded, show loading state
      this.isButtonLoading = true;
      try {
        // Wait for data (Assuming AIService handles concurrent requests correctly via cache/active request)
        const details = await AIService.getInstance().getAttractionDetails(this.place.title);
        if (details) {
            router.pushUrl({
                url: 'pages/AttractionInfoPage',
                params: { detail: details, title: this.place.title }
            });
        } else {
             promptAction.showToast({ message: '获取详情失败，请重试' });
        }
      } catch (e) {
         promptAction.showToast({ message: '网络请求失败' });
      } finally {
         // Keep loading animation for at least 300ms as per requirement
         setTimeout(() => {
             this.isButtonLoading = false;
         }, 300);
      }
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      // 卡片主图
      Image($r('app.media.background11'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .borderRadius(this.cardStyle.radius) // MODIFIABLE: .card border-radius
        .clip(true)

      // 渐变遮罩
      Column()
        .width('100%')
        .height('50%') // 稍微加高遮罩以适应大卡片
        .linearGradient({
          angle: 180,
          colors: [['rgba(0,0,0,0)', 0.0], ['rgba(0,0,0,0.8)', 1.0]]
        })
        .borderRadius({ bottomLeft: this.cardStyle.radius, bottomRight: this.cardStyle.radius })
        .position({ bottom: 0 })

      // 内容区域 (.content-wrapper)
      Column({ space: 12 }) {
        // 标题 (.title)
        Text(this.place.title)
          .fontSize(this.getTitleSize())
          .fontWeight(FontWeight.Bold)
          .fontFamily('HarmonyOS Sans SC')
          .fontColor(Color.White)
          .textAlign(this.layoutStyle.titleAlign) // MODIFIABLE: text-align
          .width('100%')
          .textShadow({ radius: 4, color: 'rgba(0,0,0,0.3)' })

        // 文化介绍文字
        Text(`——"${this.detailInfo?.description || '这是外地旅客必打卡推荐之一它蕴含着丰富的历史文化底蕴，包括...'}"`)
          .fontSize(16)
          .lineHeight(24)
          .fontColor('rgba(255,255,255,0.95)')
          .maxLines(3) // 增加显示行数
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: this.layoutStyle.textBtnGap }) // MODIFIABLE: margin-bottom

        // 底部元数据行
        Row({ space: 12 }) {
          Row() {
            Image($r('app.media.ic_cat_sights'))
              .width(16).height(16).fillColor('rgba(255,255,255,0.9)')
            Text(`${this.place.distanceKm.toFixed(1)}km`)
              .fontSize(14).fontColor('rgba(255,255,255,0.9)')
          }

          Row({ space: 4 }) {
            Text('★')
              .fontSize(16).fontColor('#FFD700')
            Text('4.8')
              .fontSize(14).fontColor('rgba(255,255,255,0.9)')
          }
        }
        .width('100%') // 关键修改点
        .justifyContent(FlexAlign.Start) // 关键修改点
        .margin({ left: 12 }) // 可选：根据需要添加左侧内边距
      }
      .padding(this.layoutStyle.padding) // MODIFIABLE: padding
      .width('100%')
      .position({ bottom: 0 })

      // 新增：点赞按钮（右上角）
      // 替换原收藏功能，使用标准爱心图标（此处复用ic_home_selected并着色，或使用Text符号代替）
      Row() {
         Image(this.isLiked ? $r('app.media.ic_home_selected') : $r('app.media.ic_home_normal'))
           .width(28).height(28)
           .fillColor(this.isLiked ? '#FF4D4F' : 'rgba(255,255,255,0.8)')
           .shadow({ radius: 4, color: 'rgba(0,0,0,0.2)' })
      }
      .padding(10)
      .backgroundColor('rgba(0,0,0,0.2)')
      .backdropBlur(10)
      .borderRadius(24)
      .position({ top: 20, right: 20 })
      .onClick(() => this.toggleLike())
      .zIndex(20)

      // 修改：原位置按钮改为"景点详细信息"
      Row({ space: 4 }) {
        if (this.isButtonLoading) {
             LoadingProgress()
               .width(16).height(16)
               .color(Color.White)
             Text('加载中...')
               .fontSize(14)
               .fontColor(Color.White)
        } else {
            Text('景点详细信息')
              .fontSize(14)
              .fontColor(Color.White)
            Image($r('app.media.ic_arrow_back')) // 旋转作为前进箭头
              .width(16).height(16)
              .fillColor(Color.White)
              .rotate({ angle: 180 })
        }
      }
      .backgroundColor('rgba(255,255,255,0.2)')
      .backdropBlur(20)
      .borderRadius(20)
      .padding({
        left: 16,
        right: 12,
        top: 8,
        bottom: 8
      })
      .position({ bottom: this.layoutStyle.padding, right: this.layoutStyle.padding }) // 跟随内边距
      .border({ width: 0.5, color: 'rgba(255,255,255,0.3)' })
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetY: 2 })
      .onClick(() => {
        if (!this.isButtonLoading) {
            this.handleInfoClick();
        }
      })

    }
    // 卡片容器样式 (.card-container)
    .width(this.cardStyle.width) // MODIFIABLE: width
    .height(this.cardStyle.height) // MODIFIABLE: height
    .borderRadius(this.cardStyle.radius) // MODIFIABLE: border-radius
    .backgroundColor(this.cardStyle.bgColor) // MODIFIABLE: background-color
    .shadow({
      radius: this.isHovering ? 20 : 12,
      color: 'rgba(0,0,0,0.15)',
      offsetY: this.isHovering ? 8 : 4
    })
    .scale({ x: this.isHovering ? 1.01 : 1.0, y: this.isHovering ? 1.01 : 1.0 }) // 减小缩放幅度以适应大卡片
    .animation({ duration: 300, curve: Curve.EaseOut })
    .onHover((isHover: boolean) => {
      this.isHovering = isHover;
    })
  }
}
