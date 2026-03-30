### 新建行程重构方案（这是其他ai综合给的思路，他的语法写得不规范有写法错误，不满足ArtsCheck的强规范性，我们借鉴他的思路，但是要符合ArtsCheck的规范）
一、先明确结论：你用到的 MapKit API + 定位服务 完全能实现所有需求
你卡壳的核心是「景点数据跨页面共享 + 地图标记联动」没做好，而非 API 能力不足。下面我给你一套 完整可运行的代码方案，从「全局数据层→页面布局→功能逻辑」全链路解决，包含：
地图初始化 + 默认定位
景点搜索→添加到行程列表
行程列表交互（弹窗详情 / 点赞 / 分组）
手动 / AI 排序
地图渲染景点 + 最优路径轨迹
二、前置准备（必做，解决权限 / 依赖问题）
1. 配置 module.json5 权限（地图 / 定位必须）
json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": ["phone"],
    "deliveryWithInstall": true,
    "installationFree": false,
    "requestPermissions": [
      { "name": "ohos.permission.INTERNET" }, // 地图/搜索需要
      { "name": "ohos.permission.LOCATION" }, // 定位需要
      { "name": "ohos.permission.LOCATION_IN_BACKGROUND" } // 后台定位
    ]
  }
}
2. 确认 MapKit 配置（解决之前权限报错）
AGC 平台已配置「包名 + SHA256 指纹」；
DevEco Studio 已配置签名证书（和 AGC 一致）；
项目 build-profile.json5 已引入 MapKit 依赖（SDK 4.0+）。
三、核心实现：分 4 个文件完成所有功能
文件 1：全局数据管理（解决跨页面共享，关键！）
新建 model/TravelPlanModel.ets，用 @StorageLink 实现行程数据全局共享（你之前添加景点失败就是没做全局数据）：
typescript
运行
import { LatLng } from '@kit.MapKit';

// 景点数据模型（统一类型，避免any）
export interface ScenicSpot {
  id: string; // 唯一标识
  name: string; // 景点名
  address: string; // 地址
  latLng: LatLng; // 经纬度（地图渲染核心）
  category: string; // 分组（自然/人文/美食）
  isLiked: boolean; // 点赞状态
  desc: string; // 景点详情
}

// 全局行程数据（跨页面同步）
@StorageLink('travelPlanList') export let travelPlanList: ScenicSpot[] = [];
// 全局当前定位
@StorageLink('currentLatLng') export let currentLatLng: LatLng = { latitude: 0, longitude: 0 };

// 手动排序：交换列表元素
export function swapScenicSpot(index1: number, index2: number) {
  const temp = travelPlanList[index1];
  travelPlanList[index1] = travelPlanList[index2];
  travelPlanList[index2] = temp;
}

// AI智能排序：按「当前位置→景点距离由近到远」排序（模拟，可扩展算法）
export function aiSortScenicSpot() {
  if (currentLatLng.latitude === 0 || travelPlanList.length < 2) return;
  // 计算两点距离（简化版经纬度距离公式）
  const getDistance = (lat1: number, lng1: number, lat2: number, lng2: number) => {
    const radLat1 = Math.PI * lat1 / 180;
    const radLat2 = Math.PI * lat2 / 180;
    const a = radLat1 - radLat2;
    const b = Math.PI * lng1 / 180 - Math.PI * lng2 / 180;
    return 6378137 * Math.acos(Math.cos(radLat1) * Math.cos(radLat2) * Math.cos(b) + Math.sin(radLat1) * Math.sin(radLat2));
  };
  // 按距离排序
  travelPlanList.sort((a, b) => {
    const disA = getDistance(currentLatLng.latitude, currentLatLng.longitude, a.latLng.latitude, a.latLng.longitude);
    const disB = getDistance(currentLatLng.latitude, currentLatLng.longitude, b.latLng.latitude, b.latLng.longitude);
    return disA - disB;
  });
}
文件 2：主行程页面（核心页面，地图 + 列表）
新建 pages/TravelPlanPage.ets，实现「上地图 + 下列表」布局，包含所有交互：
typescript
运行
import map from '@kit.MapKit';
import mapCommon from '@kit.MapKitCommon';
import navi from '@kit.MapKitNavigation';
import geolocation from '@ohos.geolocation';
import router from '@ohos.router';
import {
  travelPlanList, currentLatLng, ScenicSpot,
  swapScenicSpot, aiSortScenicSpot
} from '../model/TravelPlanModel';

