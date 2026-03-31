/**
 * @file Index.ets
 * @brief 首页主页面
 * @description 首页Tab容器，包含Banner、功能入口、推荐行程等模块
 * @see TopBarBuilder, BannerViewBuilder, FeatureGridBuilder, TripFeedBuilder, CreateTripDialog, TripRepository
 */
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { MineComponent } from '../view/MineComponent';
import { CreateTripDialog } from '../view/CreateTripDialog';
import { TripRepository } from '../repository/TripRepository';
import { Trip } from '../model/TripModel';
import { PlaceDetailParams } from './PlaceDetailPage';
import { BannerItem, FunctionalCardItem, UserTripItem } from '../common/types/CommonTypes';
import { Logger } from '../utils/Logger';
import { TopBarBuilder } from '../view/index/TopBarBuilder';
import { BannerViewBuilder } from '../view/index/BannerViewBuilder';
import { FeatureGridBuilder } from '../view/index/FeatureGridBuilder';
import { TripFeedBuilder } from '../view/index/TripFeedBuilder';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @StorageLink('isLogin') isLogin: boolean = false;
  private tripRepository: TripRepository = new TripRepository();
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CreateTripDialog({
      confirm: (name: string, location: string) => this.saveTrip(name, location)
    }),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: 0 },
    customStyle: false,
    autoCancel: true
  });

  async saveTrip(name: string, location: string): Promise<void> {
    try {
      const trip: Trip = {
        id: null,
        name: name,
        location: location,
        startDate: Date.now(),
        status: 'planning',
        createTime: Date.now(),
        updateTime: Date.now()
      };
      const newTripId = await this.tripRepository.insert(trip);
      trip.id = newTripId;
      promptAction.showToast({ message: '行程创建成功' });
      router.pushUrl({
        url: 'pages/NewTripPage'
      });

    } catch (e) {
      Logger.error('Index', 'Create trip failed', e);
      promptAction.showToast({ message: '创建失败' });
    }
  }

  // @deprecated: 首页推荐数据应从后端API获取，参见 TripService.getRecommendedTrips()
  // @see resources/rawfile/mock-config.json banners[]
  @State banners: BannerItem[] = [
    {
      id: 1,
      imageSrc: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?q=80&w=1000&auto=format&fit=crop',
      title: '瑞士阿尔卑斯山'
    },
    {
      id: 2,
      imageSrc: 'https://images.unsplash.com/photo-1493246507139-91e8fad9978e?q=80&w=1000&auto=format&fit=crop',
      title: '马尔代夫群岛'
    },
    {
      id: 3,
      imageSrc: 'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?q=80&w=1000&auto=format&fit=crop',
      title: '意大利五渔村'
    }
  ];

  // 四大功能模块 - 青春活力配色
  @State functionalCards: FunctionalCardItem[] = [
    {
      id: 1,
      title: '新建行程',
      icon: $r('app.media.ic_func_new_trip'),
      colors: [[0x4FACFE, 0.0], [0x00F2FE, 1.0]],
      shadowColor: 'rgba(79, 117, 254, 0.40)'
    },
    {
      id: 2,
      title: '新建笔记',
      icon: $r('app.media.ic_func_notes'),
      colors: [[0xFFA07A, 0.0], [0xFF6B6B, 1.0]],
      shadowColor: 'rgba(255, 107, 107, 0.4)'
    },
    {
      id: 3,
      title: '旅游建议',
      icon: $r('app.media.ic_func_advice'),
      colors: [[0x667eea, 0.0], [0x764ba2, 1.0]],
      shadowColor: 'rgba(118, 75, 162, 0.4)'
    },
    {
      id: 4,
      title: '最近行程',
      icon: $r('app.media.ic_func_recent'),
      colors: [[0x43e97b as ResourceColor, 0.0], [0x38f9d7 as ResourceColor, 1.0]],
      shadowColor: 'rgba(56, 249, 215, 0.4)'
    }
  ];

  // @deprecated: 用户推荐列表应从后端API获取
  // @see resources/rawfile/mock-config.json sampleTrips[]
  @State userTrips: UserTripItem[] = [
    {
      id: 1,
      userName: 'Alex',
      userAvatar: 'https://img.icons8.com/color/48/user-male-circle--v1.png',
      imageSrc: 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?q=80&w=600&auto=format&fit=crop',
      title: '夏威夷冲浪之旅',
      date: '2023.12.20',
      location: '夏威夷, 美国',
      likes: 128
    },
    {
      id: 2,
      userName: 'Sarah',
      userAvatar: 'https://img.icons8.com/color/48/user-female-circle--v1.png',
      imageSrc: 'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?q=80&w=600&auto=format&fit=crop',
      title: '威尼斯水城漫步',
      date: '2024.01.05',
      location: '威尼斯, 意大利',
      likes: 256
    },
    {
      id: 3,
      userName: 'Mike',
      userAvatar: 'https://img.icons8.com/color/48/user-male-circle--v1.png',
      imageSrc: 'https://images.unsplash.com/photo-1476900543704-4312b78632f8?q=80&w=600&auto=format&fit=crop',
      title: '徒步阿尔卑斯',
      date: '2023.11.15',
      location: '因特拉肯, 瑞士',
      likes: 89
    }
  ];
  @Builder
  TabBuilder(title: string, index: number, selectedImg: ResourceStr, normalImg: ResourceStr): void {
    Column() {
      Image(this.currentIndex === index ? selectedImg : normalImg)
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')

    Text(title)
      .fontColor(this.currentIndex === index ? '#007DFF' : '#999')
      .fontSize(10)
      .margin({ top: 4 })
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        Column() {
          TopBarBuilder()

          Scroll() {
            Column() {
              BannerViewBuilder({ banners: this.banners })
              FeatureGridBuilder({
                functionalCards: this.functionalCards,
                onCreateTrip: (): void => this.dialogController.open()
              })
              Text('发现精彩行程')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
                .padding({ left: 20, top: 30, bottom: 16 })
              TripFeedBuilder({ userTrips: this.userTrips })
            }
            .width('100%')
            .padding({ bottom: 20 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.app_bg'))
      }
      .tabBar(this.TabBuilder('首页', 0, $r('app.media.ic_home_selected'), $r('app.media.ic_home_normal')))

      TabContent() {
        MineComponent()
      }
      .tabBar(this.TabBuilder('我的', 1, $r('app.media.ic_mine_selected'), $r('app.media.ic_mine_normal')))
    }
    .onChange((index) => {
      this.currentIndex = index;
    })
    .scrollable(false)
  }
}
