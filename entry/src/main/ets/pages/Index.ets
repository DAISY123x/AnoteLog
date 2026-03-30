import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { MineComponent } from '../view/MineComponent';
import { CreateTripDialog } from '../view/CreateTripDialog';
import { RdbManager } from '../common/database/RdbManager';
import { Trip } from '../model/TripModel';
import { PlaceDetailParams } from './PlaceDetailPage';

// 定义数据模型
interface BannerItem {
  id: number;
  imageSrc: string;
  title: string;
}

interface FunctionalCardItem {
  id: number;
  title: string;
  icon: ResourceStr;
  colors: [ResourceColor, number][];
  shadowColor: string;
}

interface UserTripItem {
  id: number;
  userName: string;
  userAvatar: string;
  imageSrc: string;
  title: string;
  date: string;
  location: string;
  likes: number;
}

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  // 使用 StorageLink 实现跨页面状态共享
  @StorageLink('isLogin') isLogin: boolean = false;
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
      const newTripId = await RdbManager.getInstance().insertTrip(trip);
      promptAction.showToast({ message: '行程创建成功' });
      // Navigate to NewTripPage for creation flow
      router.pushUrl({
        url: 'pages/NewTripPage'
      });

    } catch (e) {
      console.error('Create trip failed', e);
      promptAction.showToast({ message: '创建失败' });
    }
  }

  // 必玩推荐景点 (轮播图)
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
      // 鲜艳的蓝青渐变
      colors: [[0x4FACFE, 0.0], [0x00F2FE, 1.0]],
      shadowColor: 'rgba(79, 117, 254, 0.40)'
    },
    {
      id: 2,
      title: '新建笔记',
      icon: $r('app.media.ic_func_notes'),
      // 温暖的橙红渐变
      colors: [[0xFFA07A, 0.0], [0xFF6B6B, 1.0]],
      shadowColor: 'rgba(255, 107, 107, 0.4)'
    },
    {
      id: 3,
      title: '旅游建议',
      icon: $r('app.media.ic_func_advice'),
      // 梦幻的紫粉渐变
      colors: [[0x667eea, 0.0], [0x764ba2, 1.0]],
      shadowColor: 'rgba(118, 75, 162, 0.4)'
    },
    {
      id: 4,
      title: '最近行程',
      icon: $r('app.media.ic_func_recent'),
      // 清新的绿青渐变
      colors: [[0x43e97b as ResourceColor, 0.0], [0x38f9d7 as ResourceColor, 1.0]],
      shadowColor: 'rgba(56, 249, 215, 0.4)'
    }
  ];
  // 用户行程推荐列表
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

  @Styles
  cardPressed() {
    .scale({ x: 0.96, y: 0.96 })
  }

  @Styles
  cardNormal() {
    .scale({ x: 1, y: 1 })
  }

  // TabBuilder
  @Builder
  TabBuilder(title: string, index: number, selectedImg: ResourceStr, normalImg: ResourceStr) {
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
      // 首页 Tab
      TabContent() {
        Column() {
          // 1. 顶部状态栏区域 (Search + Login)
          this.TopBar()

          Scroll() {
            Column() {
              // 2. 必玩推荐 (Banner)
              this.BannerView()

              // 3. 核心功能 (四宫格)
              this.FeatureGrid()

              // 4. 推荐列表标题
              Text('发现精彩行程')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
                .padding({ left: 20, top: 30, bottom: 16 })

              // 5. 推荐列表 (用户行程)
              this.TripFeed()
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

      // 我的 Tab
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

  @Builder
  TopBar() {
    Row() {
      // 搜索按钮 - 胶囊样式
      Row() {
        Image($r('app.media.ic_search'))
          .width(18)
          .height(18)
          .fillColor($r('app.color.search_icon'))
          .margin({ right: 8 })
        Text('搜索目的地/景点')
          .fontSize(14)
          .fontColor($r('app.color.text_tertiary'))
      }
      .height(40)
      .layoutWeight(1) // 占据剩余空间
      .backgroundColor($r('app.color.search_bg'))
      .border({ width: 1, color: $r('app.color.search_border') })
      .borderRadius(20)
      .padding({ left: 16 })
      .shadow({ radius: 10, color: 'rgba(0, 125, 255, 0.10)', offsetY: 2 })
      .onClick(() => {
        router.pushUrl({ url: 'pages/SearchPage' });
      })

      // 登录/注册按钮
      if (!this.isLogin) {
        Button('登录 / 注册')
          .height(36)
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#007DFF')
          .borderRadius(18)
          .margin({ left: 16 })
          .onClick(() => {
            // 跳转到登录页
            router.pushUrl({ url: 'pages/LoginPage' });
          })
          .shadow({ radius: 8, color: 'rgba(0, 125, 255, 0.3)', offsetY: 2 })
      } else {
        Image('https://img.icons8.com/color/48/user-male-circle--v1.png')
          .width(40)
          .height(40)
          .borderRadius(20)
          .margin({ left: 16 })
          .border({ width: 2, color: Color.White })
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)', offsetY: 2 })
          .onClick(() => {
            this.currentIndex = 1; // 跳转到我的 Tab
          })
      }
    }
    .width('100%')
    .padding({
      left: 20,
      right: 20,
      top: 12,
      bottom: 12
    })
  }

  @Builder
  BannerView() {
    Column() {
      Text('必玩推荐')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ left: 20, bottom: 16, top: 8 })
        .width('100%')

      Swiper() {
        ForEach(this.banners, (item: BannerItem) => {
          Stack({ alignContent: Alignment.BottomStart }) {
            Image(item.imageSrc)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .borderRadius(20)
              .backgroundColor('#E0E0E0')
              .alt($r('app.media.ic_placeholder'))

            // 渐变遮罩
            Column()
              .width('100%')
              .height('50%')
              .linearGradient({
                angle: 180,
                colors: [['rgba(0,0,0,0)', 0], ['rgba(0,0,0,0.7)', 1]]
              })
              .borderRadius({ bottomLeft: 20, bottomRight: 20 })

            Text(item.title)
              .fontColor(Color.White)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 20, bottom: 20 })
              .textShadow({ radius: 4, color: 'rgba(0,0,0,0.5)' })
          }
          .width('100%')
          .height(220)
          .padding({ left: 20, right: 20 })
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.1)', offsetY: 4 })
          .onClick(() => {
            // Construct Place List from Banners
            const placeList = this.banners.map((b, idx) => ({
              id: b.id,
              title: b.title,
              type: 'sights',
              distanceKm: 0,
              durationMin: 120,
              latitude: 0,
              longitude: 0,
              note: b.title
            } as PlaceDetailParams));

            router.pushUrl({
              url: 'pages/PlaceDetailPage',
              params: {
                placeList: placeList,
                initialIndex: this.banners.indexOf(item)
              }
            });
          })
        })
      }
      .autoPlay(true)
      .interval(4000)
      .indicator(
        Indicator.dot()
          .itemWidth(6)
          .itemHeight(6)
          .selectedItemWidth(24)
          .selectedItemHeight(6)
          .color('rgba(255,255,255,0.4)')
          .selectedColor(Color.White)
          .bottom(12)
      )
    }
    .margin({ top: 8 })
  }

  @Builder
  FeatureGrid() {
    Column() {
      Row() {
        Text('核心功能')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))

        Blank()

        Row() {
          Text('查看更多')
            .fontSize(14)
            .fontColor($r('app.color.text_tertiary'))
          Image($r('app.media.ic_cat_more'))
            .width(14)
            .height(14)
            .fillColor($r('app.color.icon_secondary'))
            .margin({ left: 4 })
        }
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        bottom: 16,
        top: 30
      })

      Grid() {
        ForEach(this.functionalCards, (item: FunctionalCardItem) => {
          GridItem() {
            Stack({ alignContent: Alignment.TopStart }) {
              // 1. 背景层
              Column()
                .width('100%')
                .height('100%')
                .linearGradient({ angle: 135, colors: item.colors })
                .borderRadius(20)
                .shadow({ radius: 10, color: item.shadowColor, offsetY: 6 })

              // 2. 装饰图案 (大圆环)
              Circle()
                .width(100)
                .height(100)
                .fill('rgba(255,255,255,0.1)')
                .position({ x: -30, y: -30 })

              // 3. 装饰图案 (小圆点)
              Circle()
                .width(20)
                .height(20)
                .fill('rgba(255,255,255,0.2)')
                .position({ x: '80%', y: '70%' })

              // 4. 内容层
              Column() {
                // 图标容器
                Column() {
                  Image(item.icon)
                    .width(32)
                    .height(32)
                    .objectFit(ImageFit.Contain)
                    .fillColor(Color.White)
                }
                .width(56)
                .height(56)
                .borderRadius(28)
                .backgroundColor('rgba(255,255,255,0.2)')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)

                Blank()

                Text(item.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .letterSpacing(1)
              }
              .width('100%')
              .height('100%')
              .padding(16)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .height(140) // 增加高度
            .stateStyles({
              pressed: this.cardPressed,
              normal: this.cardNormal
            })
            .animation({ duration: 200 })
            .onClick(() => {
              if (item.id === 1) { // 新建行程
                this.dialogController.open();
              } else if (item.id === 2) { // 旅游笔记
                router.pushUrl({ url: 'pages/NoteListPage' });
              } else if (item.id === 3) { // 旅游建议
                router.pushUrl({ url: 'pages/AdvicePage' });
              } else if (item.id === 4) { // 最近行程
                router.pushUrl({ url: 'pages/RecentTripsPage' });
              } else {
                promptAction.showToast({ message: item.title + ' 功能开发中' });
              }
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(16)
      .rowsGap(16)
      .height(296) // 140*2 + 16 gap
      .padding({ left: 20, right: 20 })
    }
  }

  @Builder
  TripFeed() {
    List({ space: 20 }) {
      ForEach(this.userTrips, (item: UserTripItem) => {
        ListItem() {
          Column() {
            // 大图
            Image(item.imageSrc)
              .width('100%')
              .height(200)
              .objectFit(ImageFit.Cover)
              .borderRadius({ topLeft: 16, topRight: 16 })
              .backgroundColor('#E0E0E0')
              .alt($r('app.media.ic_placeholder'))

            // 内容区
            Column() {
              Text(item.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Row() {
                Image($r('app.media.ic_cat_sights'))
                  .width(14)
                  .height(14)
                  .fillColor('#007DFF')
                  .margin({ right: 4 })
                Text(item.location)
                  .fontSize(13)
                  .fontColor('#666')

                Blank()

                Text(item.date)
                  .fontSize(12)
                  .fontColor('#999')
              }
              .width('100%')
              .margin({ top: 8, bottom: 16 })

              // 底部用户信息栏
              Row() {
                Image(item.userAvatar)
                  .width(32)
                  .height(32)
                  .borderRadius(16)
                  .margin({ right: 8 })
                  .border({ width: 1, color: '#EEE' })

                Text(item.userName)
                  .fontSize(14)
                  .fontColor('#333')
                  .fontWeight(FontWeight.Medium)

                Blank()

                Row() {
                  Image($r('app.media.ic_home_normal'))
                    .width(18)
                    .height(18)
                    .fillColor('#FF5E62')
                  Text(item.likes.toString())
                    .fontSize(13)
                    .fontColor('#666')
                    .margin({ left: 6 })
                }
                .backgroundColor('#FFF0F0')
                .padding({
                  left: 10,
                  right: 10,
                  top: 6,
                  bottom: 6
                })
                .borderRadius(14)
              }
              .width('100%')
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius({ bottomLeft: 16, bottomRight: 16 })
          }
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.06)', offsetY: 4 })
          .onClick(() => {
            // Construct Place List from UserTrips
            const placeList = this.userTrips.map((t) => ({
              id: t.id,
              title: t.title,
              type: 'sights',
              distanceKm: 0,
              durationMin: 0,
              latitude: 0,
              longitude: 0,
              note: t.location
            } as PlaceDetailParams));

            router.pushUrl({
              url: 'pages/PlaceDetailPage',
              params: {
                placeList: placeList,
                initialIndex: this.userTrips.indexOf(item)
              }
            });
          })
        }
      })
    }
    .padding({ left: 20, right: 20, bottom: 30 })
  }
}