@Entry
@Component
struct TravelPlanPage {
  // 地图控制器（交互核心）
  private mapController: map.MapController = new map.MapController();
  // 弹窗控制：景点详情
  @State isDetailDialogShow: boolean = false;
  @State currentSpot: ScenicSpot | null = null;
  // 分组筛选
  @State activeCategory: string = '全部';
  private categories: string[] = ['全部', '自然', '人文', '美食'];
  // 路径规划结果
  @State naviPath: navi.NavigationResult | null = null;

  // 页面加载：初始化定位+地图
  async aboutToAppear() {
    await this.getLocation(); // 获取当前定位
    this.initMap(); // 初始化地图
  }

  // 1. 获取当前定位（默认定位）
  async getLocation() {
    try {
      const location = await geolocation.getCurrentLocation({
        coordinateType: geolocation.CoordinateType.COORDINATE_TYPE_WGS84, // 和MapKit坐标系一致
        timeout: 5000
      });
      currentLatLng = {
        latitude: location.latitude,
        longitude: location.longitude
      };
      // 地图定位到当前位置
      this.mapController.setCenter(currentLatLng, true);
      this.mapController.setZoom(14, true);
    } catch (e) {
      console.error('定位失败:', e);
      // 定位失败默认设为北京（测试用）
      currentLatLng = { latitude: 39.908823, longitude: 116.397470 };
    }
  }

  // 2. 初始化地图（绑定交互按钮）
  initMap() {
    // 开启地图交互（缩放/拖拽）
    this.mapController.enableScroll(true);
    this.mapController.enableZoom(true);
    this.mapController.enableRotate(true);
  }

  // 3. 渲染地图标记（行程列表联动）
  buildMapMarkers() {
    return travelPlanList.map((spot) => {
      return map.Marker({
        position: spot.latLng,
        title: spot.name,
        icon: '/images/marker_icon.png', // 自定义标记图标（自己放图片）
        onClick: () => {
          this.currentSpot = spot;
          this.isDetailDialogShow = true;
        }
      });
    });
  }

  // 4. 路径规划：生成最优轨迹
  async generateNaviPath() {
    if (travelPlanList.length < 2) return;
    // 路径点：当前位置 → 排序后的景点列表
    const wayPoints = [currentLatLng, ...travelPlanList.map(spot => spot.latLng)];
    try {
      const result = await navi.calculateRoute({
        startPoint: wayPoints[0],
        endPoint: wayPoints[wayPoints.length - 1],
        wayPoints: wayPoints.slice(1, -1), // 中间景点
        routeType: navi.RouteType.ROUTE_TYPE_DRIVING // 驾车（可改步行/公交）
      });
      this.naviPath = result;
      // 地图渲染轨迹
      this.mapController.addPolyline({
        points: result.points,
        width: 8,
        color: '#1677FF',
        zIndex: 10
      });
    } catch (e) {
      console.error('路径规划失败:', e);
    }
  }

  // 5. 筛选分组景点
  getFilteredSpots() {
    if (this.activeCategory === '全部') return travelPlanList;
    return travelPlanList.filter(spot => spot.category === this.activeCategory);
  }

  build() {
    Column() {
      // 上半部分：地图区域
      RelativeContainer() {
        // 地图组件
        map.Map({
          controller: this.mapController,
          center: currentLatLng,
          zoom: 14,
          uiSettings: {
            zoomControlsVisible: false, // 隐藏默认缩放按钮（自定义）
            myLocationButtonVisible: false // 隐藏默认定位按钮（自定义）
          }
        })
          .width('100%')
          .height('50%')
          .markers(this.buildMapMarkers()) // 绑定景点标记
          .onReady(() => console.log('地图加载完成'));

        // 地图交互按钮：定位复位
        Button('🔄')
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor('#FFFFFF')
          .position({ left: 16, bottom: 16 })
          .onClick(() => {
            this.mapController.setCenter(currentLatLng, true); // 回到当前位置
            this.mapController.setZoom(14, true);
          });

        // 地图交互按钮：缩放+
        Button('+')
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor('#FFFFFF')
          .position({ left: 16, bottom: 62 })
          .onClick(() => this.mapController.setZoom(this.mapController.getZoom() + 1, true));

        // 地图交互按钮：缩放-
        Button('-')
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor('#FFFFFF')
          .position({ left: 16, bottom: 108 })
          .onClick(() => this.mapController.setZoom(this.mapController.getZoom() - 1, true));

        // 右上角：保存按钮
        Button('保存行程')
          .width(80)
          .height(32)
          .borderRadius(16)
          .backgroundColor('#1677FF')
          .fontColor('#FFFFFF')
          .position({ right: 16, top: 16 })
          .onClick(() => {
            // 保存逻辑：可存本地数据库/文件，这里模拟
            console.log('行程保存成功:', travelPlanList);
            promptAction.showToast({ message: '行程保存成功' });
          });
      }
      .width('100%')
      .height('50%');

      // 下半部分：行程列表区域
      Column() {
        // 分组筛选按钮
        Row({ space: 8 }) {
          ForEach(this.categories, (category) => {
            Button(category)
              .backgroundColor(this.activeCategory === category ? '#1677FF' : '#F5F7FA')
              .fontColor(this.activeCategory === category ? '#FFFFFF' : '#333333')
              .borderRadius(16)
              .onClick(() => this.activeCategory = category);
          });
        }
        .padding(8)
        .width('100%')
        .backgroundColor('#FFFFFF');

        // 排序按钮（手动/AI）
        Row({ space: 8 }) {
          Button('手动排序')
            .backgroundColor('#F5F7FA')
            .borderRadius(16)
            .onClick(() => {
              // 手动排序：开启列表拖拽（下面List已配置）
              promptAction.showToast({ message: '可拖拽调整顺序' });
            });
          Button('AI智能排序')
            .backgroundColor('#1677FF')
            .fontColor('#FFFFFF')
            .borderRadius(16)
            .onClick(() => {
              aiSortScenicSpot(); // AI排序
              this.generateNaviPath(); // 重新生成路径
              promptAction.showToast({ message: '已按距离排序' });
            });
        }
        .padding(8)
        .width('100%');

        // 行程景点列表（可拖拽排序）
        List({ space: 4 }) {
          ForEach(this.getFilteredSpots(), (spot, index) => {
            ListItem() {
              Row({ space: 8 }) {
                Image('/images/spot_default.png') // 景点默认图
                  .width(60)
                  .height(60)
                  .borderRadius(8);
                Column({ space: 4 }) {
                  Text(spot.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium);
                  Text(spot.address)
                    .fontSize(12)
                    .fontColor('#999999')
                    .maxLines(1)
                    .width('180');
                }
                .flexGrow(1);
                // 点赞按钮
                Button(spot.isLiked ? '❤️' : '♡')
                  .fontSize(20)
                  .width(40)
                  .height(40)
                  .backgroundColor('transparent')
                  .onClick(() => {
                    travelPlanList[index].isLiked = !travelPlanList[index].isLiked;
                  });
                // 删除按钮
                Button('🗑️')
                  .width(40)
                  .height(40)
                  .backgroundColor('transparent')
                  .onClick(() => {
                    travelPlanList.splice(index, 1);
                    this.generateNaviPath(); // 删除后重新生成路径
                  });
              }
              .padding(8)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .onClick(() => {
                this.currentSpot = spot;
                this.isDetailDialogShow = true;
              });
            })
            .editable(true) // 开启拖拽排序
            .onDragStart((event) => event.data.set('index', index.toString()))
            .onDragEnter((event) => {
              const fromIndex = parseInt(event.data.get('index') as string);
              const toIndex = index;
              if (fromIndex !== toIndex) {
                swapScenicSpot(fromIndex, toIndex); // 交换位置
                this.generateNaviPath(); // 排序后重新生成路径
              }
            });
          });
        }
        .height('60%')
        .backgroundColor('#F5F7FA');

        // 底部：添加景点按钮
        Button('+ 添加景点')
          .width('90%')
          .height(48)
          .backgroundColor('#1677FF')
          .fontColor('#FFFFFF')
          .borderRadius(24)
          .margin(16)
          .onClick(() => {
            // 跳转到搜索景点页面
            router.pushUrl({ url: 'pages/SearchPlacePage' });
          });
      }
      .width('100%')
      .flexGrow(1)
      .backgroundColor('#F5F7FA');

      // 景点详情弹窗
      if (this.isDetailDialogShow && this.currentSpot) {
        Dialog() {
          Column({ space: 16 }) {
            Image('/images/spot_detail.png') // 景点详情图
              .width('100%')
              .height(120)
              .borderRadius(8);
            Text(this.currentSpot.name)
              .fontSize(20)
              .fontWeight(FontWeight.Bold);
            Text(this.currentSpot.desc)
              .fontSize(14)
              .fontColor('#666666');
            Text(`地址：${this.currentSpot.address}`)
              .fontSize(12)
              .fontColor('#999999');
            Button('关闭')
              .width('100%')
              .height(40)
              .backgroundColor('#1677FF')
              .fontColor('#FFFFFF')
              .borderRadius(8)
              .onClick(() => this.isDetailDialogShow = false);
          }
          .padding(16)
          .width('80%');
        }
        .overlay(this.isDetailDialogShow)
        .onDisappear(() => this.currentSpot = null);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA');
  }
}
文件 3：景点搜索页面（添加景点到行程）
新建 pages/SearchPlacePage.ets，调用 MapKit 的 site 搜索 API，实现「搜索→添加」：
typescript
运行
import site from '@kit.MapKitSite';
import router from '@ohos.router';
import { travelPlanList, ScenicSpot } from '../model/TravelPlanModel';

@Entry
@Component
struct SearchPlacePage {
  @State searchText: string = ''; // 搜索关键词
  @State searchResult: site.SearchResult[] = []; // 搜索结果
  @State isLoading: boolean = false; // 加载状态

  // 调用MapKit Site搜索API
  async searchScenicSpot() {
    if (!this.searchText.trim()) return;
    this.isLoading = true;
    try {
      const result = await site.search({
        keyword: this.searchText,
        region: { // 限定搜索区域（当前城市，可改）
          latitude: 39.908823,
          longitude: 116.397470,
          radius: 10000 // 10公里内
        },
        pageSize: 20,
        pageNum: 1
      });
      this.searchResult = result;
    } catch (e) {
      console.error('搜索失败:', e);
      promptAction.showToast({ message: '搜索失败，请重试' });
    } finally {
      this.isLoading = false;
    }
  }

  // 添加景点到行程列表
  addToPlan(spot: site.SearchResult) {
    const newSpot: ScenicSpot = {
      id: Date.now().toString(), // 唯一ID
      name: spot.name,
      address: spot.address || '暂无地址',
      latLng: {
        latitude: spot.location.latitude,
        longitude: spot.location.longitude
      },
      category: '自然', // 默认分类，可后续修改
      isLiked: false,
      desc: spot.description || '暂无介绍'
    };
    travelPlanList.push(newSpot); // 加入全局行程列表
    promptAction.showToast({ message: `已添加${spot.name}到行程` });
    router.back(); // 返回主页面
  }

  build() {
    Column() {
      // 搜索栏
      Row({ space: 8 }) {
        TextInput({ placeholder: '输入景点名搜索' })
          .value(this.searchText)
          .onChange((value) => this.searchText = value)
          .onSubmit(() => this.searchScenicSpot())
          .padding(8)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .flexGrow(1);
        Button('搜索')
          .backgroundColor('#1677FF')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .onClick(() => this.searchScenicSpot());
      }
      .padding(8)
      .width('100%')
      .backgroundColor('#F5F7FA');

      // 搜索结果列表
      if (this.isLoading) {
        Text('加载中...')
          .padding(20)
          .width('100%');
      } else {
        List({ space: 4 }) {
          ForEach(this.searchResult, (spot) => {
            ListItem() {
              Column({ space: 4 }) {
                Text(spot.name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium);
                Text(spot.address || '暂无地址')
                  .fontSize(12)
                  .fontColor('#999999');
                Row({ space: 8 }) {
                  Button('添加到行程')
                    .backgroundColor('#1677FF')
                    .fontColor('#FFFFFF')
                    .borderRadius(8)
                    .onClick(() => this.addToPlan(spot));
                  Button('查看地图')
                    .backgroundColor('#F5F7FA')
                    .borderRadius(8)
                    .onClick(() => {
                      // 拉起Petal Maps（可选）
                      petalMaps.openMap({
                        latitude: spot.location.latitude,
                        longitude: spot.location.longitude,
                        name: spot.name
                      });
                    });
                }
                .padding(4)
                .alignItems(Alignment.End)
                .width('100%');
              }
              .padding(8)
              .backgroundColor('#FFFFFF')
              .borderRadius(8);
            };
          });
        }
        .height('100%')
        .backgroundColor('#F5F7FA');
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA');
  }
}
文件 4：路由配置（main_pages.json）
确保页面路由已配置：
json
{
  "pages": [
    "pages/TravelPlanPage",
    "pages/SearchPlacePage"
  ]
}
四、核心问题解决（你卡壳的关键）
搜索景点添加到行程失败：
用 @StorageLink 全局共享 travelPlanList，搜索页 addToPlan 方法 push 新景点后，主页面列表自动刷新；
景点模型统一包含 latLng 经纬度，为地图渲染提供核心数据。
地图渲染不出坐标：
主页面 buildMapMarkers 方法遍历 travelPlanList，为每个景点生成 MapKit Marker；
定位初始化时确保坐标系和 MapKit 一致（WGS84）。
景点排序后地图更新：
手动 / AI 排序后调用 generateNaviPath 重新生成路径，地图 Polyline 轨迹自动更新；
拖拽排序通过 swapScenicSpot 交换列表元素，联动地图标记顺序。
五、运行验证步骤
把代码复制到对应文件，补充图片资源（marker_icon.png/spot_default.png 等）；
确保手机已开启定位 + USB 调试，连接 DevEco Studio；
运行 TravelPlanPage，先定位到当前位置；
点击「添加景点」→ 搜索景点（如 “故宫”）→ 点击「添加到行程」；
返回主页面，能看到景点列表，地图上显示标记；
点击「AI 智能排序」→ 生成最优路径轨迹；
点击景点标记 / 列表项，弹出详情弹窗。
六、扩展优化（可选）
景点分组可手动编辑（当前默认 “自然”，可加弹窗修改）；
点赞状态持久化（存本地数据库）；
AI 排序可扩展为「游玩时间 + 距离」综合排序；
地图标记可自定义不同分类的图标；
行程保存可存到鸿蒙本地数据库（RdbStore）。