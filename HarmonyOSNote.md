### map官方地图示例功能
### MapComponentCotroller

MapComponentController
支持设备PhonePC/2in1TabletWearable
地图的主要功能入口类，与地图有关的所有方法从此处接入。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

示例：

import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct HuaweiMapDemo {
  private TAG = "HuaweiMapDemo";
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;

  aboutToAppear(): void {
    // 地图初始化参数，设置地图中心点坐标及层级
    this.mapOptions = {
      position: {
        target: {
          latitude: 39.9,
          longitude: 116.4
        },
        zoom: 10
      }
    };

    // 地图初始化的回调
    this.callback = async (err, mapController) => {
      if (!err) {
        // 获取地图的控制器类，用来操作地图
        this.mapController = mapController;
        // 返回地图组件的监听事件管理接口
        this.mapEventManager = this.mapController.getEventManager();
        let callback = () => {
          console.info(this.TAG, `on-mapLoad`);
        }
        this.mapEventManager.on("mapLoad", callback);

        // 执行自定义的方法
        this.customizedMethod();
      }
    };
  }

  // 自定义的方法
  private customizedMethod() {
    // ...
  }

  build() {
    Stack() {
      // 调用MapComponent组件初始化地图
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('100%')
    }.height('100%')
  }
}
说明
MapComponentController中的方法需要放在上述示例的地图初始化的回调中运行或自定义的方法中运行。

animateCamera
支持设备PhonePC/2in1TabletWearable
animateCamera(update: CameraUpdate, duration?: number): void

在指定的持续时间内以动画的形式更新相机状态。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

update

CameraUpdate

是

相机状态将要发生的变化。

duration

number

否

动画的持续时间，单位：ms，默认值为250，取值范围：大于0，小于等于0按照默认值处理。

示例：

let target: mapCommon.LatLng = {
  latitude: 39.9,
  longitude: 116.4
};
let cameraPosition: mapCommon.CameraPosition = {
  target: target,
  zoom: 10
};
// 新建CameraUpdate对象
let cameraUpdate: map.CameraUpdate = map.newCameraPosition(cameraPosition);
// 在1000ms内以动画的形式移动相机
this.mapController.animateCamera(cameraUpdate, 1000);
animateCameraStatus
支持设备PhonePC/2in1TabletWearable
animateCameraStatus(update: CameraUpdate, duration?: number): Promise<AnimateResult>

在指定的持续时间内以动画的形式更新相机状态，并返回动画结果。使用Promise异步回调。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本5.0.0(12)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：5.0.0(12)

参数：

参数名

类型

必填

说明

update

CameraUpdate

是

相机状态将要发生的变化。

duration

number

否

动画的持续时间，单位：ms，默认值为250，取值范围：大于0，小于等于0按照默认值处理。

返回值：

类型

说明

Promise<AnimateResult>

Promise对象，返回AnimateResult。

错误码：

以下错误码的详细介绍请参见ArkTS API错误码。

错误码ID

错误信息

401

Invalid input parameter.

示例：

let target: mapCommon.LatLng = {
  latitude: 39.9,
  longitude: 116.4
};
let cameraPosition: mapCommon.CameraPosition = {
  target: target,
  zoom: 10
};
// 新建CameraUpdate对象
let cameraUpdate: map.CameraUpdate = map.newCameraPosition(cameraPosition);
// 在1000ms内以动画的形式移动相机
let animateResult = await this.mapController.animateCameraStatus(cameraUpdate, 1000);
animateCameraWithMarker
支持设备PhonePC/2in1TabletWearable
animateCameraWithMarker(update: CameraUpdate, marker: Marker, duration: number): Promise<AnimateResult>

在指定的持续时间内以动画的形式更新相机状态，并更新指定的marker。使用Promise异步回调。相机移动过程中不能被打断，否则AnimateResult的参数isCanceled返回值为true。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本5.0.0(12)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：5.0.0(12)

参数：

参数名

类型

必填

说明

update

CameraUpdate

是

相机状态将要发生的变化。

marker

Marker

是

标记。

duration

number

是

动画的持续时间，单位：ms，默认值为250，取值范围：大于0，小于等于0按照默认值处理。

返回值：

类型

说明

Promise<AnimateResult>

Promise对象，返回AnimateResult。

示例：

let target: mapCommon.LatLng = {
  latitude: 39.9,
  longitude: 116.4
};
let cameraPosition: mapCommon.CameraPosition = {
  target: target,
  zoom: 10
};
// 新建CameraUpdate对象
let cameraUpdate: map.CameraUpdate = map.newCameraPosition(cameraPosition);
// marker初始化参数
let markerOptions: mapCommon.MarkerOptions = {
  position: {
    latitude: 39.9,
    longitude: 116.4
  },
  title: "dhw",
  // 图标需存放在resources/rawfile目录下
  icon: 'icon/icon.png',
  clickable: true
};
// 新建marker
let marker = await this.mapController?.addMarker(markerOptions);
// 在1000ms内以动画的形式移动相机, 并更新指定的marker
await this.mapController.animateCameraWithMarker(cameraUpdate, marker, 1000);
animateCameraWithMarkers
支持设备PhonePC/2in1TabletWearable
animateCameraWithMarkers(update: CameraUpdate, markers: Array<Marker>, duration: number): Promise<AnimateResult>

在指定的持续时间内以动画的形式更新相机状态，并更新传入的marker，支持传一组标记。使用Promise异步回调。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本5.0.0(12)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：5.0.0(12)

参数：

参数名

类型

必填

说明

update

CameraUpdate

是

相机状态将要发生的变化。

markers

Array<Marker>

是

一组标记。

说明
一组标记的位置必须相同，否则会返回401错误码。

duration

number

是

动画的持续时间，单位：ms，默认值为250，取值范围：大于0，小于等于0按照默认值处理。

返回值：

类型

说明

Promise<AnimateResult>

Promise对象，返回AnimateResult。

错误码：

以下错误码的详细介绍请参见ArkTS API错误码。

错误码ID

错误信息

401

Invalid input parameter.

示例：

let target: mapCommon.LatLng = {
  latitude: 39.9,
  longitude: 116.4
};
let cameraPosition: mapCommon.CameraPosition = {
  target: target,
  zoom: 10
};
// 新建CameraUpdate对象
let cameraUpdate: map.CameraUpdate = map.newCameraPosition(cameraPosition);
// marker1初始化参数
let markerOptions1: mapCommon.MarkerOptions = {
  position: {
    latitude: 31.984410259206815,
    longitude: 118.76625379397866
  },
  title: "icon",
  // 图标需存放在resources/rawfile目录下
  icon: 'icon/icon.png',
  clickable: true
};
let markerOptions2: mapCommon.MarkerOptions = {
  position: {
    latitude: 31.984410259206815,
    longitude: 118.76625379397866
  },
  title: "avocado",
  // 图标需存放在resources/rawfile目录下
  icon: 'icon/avocado.png',
  clickable: true,
  anchorU: 0.5,
  anchorV: 1
};
let marker1 = await this.mapController?.addMarker(markerOptions1);
// marker2初始化参数
let marker2 = await this.mapController?.addMarker(markerOptions2);
// 在1000ms内以动画的形式移动相机, 并更新指定的marker
await this.mapController.animateCameraWithMarkers(cameraUpdate, [marker1, marker2], 1000);
stopAnimation
支持设备PhonePC/2in1TabletWearable
stopAnimation(): void

停止当前执行的改变地图状态的动画。调用该方法时，相机立即停止移动并保持在该位置。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

示例：

this.mapController.stopAnimation();
clear
支持设备PhonePC/2in1TabletWearable
clear(): void

移除地图上所有的圆、标记、折线等覆盖物。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

示例：

this.mapController.clear();
moveCamera
支持设备PhonePC/2in1TabletWearable
moveCamera(update: CameraUpdate): void

更新相机状态。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

update

CameraUpdate

是

相机状态将要发生的变化。

示例：

let target: mapCommon.LatLng = {
  latitude: 39.9,
  longitude: 116.4
};
let cameraPosition: mapCommon.CameraPosition = {
  target: target,
  zoom: 10
};
// 新建CameraUpdate对象
let cameraUpdate: map.CameraUpdate = map.newCameraPosition(cameraPosition);
// 移动相机
this.mapController.moveCamera(cameraUpdate);
getCameraPosition
支持设备PhonePC/2in1TabletWearable
getCameraPosition(): mapCommon.CameraPosition

获取相机的当前状态信息。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

返回值：

类型

说明

mapCommon.CameraPosition

相机的当前状态信息。

示例：

let cameraPosition: mapCommon.CameraPosition = this.mapController.getCameraPosition();
setLatLngBounds
支持设备PhonePC/2in1TabletWearable
setLatLngBounds(bounds: mapCommon.LatLngBounds): void

指定一个mapCommon.LatLngBounds来约束相机目标，使用户移动地图时，相机目标不会移出此边界。当设置新的边界时，新边界将覆盖之前设置的边界。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

bounds

mapCommon.LatLngBounds

是

约束相机目标的边界。

说明
西南角纬度大于东北角纬度时不生效。

示例：

let bounds:mapCommon.LatLngBounds = {
  northeast: {
    latitude: 31,
    longitude: 118
  },
  southwest: {
    latitude: 30,
    longitude: 117
  }
};
this.mapController.setLatLngBounds(bounds);
setPointToCenter
支持设备PhonePC/2in1TabletWearable
setPointToCenter(point: mapCommon.MapPoint): void

将屏幕上的像素位置设置为地图的中心点。使用此方法后，地图将根据设置的屏幕坐标进行缩放和旋转。异常值不处理。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

point

mapCommon.MapPoint

是

屏幕坐标点。

示例：

let point: mapCommon.MapPoint = {
  positionX: 1000,
  positionY: 1000
};
this.mapController.setPointToCenter(point);
setMaxZoom
支持设备PhonePC/2in1TabletWearable
setMaxZoom(maxZoom: number): void

设置相机最大缩放级别。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

maxZoom

number

是

相机最大缩放级别，取值范围：[2, 20]。

传入的值大于20，最大缩放级别会取20。

传入的值小于2，最大缩放级别会取2。

在取值范围内，传入的值小于当前minZoom，最大缩放级别和最小缩放级别都会被设置为当前传入的值。

示例：

this.mapController.setMaxZoom(10);
setMinZoom
支持设备PhonePC/2in1TabletWearable
setMinZoom(minZoom: number): void

设置相机最小缩放级别。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

minZoom

number

是

相机最小缩放级别，取值范围：[2, 20]。

传入的值大于20，最小缩放级别会取20。

传入的值小于2，最小缩放级别会取2。

在取值范围内，传入的值大于当前maxZoom，最大缩放级别和最小缩放级别都会被设置为当前传入的值。

示例：

this.mapController.setMinZoom(3); 
getMaxZoom
支持设备PhonePC/2in1TabletWearable
getMaxZoom(): number

获取相机最大缩放级别。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

返回值：

类型

说明

number

相机最大缩放级别。

示例：

let maxZoom: number = this.mapController.getMaxZoom(); 
getMinZoom
支持设备PhonePC/2in1TabletWearable
getMinZoom(): number

获取相机最小缩放级别。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

返回值：

类型

说明

number

相机最小缩放级别。

示例：

let minZoom: number = this.mapController.getMinZoom(); 
setTrafficEnabled
支持设备PhonePC/2in1TabletWearable
setTrafficEnabled(enabled: boolean): void

打开或关闭路况图层。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

enabled

boolean

是

true：打开路况图层
false：关闭路况图层
默认值为false。

示例：

this.mapController.setTrafficEnabled(true);  
isTrafficEnabled
支持设备PhonePC/2in1TabletWearable
isTrafficEnabled(): boolean

获取路况图层开启状态。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

返回值：

类型

说明

boolean

true：路况图层为开启状态
false：路况图层为关闭状态
示例：

let isTrafficEnabled: boolean = this.mapController.isTrafficEnabled(); 


### maker :
导入模块
支持设备PhonePC/2in1TabletWearable
import { map, mapCommon } from '@kit.MapKit';
Marker
支持设备PhonePC/2in1TabletWearable
标记，继承BaseOverlay。在调用map.MapComponentController类的addMarker方法时会返回该类型的实例。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

示例：

let markerOptions: mapCommon.MarkerOptions = {
  position: {
    latitude: 39.9,
    longitude: 116.4
  }
};
let marker: map.Marker = await this.mapController.addMarker(markerOptions);
getTitle
支持设备PhonePC/2in1TabletWearable
getTitle(): string

返回信息窗的标题。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

返回值：

类型

说明

string

信息窗的标题。

示例：

let title: string = marker.getTitle();
getSnippet
支持设备PhonePC/2in1TabletWearable
getSnippet(): string

返回信息窗的子标题。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

返回值：

类型

说明

string

信息窗的子标题。

示例：

let snippet: string = marker.getSnippet();
getAlpha
支持设备PhonePC/2in1TabletWearable
getAlpha(): number

获取标记的透明度。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

返回值：

类型

说明

number

标记的透明度，取值范围：[0, 1]。

示例：

let alpha: number = marker.getAlpha();
getPosition
支持设备PhonePC/2in1TabletWearable
getPosition(): mapCommon.LatLng

获取标记的位置。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

返回值：

类型

说明

mapCommon.LatLng

标记的位置。

示例：

let position: mapCommon.LatLng = marker.getPosition();
getRotation
支持设备PhonePC/2in1TabletWearable
getRotation(): number

获取标记的旋转角度。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

返回值：

类型

说明

number

标记的旋转角度。

示例：

let rotation: number = marker.getRotation();
isClickable
支持设备PhonePC/2in1TabletWearable
isClickable(): boolean

获取标记是否可以点击。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

返回值：

类型

说明

boolean

标记是否可以点击。

true：可以
false：不可以
示例：

let isClickable: boolean = marker.isClickable();
isDraggable
支持设备PhonePC/2in1TabletWearable
isDraggable(): boolean

获取标记是否可以通过长按来拖拽。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

返回值：

类型

说明

boolean

标记是否可以通过长按来拖拽。

true：可以
false：不可以
示例：

let isDraggable: boolean = marker.isDraggable();
isFlat
支持设备PhonePC/2in1TabletWearable
isFlat(): boolean

获取标记是否平贴地图。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

返回值：

类型

说明

boolean

标记是否平贴地图。

true：平贴地图
false：面对相机
示例：

let isFlat: boolean = marker.isFlat();

### mapcommon模块用法：
MapCommon模块用法总结
MapCommon模块是HarmonyOS Map Kit（地图服务）的核心组成部分，主要用于配置地图的初始化属性。它通过MapOptions接口定义地图的初始状态，确保开发者能快速设置地图参数。以下是关键用法：

核心接口：MapCommon.MapOptions
用于初始化地图属性，包括位置、缩放级别等。
主要属性：
position.target：设置地图中心点的经纬度坐标（如{ latitude: 39.9, longitude: 116.4 }）。
zoom：控制地图的缩放级别（例如zoom: 10）。
使用步骤：
导入相关模块：import { MapComponent, mapCommon, map } from '@kit.MapKit';1
定义MapOptions对象并传入MapComponent组件。
通过回调函数获取地图控制器（MapComponentController）以操作地图。 示例代码片段（基于搜索结果）：
aboutToAppear(): void {
  this.mapOptions = {
    position: {
      target: {
        latitude: 39.9,  // 纬度
        longitude: 116.4 // 经度
      },
      zoom: 10  // 缩放级别
    }
  };
}
在旅游攻略应用中的真实业务举例
在旅游类应用中，MapCommon模块常用于实现位置展示、导航等交互功能，提升用户体验。以下是基于旅行规划场景的典型应用：

业务场景：旅行行程地图视图
功能描述：用户在旅行规划App中，点击“地图”按钮切换至地图视图，实时查看行程位置（如景点、酒店）。基于Map Kit实现地图渲染、位置标记和路径规划。
真实实现：
使用MapOptions设置当前行程的经纬度（如从行程数据中动态获取）。
结合状态管理（如@State变量），当用户切换行程时，更新MapOptions的position.target以刷新地图中心点。
示例交互：在旅行应用中（如搜索结果中的案例），用户点击左侧行程列表项，地图自动定位到该行程的位置。
关键优势：
快速初始化地图，减少加载时间。
支持动态更新位置，适用于多行程切换。
结合路径规划（Map Kit的导航功能），帮助用户规划园区路线（如旅游园区应用中的导航到特定项目点）。

### navi路径规划
navi模块是HarmonyOS Map Kit（地图服务）的导航功能模块，主要用于计算和显示地图上的路径。它提供了驾车、步行、骑行等多种路径规划方式，帮助开发者在地图应用中实现导航功能。以下是navi模块的核心API及用法。

### 一、navi模块核心API及用法

驾车路径规划（getDrivingRoutes）1

import { navi } from '@kit.MapKit';

// 设置规划参数
const params: navi.DrivingRouteParams = {
  origins: [{ latitude: 39.992281, longitude: 116.31088 }], // 起点
  destination: { latitude: 39.94, longitude: 116.311 },    // 终点
  wayPoints: [                                             // 途经点（最多5个）
    { latitude: 39.995, longitude: 116.305 },
    { latitude: 39.98, longitude: 116.308 }
  ]
};

// 执行路径规划
try {
  const result = await navi.getDrivingRoutes(params);
  console.log("规划结果:", result.routes.steps);  // 取最优路线
} catch (err) {
  console.error("规划失败:", err.code);  // 处理错误码
}
步行路径规划（getWalkingRoutes）

const params: navi.RouteParams = {
  origins: [{ latitude: 39.992281, longitude: 116.31088 }],
  destination: { latitude: 39.94, longitude: 116.311 }  // 限制150公里内
};

const result = await navi.getWalkingRoutes(params);
骑行路径规划（getCyclingRoutes）

const result = await navi.getCyclingRoutes(params);
二、路径渲染到地图的关键步骤
获取路径坐标点

let points: Array<map.LatLng> = [];
result.routes.steps.forEach(step => {
  step.roads.forEach(road => {
    points = points.concat(road.polyline);  // 提取所有路径点
  });
});

// 路径点抽稀优化（提升性能）
if (points.length >= 1000) {
  points = points.filter((_, index) => index % 50 === 0);
} else {
  points = points.filter((_, index) => index % 2 === 0);
}
地图绘制折线

import { map } from '@kit.MapKit';

// 创建折线对象
const polylineOption: map.PolylineOptions = {
  points: points,
  color: '#FF0000',
  width: 8
};

// 添加到地图
const mapPolyline = await mapController.addPolyline(polylineOption);
三、多景点规划最佳实践

景点排序优化

先通过site.searchByText获取景点坐标
使用TSP算法（需自行实现）计算最优访问顺序
将排序后的景点作为wayPoints传入API
分段规划策略

// 当景点>6个时分段处理
const batchSize = 5;  // 最大途经点数
for (let i = 0; i < spots.length; i += batchSize) {
  const segment = spots.slice(i, i + batchSize + 1);
  const params = {
    origins: [segment],
    destination: segment[segment.length - 1],
    wayPoints: segment.slice(1, -1)
  };
  await navi.getDrivingRoutes(params);
}
四、必备配置
权限声明（module.json5）

"requestPermissions": [
  { "name": "ohos.permission.INTERNET" },
  { "name": "ohos.permission.APPROXIMATELY_LOCATION" }
]
地图服务开通

在AppGallery Connect中启用地图服务
配置API密钥和签名
注意事项：

路径规划需在Stage模型下使用（FA模型不支持）
单次调用最多返回3条路线，优先取routes作为最优路径
跨区域规划会报错1002602002
点距超限错误码1002602004（驾车无距离限制，步行限150公里）
### 原官方navi文档
getDrivingRoutes
支持设备PhonePC/2in1TabletWearable
getDrivingRoutes(params: DrivingRouteParams): Promise<RouteResult>

规划两个地点之间的驾车路线。使用Promise异步回调。

说明
每次调用最多可以返回3条路径。
最多可以指定5个途经点。
模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

params

DrivingRouteParams

是

驾车路径规划的参数。

返回值：

类型

说明

Promise<RouteResult>

Promise对象，返回RouteResult。
示例代码：
let params: navi.DrivingRouteParams = {
  origins: [{
    "latitude": 31.9821213545843,
    "longitude": 120.27745557768591
  }],
  destination: {
    "latitude": 31.983545843,
    "longitude": 120.27745557768591
  },
  waypoints: [
    { "latitude": 31.967236140819114, "longitude": 120.27142088866847 },
    { "latitude": 31.972868002238872, "longitude": 120.2943211817165 },
    { "latitude": 31.98469327973332, "longitude": 120.29101107384068 }
  ],
  language: "zh_CN"
};
const result = await navi.getDrivingRoutes(params);
console.info("Succeeded in getting driving routes.");
getDrivingRoutes
支持设备PhonePC/2in1TabletWearable
getDrivingRoutes(context: common.Context, params: DrivingRouteParams): Promise<RouteResult>

规划两个地点之间的驾车路线，支持传入Context上下文。使用Promise异步回调。

说明
每次调用最多可以返回3条路径。
最多可以指定5个途经点。
模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本5.0.0(12)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：5.0.0(12)

参数：

参数名

类型

必填

说明

context

common.Context

是

Context上下文。

params

DrivingRouteParams

是

驾车路径规划的参数。

返回值：

类型

说明

Promise<RouteResult>

Promise对象，返回RouteResult。
示例代码：
let params: navi.DrivingRouteParams = {
  origins: [{
    "latitude": 31.982129213545843,
    "longitude": 120.27745557768591
  }],
  destination: {
    "latitude": 31.9821213545843,
    "longitude": 120.277557768591
  },
  waypoints: [
    { "latitude": 31.967236140819114, "longitude": 120.27142088866847 },
    { "latitude": 31.972868002238872, "longitude": 120.2943211817165 },
    { "latitude": 31.98469327973332, "longitude": 120.29101107384068 }
  ],
  language: "zh_CN"
};
const result = await navi.getDrivingRoutes(this.getUIContext().getHostContext(), params);
console.info("Succeeded in getting driving routes.");
getWalkingRoutes
支持设备PhonePC/2in1TabletWearable
getWalkingRoutes(params: RouteParams): Promise<RouteResult>

规划两个地点之间的步行路线。使用Promise异步回调。

说明
只能规划直线距离150公里内的两个地点步行路线。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

params

RouteParams

是

步行路径规划的参数。

返回值：

类型

说明

Promise<RouteResult>

Promise对象，返回RouteResult。
示例代码：
let params: navi.RouteParams = {
  origins: [
    { "latitude": 39.992281, "longitude": 116.31088 },
    { "latitude": 39.996, "longitude": 116.311 }
  ],
  destination: {
    "latitude": 39.94,
    "longitude": 116.311
  },
  language: "zh_CN"
};
const result = await navi.getWalkingRoutes(params);
console.info("Succeeded in getting walking routes.");
getWalkingRoutes
支持设备PhonePC/2in1TabletWearable
getWalkingRoutes(context: common.Context, params: RouteParams): Promise<RouteResult>

规划两个地点之间的步行路线，支持传入Context上下文。使用Promise异步回调。

说明
只能在直线距离150公里内规划步行路线。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本5.0.0(12)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：5.0.0(12)

参数：

参数名

类型

必填

说明

context

common.Context

是

Context上下文。

params

RouteParams

是

步行路径规划的参数。

返回值：

类型

说明

Promise<RouteResult>

Promise对象，返回RouteResult。
getTransitRoutes
支持设备PhonePC/2in1TabletWearable
getTransitRoutes(context: common.Context, params: TransitRouteParams): Promise<TransitRouteResult>

规划两地之间的中转路线，仅支持中国大陆。支持传入Context上下文，使用Promise异步回调。

说明
非同城起点和终点的直线距离不超过100km，同城不限制距离。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本5.1.1(19)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：5.1.1(19)

参数：

参数名

类型

必填

说明

context

common.Context

是

Context上下文。

params

TransitRouteParams

是

中转路线规划的参数。

返回值：

类型

说明

Promise<TransitRouteResult>

Promise对象，返回TransitRouteResult。
示例代码：
let params: navi.TransitRouteParams = {
  "origin": { "latitude": 39.921619, "longitude": 116.356587 },
  "destination": { "latitude": 39.94161, "longitude": 116.353621 },
  "departureTime": new Date().getTime() / 1000
};
const result = await navi.getTransitRoutes(this.getUIContext().getHostContext(), params);
console.info("Succeeded in getting transit routes.");
### site(地点搜索)
### 地点搜索接口
1. searchByText关键字搜索功能：通过关键字查询地点（如景点、企业等），支持指定地理范围1。 🔹 基础版本 (API 4.1.0+)

import { site } from '@kit.MapKit';

let params: site.SearchByTextParams = {
  query: "北京大学",          // 必填：搜索关键字
  location: {                // 可选：中心点坐标
    latitude: 39.9042, 
    longitude: 116.4074
  },
  radius: 5000,              // 可选：搜索半径（单位：米）
  language: "zh"             // 可选：返回结果语言
};

site.searchByText(params)
  .then((result: site.SearchByTextResult) => {
    console.info("搜索结果:", result);
  })
  .catch((error: BusinessError) => {
    console.error("搜索失败，错误码:", error.code);
  });
🔹 扩展版本 (API 5.0.0+)支持传入 Context上下文：

site.searchByText(context, params)  // context 从 Ability 获取
  .then((result) => { /* 处理结果 */ });
⚠️ 关键约束

模型限制：仅支持 Stage 模型。
权限要求：需申请地图权限（ohos.permission.LOCATION）。
错误码处理：
401：参数无效（如 query为空）。
1002603001：无搜索结果。
1002600004：未启用地图权限（检查权限配置）。
📍 2. 参数与返回值详解

🔸 SearchByTextParams结构
字段	类型	必填	说明
query	string	✓	搜索关键字（如地址）
location	{ latitude: number; longitude: number }	✗	中心点经纬度
radius	number	✗	搜索半径（米）
language	string	✗	语言代码（如 "en"）
🔸 SearchByTextResult返回结构
包含地点列表，每个地点对象含：

name：地点名称
address：详细地址
location：经纬度坐标
distance：距中心点距离（若有 location参数）
📍 3. 使用场景示例

🔹 旅游景点搜索
const params = {
  query: "故宫",
  location: { latitude: 39.9138, longitude: 116.3914 },
  radius: 3000
};
🔹 企业/学校查询

const params = {
  query: "清华大学",
  language: "en"  // 返回英文结果
};
⚠️ 4. 注意事项

版本兼容性：
基础版需 HarmonyOS 4.1.0(11)+
扩展版需 HarmonyOS 5.0.0(12)+
网络依赖：需设备联网调用 Map Kit 服务。
语言支持：若未指定 language，默认使用系统语言。
性能优化：高频调用时建议缓存结果，避免重复请求。
💡 最佳实践

错误兜底：捕获 Promise异常并提示用户：
.catch((error) => {
  if (error.code === 1002603001) {
    console.warn("未找到相关地点");
  }
});
结果过滤：对返回的 SearchByTextResult按 distance排序，优先展示最近地点。
完整文档请查阅 DevEco Studio 内置 API 参考
### 原官方文档写法
searchByText
支持设备PhonePC/2in1TabletWearable
searchByText(searchByTextParams: SearchByTextParams): Promise<SearchByTextResult>

通过指定的关键字和可选的地理范围，查询诸如旅游景点、企业和学校之类的地点。使用Promise异步回调。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

searchByTextParams

SearchByTextParams

是

关键字搜索的参数。

返回值：

类型

说明

Promise<SearchByTextResult>

Promise对象，返回SearchByTextResult。
示例代码：
let params: site.SearchByTextParams = {
  query: "Piazzale Dante, 41, 55049 Viareggio, Tuscany, Italy",
  location: {
    latitude: 31.984410259206815,
    longitude: 118.76625379397866
  },
  radius: 10000,
  language: "en"
};
const result = await site.searchByText(params);
console.info("Succeeded in searching by text.");
searchByText
支持设备PhonePC/2in1TabletWearable
searchByText(context: common.Context, searchByTextParams: SearchByTextParams): Promise<SearchByTextResult>

通过指定的关键字和可选的地理范围，查询诸如旅游景点、企业和学校之类的地点，支持传入Context上下文。使用Promise异步回调。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本5.0.0(12)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：5.0.0(12)

参数：

参数名

类型

必填

说明

context

common.Context

是

Context上下文。

searchByTextParams

SearchByTextParams

是

关键字搜索的参数。

返回值：

类型

说明

Promise<SearchByTextResult>

Promise对象，返回SearchByTextResult。
示例代码：
let params: site.SearchByTextParams = {
  query: "Piazzale Dante, 41, 55049 Viareggio, Tuscany, Italy",
  location: {
    latitude: 31.984410259206815,
    longitude: 118.76625379397866
  },
  radius: 10000,
  language: "en"
};
const result = await site.searchByText(this.getUIContext().getHostContext(), params);
console.info("Succeeded in searching by text.");
nearbySearch
支持设备PhonePC/2in1TabletWearable
nearbySearch(nearbySearchParams: NearbySearchParams): Promise<NearbySearchResult>

通过用户传入自己的位置，可以返回周边地点列表。您可以通过提供关键字或指定要搜索的地点的类型来优化搜索结果。使用Promise异步回调。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

nearbySearchParams

NearbySearchParams

是

周边搜索的参数。

返回值：

类型

说明

Promise<NearbySearchResult>

Promise对象，返回NearbySearchResult。
示例代码：
let params: site.NearbySearchParams = {
  location: {
    latitude:51.50811219132287,
    longitude:-0.07594896472392065
  },
  poiTypes: [
    "Watch_Store",
    "SUBWAY",
    "PRIMARY_SCHOOL",
    "GENERAL_AUTO_REPAIR_SERVICE_CENTER"
  ]
}
// 返回周边搜索结果
const result = await site.nearbySearch(params);
console.info(`Succeeded in searching nearby. result is ${result}`);
nearbySearch
支持设备PhonePC/2in1TabletWearable
nearbySearch(context: common.Context, nearbySearchParams: NearbySearchParams): Promise<NearbySearchResult>

通过用户传入自己的位置，可以返回周边地点列表，支持传入Context上下文。您可以通过提供关键字或指定要搜索的地点的类型来优化搜索结果。使用Promise异步回调。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本5.0.0(12)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：5.0.0(12)

参数：

参数名

类型

必填

说明

context

common.Context

是

Context上下文。

nearbySearchParams

NearbySearchParams

是

周边搜索的参数。

返回值：

类型

说明

Promise<NearbySearchResult>

Promise对象，返回NearbySearchResult。

错误码：

以下错误码的详细介绍请参见ArkTS API错误码。

错误码ID

错误信息

401

Invalid input parameter.

1002600001

System internal error.

1002600002

Failed to connect to the Map Kit server.

1002600003

App authentication failed.

1002600004

The Map permission is not enabled.

1002603001

Zero result.

示例：

let params: site.NearbySearchParams = {
  location: {
    latitude:51.50811219132287,
    longitude:-0.07594896472392065
  },
  poiTypes: [
    "Watch_Store",
    "SUBWAY",
    "PRIMARY_SCHOOL",
    "GENERAL_AUTO_REPAIR_SERVICE_CENTER"
  ]
}
// 返回周边搜索结果
const result = await site.nearbySearch(this.getUIContext().getHostContext(), params);
console.info(`Succeeded in searching nearby. result is ${result}`);
queryAutoComplete
支持设备PhonePC/2in1TabletWearable
queryAutoComplete(queryAutoCompleteParams: QueryAutoCompleteParams): Promise<QueryAutoCompleteResult>

根据输入的关键字返回预测的输入关键字和地点查询建议。使用Promise异步回调。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

queryAutoCompleteParams

QueryAutoCompleteParams

是

自动补全的参数。

返回值：

类型

说明

Promise<QueryAutoCompleteResult>

Promise对象，返回QueryAutoCompleteResult。

错误码：

以下错误码的详细介绍请参见ArkTS API错误码。

错误码ID

错误信息

401

Invalid input parameter.

1002600001

System internal error.

1002600002

Failed to connect to the Map Kit server.

1002600003

App authentication failed.

1002600004

The Map permission is not enabled.

1002603001

Zero result.

示例：

let params: site.QueryAutoCompleteParams = {
  query: "hotel",
  location: {
    latitude: 31.984410259206815,
    longitude: 118.76625379397866
  },
  language: "en",
  isChildren: true
};
const result = await site.queryAutoComplete(params);
console.info("Succeeded in querying.");
queryAutoComplete
支持设备PhonePC/2in1TabletWearable
queryAutoComplete(context: common.Context, queryAutoCompleteParams: QueryAutoCompleteParams): Promise<QueryAutoCompleteResult>

根据输入的关键字返回预测的输入关键字和地点查询建议，支持传入Context上下文。使用Promise异步回调。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本5.0.0(12)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：5.0.0(12)

参数：

参数名

类型

必填

说明

context

common.Context

是

Context上下文。

queryAutoCompleteParams

QueryAutoCompleteParams

是

自动补全的参数。

返回值：

类型

说明

Promise<QueryAutoCompleteResult>

Promise对象，返回QueryAutoCompleteResult。

错误码：

以下错误码的详细介绍请参见ArkTS API错误码。

错误码ID

错误信息

401

Invalid input parameter.

1002600001

System internal error.

1002600002

Failed to connect to the Map Kit server.

1002600003

App authentication failed.

1002600004

The Map permission is not enabled.

1002603001

Zero result.

示例：

let params: site.QueryAutoCompleteParams = {
  query: "hotel",
  location: {
    latitude: 31.984410259206815,
    longitude: 118.76625379397866
  },
  language: "en",
  isChildren: true
};
const result = await site.queryAutoComplete(this.getUIContext().getHostContext(), params);
console.info("Succeeded in querying.");
searchById
支持设备PhonePC/2in1TabletWearable
searchById(searchByIdParams: SearchByIdParams): Promise<SearchByIdResult>

根据地点的唯一主键地点ID获取地点详情。地点详细信息请求返回有关指定地点的更全面的信息，如地点名称、地址详细信息、经纬度等。使用Promise异步回调。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

searchByIdParams

SearchByIdParams

是

地点详情的参数。

返回值：

类型

说明

Promise<SearchByIdResult>

Promise对象，返回SearchByIdResult。

错误码：

以下错误码的详细介绍请参见ArkTS API错误码。

错误码ID

错误信息

401

Invalid input parameter.

1002600001

System internal error.

1002600002

Failed to connect to the Map Kit server.

1002600003

App authentication failed.

1002600004

The Map permission is not enabled.

1002603001

Zero result.

示例：

let params: site.SearchByIdParams = {
  siteId: "144129739873977856",
  language: "en",
  isChildren: true
};
const result = await site.searchById(params);
console.info("Succeeded in searching by id.");
searchById
支持设备PhonePC/2in1TabletWearable
searchById(context: common.Context, searchByIdParams: SearchByIdParams): Promise<SearchByIdResult>

根据地点的唯一主键地点ID获取地点详情。地点详细信息请求返回有关指定地点的更全面的信息，如地点名称、地址详细信息、经纬度等，支持传入Context上下文。使用Promise异步回调。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本5.0.0(12)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：5.0.0(12)

参数：

参数名

类型

必填

说明

context

common.Context

是

Context上下文。

searchByIdParams

SearchByIdParams

是

地点详情的参数。

返回值：

类型

说明

Promise<SearchByIdResult>

Promise对象，返回SearchByIdResult。

错误码：

以下错误码的详细介绍请参见ArkTS API错误码。

错误码ID

错误信息

401

Invalid input parameter.

1002600001

System internal error.

1002600002

Failed to connect to the Map Kit server.

1002600003

App authentication failed.

1002600004

The Map permission is not enabled.

1002603001

Zero result.

示例：

let params: site.SearchByIdParams = {
  siteId: "144129739873977856",
  language: "en",
  isChildren: true
};
const result = await site.searchById(this.getUIContext().getHostContext(), params);
console.info("Succeeded in searching by id.");
geocode
支持设备PhonePC/2in1TabletWearable
geocode(geocodeParams: GeocodeParams): Promise<GeocodeResult>

根据结构化地址获取地点的经纬度。使用Promise异步回调。

说明
根据地址获取地点的空间坐标，如经纬度，最多返回10条记录。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

geocodeParams

GeocodeParams

是

正地理编码的参数。

返回值：

类型

说明

Promise<GeocodeResult>

Promise对象，返回GeocodeResult。

错误码：

以下错误码的详细介绍请参见ArkTS API错误码。

错误码ID

错误信息

401

Invalid input parameter.

1002600001

System internal error.

1002600002

Failed to connect to the Map Kit server.

1002600003

App authentication failed.

1002600004

The Map permission is not enabled.

1002603001

Zero result.

示例：

let params: site.GeocodeParams = {
  "query": "Piazzale Dante, 41, 55049 Viareggio",
  "language": "en"
};
const result = await site.geocode(params);
console.info("Succeeded in geocoding.");
geocode
支持设备PhonePC/2in1TabletWearable
geocode(context: common.Context, geocodeParams: GeocodeParams): Promise<GeocodeResult>

根据结构化地址获取地点的经纬度，支持传入Context上下文。使用Promise异步回调。

说明
根据地址获取地点的空间坐标，如经纬度，最多返回10条记录。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本5.0.0(12)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：5.0.0(12)

参数：

参数名

类型

必填

说明

context

common.Context

是

Context上下文。

geocodeParams

GeocodeParams

是

正地理编码的参数。

返回值：

类型

说明

Promise<GeocodeResult>

Promise对象，返回GeocodeResult。

错误码：

以下错误码的详细介绍请参见ArkTS API错误码。

错误码ID

错误信息

401

Invalid input parameter.

1002600001

System internal error.

1002600002

Failed to connect to the Map Kit server.

1002600003

App authentication failed.

1002600004

The Map permission is not enabled.

1002603001

Zero result.

示例：

let params: site.GeocodeParams = {
  "query": "Piazzale Dante, 41, 55049 Viareggio",
  "language": "en"
};
const result = await site.geocode(this.getUIContext().getHostContext(), params);
console.info("Succeeded in geocoding.");
reverseGeocode
支持设备PhonePC/2in1TabletWearable
reverseGeocode(reverseGeocodeParams: ReverseGeocodeParams): Promise<ReverseGeocodeResult>

逆地理编码接口能够根据经纬度返回对应的地址信息，包括位置描述信息、结构化区划信息、周边POI地点等详细信息。使用Promise异步回调。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本4.1.0(11)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：4.1.0(11)

参数：

参数名

类型

必填

说明

reverseGeocodeParams

ReverseGeocodeParams

是

逆地理编码的参数。

返回值：

类型

说明

Promise<ReverseGeocodeResult>

Promise对象，返回ReverseGeocodeResult。

错误码：

以下错误码的详细介绍请参见ArkTS API错误码。

错误码ID

错误信息

401

Invalid input parameter.

1002600001

System internal error.

1002600002

Failed to connect to the Map Kit server.

1002600003

App authentication failed.

1002600004

The Map permission is not enabled.

1002603001

Zero result.

示例：

let params: site.ReverseGeocodeParams = {
  location: {
    latitude: 31.984410259206815,
    longitude: 118.76625379397866
  },
  language: "en",
  radius: 200
};
const result = await site.reverseGeocode(params);
console.info("Succeeded in reversing geocode.");
reverseGeocode
支持设备PhonePC/2in1TabletWearable
reverseGeocode(context: common.Context, reverseGeocodeParams: ReverseGeocodeParams): Promise<ReverseGeocodeResult>

逆地理编码接口能够根据经纬度返回对应的地址信息，包括位置描述信息、结构化区划信息、周边POI地点等详细信息，支持传入Context上下文。使用Promise异步回调。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本5.0.0(12)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：5.0.0(12)

参数：

参数名

类型

必填

说明

context

common.Context

是

Context上下文。

reverseGeocodeParams

ReverseGeocodeParams

是

逆地理编码的参数。

返回值：

类型

说明

Promise<ReverseGeocodeResult>

Promise对象，返回ReverseGeocodeResult。

错误码：

以下错误码的详细介绍请参见ArkTS API错误码。

错误码ID

错误信息

401

Invalid input parameter.

1002600001

System internal error.

1002600002

Failed to connect to the Map Kit server.

1002600003

App authentication failed.

1002600004

The Map permission is not enabled.

1002603001

Zero result.

示例：

let params: site.ReverseGeocodeParams = {
  location: {
    latitude: 31.984410259206815,
    longitude: 118.76625379397866
  },
  language: "en",
  radius: 200
};
const result = await site.reverseGeocode(this.getUIContext().getHostContext(), params);
console.info("Succeeded in reversing geocode.");
SortRule
支持设备PhonePC/2in1TabletWearable
结果排序规则。

模型约束：此接口仅可在Stage模型下使用。

元服务API：从版本5.0.0(12)开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Map.Core

起始版本：5.0.0(12)

名称

值

说明

COMPOSITE

0

综合排序。

DISTANCE

1
按距离排序。
### staticMap（静态图）
staticMap功能总结
staticMap提供鸿蒙地图静态图生成能力，返回image.PixelMap对象用于UI展示。以下是核心功能及参数详解：

一、核心功能
静态图生成
根据经纬度生成指定尺寸的地图图片
支持自定义缩放级别和分辨率
地图标注
添加标记点（Markers）显示位置
绘制路径（Path）展示路线
样式定制
昼夜模式切换
标记点图标/文字/旋转角度自定义1
二、关键参数（StaticMapOptions）
参数	类型	必填	说明
location	LatLng	✓	中心点坐标 {latitude, longitude}
zoom	number	✓	缩放级别 [2,17]（整数）
imageWidth	number	✓	图片宽度（px）
scale=1时：(0,1024]；scale=2时：(0,512]
imageHeight	number	✓	图片高度（px）约束同上
scale	number		分辨率比例（1或2），默认1
dayNightMode	DayNightMode		昼夜模式（默认Day）
markers	StaticMapMarker[]		标记点数组
path	StaticMapPath		路径绘制参数
三、扩展参数

标记点参数（StaticMapMarker）
{
  location: { latitude, longitude },  // 位置坐标
  icon: 'https://.../icon.png',       // 自定义图标URL（PNG<16KB）
  font: '标记名称',                  // 显示文字（超长显示...）
  fontColor: 0xff000000,             // 文字颜色（ARGB格式）
  rotation: 45,                      // 图标旋转角度[0,360)
  defaultIconSize: IconSize.NORMAL    // 默认图标尺寸
}
路径参数（StaticMapPath）
{
  locations: [ {latitude, longitude}, ... ],  // 路径点数组
  width: 3                                   // 线宽（px）
}
四、代码示例基础用法（无标记）

import { staticMap } from '@kit.MapKit';

let options = {
  location: { latitude: 39.9, longitude: 116.4 },
  zoom: 10,
  imageWidth: 400,
  imageHeight: 400,
  scale: 1
};

staticMap.getMapImage(options)
  .then(pixelMap => {
    // 在Image组件中使用pixelMap
  })
  .catch((err: BusinessError) => {
    console.error(`Error: ${err.code}, ${err.message}`);
  });
进阶用法（标记+路径）

// 定义标记点
let markers = [{
  location: { latitude: 50, longitude: 126.3 },
  font: '商店位置',
  defaultIconSize: staticMap.IconSize.TINY
}];

// 定义路径
let path = {
  locations: [
    { latitude: 50, longitude: 126 },
    { latitude: 50.3, longitude: 126 },
    // ...更多坐标点
  ],
  width: 3
};

// 组合参数
let option = {
  location: { latitude: 50, longitude: 126 },
  zoom: 10,
  imageWidth: 1024,
  imageHeight: 1024,
  markers: markers,
  path: path
};

staticMap.getMapImage(option)
  .then(pixelMap => console.info("生成成功"))
  .catch(error => console.error("失败原因", error));
注意事项
权限要求：需声明ohos.permission.INTERNET
错误处理：捕获BusinessError，常见错误码：
1002600005：网络不可用
1002600003：应用鉴权失败
1002600006：API调用超配额
图标规范：
格式必须为PNG
尺寸≤128x128像素
文件大小<16KB
### 轨迹绑路
场景介绍
从5.1.1(19)开始，支持公共交通规划功能。

提供两点之间驾车、步行、骑行和公共交通的路径规划能力。其中驾车路径规划支持添加途经点。

接口说明
以下是路径规划功能相关接口，主要由navi命名空间下的方法提供，更多接口及使用方法请参见接口文档。

接口名

描述

getDrivingRoutes(params: DrivingRouteParams): Promise<RouteResult>

驾车路径规划。

getDrivingRoutes(context: common.Context, params: DrivingRouteParams): Promise<RouteResult>

驾车路径规划。支持传入Context上下文。

getWalkingRoutes(params: RouteParams): Promise<RouteResult>

步行路径规划。


开发步骤
导入相关模块。
import { navi } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
驾车路径规划
根据起终点坐标检索符合条件的驾车路径规划方案。支持以下功能：

支持一次请求返回多条路线，最多支持3条路线。
最多支持5个途经点。
支持未来出行规划。
支持根据实时路况进行合理路线规划。
支持多种路线偏好选择，如时间最短、避免经过收费的公路、避开高速公路、距离优先等。
async testDrivingRoutes() {
  let params: navi.DrivingRouteParams = {
    // 起点的经纬度
    origins: [{
      latitude: 31.982129213545843,
      longitude: 120.27745557768591
    }],
    // 终点的经纬度
    destination: {
      latitude: 31.986129213545843,
      longitude: 120.32745557768591
    },
    // 路径的途经点
    waypoints: [{
      latitude: 31.967236140819114,
      longitude: 120.27142088866847
    }, {
      latitude: 31.972868002238872,
      longitude: 120.2943211817165
    }, {
      latitude: 31.98469327973332,
      longitude: 120.29101107384068
    }],
    language: 'zh_CN'
  };
  try {
    const result = await navi.getDrivingRoutes(params);
    console.info(`Succeeded in getting driving routes. result is ${JSON.stringify(result)}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed in getting driving routes. Code is ${err.code}, message is ${err.message}`);
  }
}
### 模块API实现地图路线规划参考
基于您的需求，为旅游攻略助手App实现景点管理、地图渲染和路径规划功能，以下是完整的实现方案（结合鸿蒙Map Kit和导航服务）：

一、核心功能实现步骤

1. 景点列表管理
// 景点数据结构
interface Attraction {
  id: string;
  name: string;
  position: mapCommon.LatLng; // {latitude: number, longitude: number}
}

// 景点管理类
class AttractionManager {
  private attractions: Attraction[] = [];

  // 添加景点
  addAttraction(attraction: Attraction) {
    this.attractions.push(attraction);
    this.updateMapMarkers();
  }

  // 更新地图标记
  private async updateMapMarkers() {
    this.clearAllMarkers();
    for (const attr of this.attractions) {
      const marker = await this.mapController?.addMarker({
        position: attr.position,
        title: attr.name
      });
      this.markers.push(marker!);
    }
  }
}
2. 地图渲染与景点标记1

// 初始化地图（参考搜索结果）
aboutToAppear(): void {
  this.callback = async (err, mapController) => {
    this.mapController = mapController;
    this.mapController.on('mapLoad', () => {
      // 加载景点标记
      attractionManager.setMapController(mapController);
    });
  };
}

// 添加标记方法（参考）
public static async addMarker(
  position: mapCommon.LatLng,
  controller: map.MapController
): Promise<mapCommon.Marker> {
  return controller.addMarker({
    position: position,
    icon: $r('app.media.attraction_icon')
  });
}
3. 路径规划与轨迹绑路12
// 路径规划核心方法（参考）
async planRoute(start: Attraction, end: Attraction) {
  const params: navi.RouteParams = {
    origins: [start.position],
    destination: end.position,
    matchType: 3, // 启用轨迹绑路（参考）
    originPoints: this.getUserTrail(), // 获取用户轨迹点
    language: 'zh_CN'
  };

  try {
    const result = await navi.getDrivingRoutes(params);
    this.drawRoute(result.routes.points);
  } catch (err) {
    promptAction.showToast({message: '路径规划失败'});
  }
}

// 轨迹绑路数据准备（参考）
private getUserTrail(): mapCommon.LatLng[] {
  return [
    {latitude: 39.909, longitude: 116.397},
    {latitude: 39.910, longitude: 116.398},
    // ...实际获取用户移动轨迹点
  ];
}
4. 路线绘制与动画13

// 绘制路线（参考）
private async drawRoute(points: mapCommon.LatLng[]) {
  // 清除旧路线
  this.mapPolyline?.remove();
  
  // 创建新路线
  this.mapPolyline = await this.mapController?.addPolyline({
    points: points,
    color: 0xAA36C18D,
    width: 12
  });

  // 添加路线动画（参考）
  const traceOptions: mapCommon.TraceOverlayParams = {
    points: points,
    animationDuration: 3000,
    color: 0xAAFF5722,
    width: 8,
    animationCallback: (pointIndex) => {
      if (pointIndex === points.length - 1) {
        this.showArrivalInfo();
      }
    }
  };
  this.mapController?.addTraceOverlay(traceOptions);
}
二、关键技术点说明

轨迹绑路优化（参考2）

设置 matchType: 3启用轨迹绑路
通过 originPoints传入连续轨迹点2
特别适合步行/骑行场景的路径优化
避开封闭/施工道路（默认行为）
权限管理（参考45）

// 在module.json5中添加
"requestPermissions": [
  {
    "name": "ohos.permission.LOCATION"
  },
  {
    "name": "ohos.permission.APPROXIMATELY_LOCATION"
  }
]
地图初始化要点（参考3）

需要在AGC开通地图服务
使用调试证书手动签名
配置client_id：
// module.json5
"metadata": [{
  "name": "client_id",
  "value": "Your-Client-ID"
}]
三、最佳实践建议
性能优化方案

使用HSP动态加载城市数据（参考4）
轨迹点采样：每5-10米采集一个点
使用 mapController.clear()批量移除旧元素
交互增强

// 景点点击事件
this.mapController.on('markerClick', (marker) => {
  const attraction = this.attractions.find(a => a.id === marker.id);
  this.showAttractionDetail(attraction!);
});
错误处理

try {
  // 路径规划操作
} catch (err) {
  if (err.code === 1803) { // 路径不存在
    promptAction.showToast({message: '未找到可行路线'});
  }
}
四、完整开发流程
在AGC控制台开通地图服务
配置模块签名信息
实现景点管理数据结构
集成MapKit初始化地图
实现景点标记渲染逻辑
添加路径规划服务调用
实现轨迹绑路数据采集
添加路线绘制动画效果
关键提示：轨迹绑路(matchType=3)需要连续的位置点数据，建议使用@kit.LocationKit的连续定位功能采集用户移动轨迹，采样间隔建议设置为3-5秒
### 官方写法：
场景介绍
根据给定的坐标点捕捉道路，将用户的轨迹纠正到道路上，从而返回用户实际驾车经过的道路坐标。

接口说明
以下是路径规划功能相关接口，主要由navi命名空间下的方法提供，更多接口及使用方法请参见接口文档。

接口名

描述

SnapToRoadsParams

轨迹绑路的参数。

snapToRoads(params: SnapToRoadsParams): Promise<SnapToRoadsResult>

轨迹绑路。

snapToRoads(context: common.Context, params: SnapToRoadsParams): Promise<SnapToRoadsResult>

轨迹绑路。支持传入Context上下文。

SnapToRoadsResult

轨迹绑路的结果。

开发步骤
导入相关模块。
import { navi } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
轨迹绑路
根据给定的坐标点捕捉道路，将用户的轨迹纠正到道路上，从而返回用户实际驾车经过的道路坐标。

async testSnapToRoads() {
  let params: navi.SnapToRoadsParams = {
    // 道路贴合点集合，不能超过100个，且相邻两个点距离需小于等于500米
    points: [{
      latitude: 31.984410259206815,
      longitude: 118.76625379397866
    }]
  };
  try {
    const result = await navi.snapToRoads(params);
    console.info(`Succeeded in snapping to roads. result is ${JSON.stringify(result)}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed in snapping to roads. Code is ${err.code}, message is ${err.message}`);
  }
}
### 批量算路
批量算路
更新时间: 2025-12-30 15:45
场景介绍
多个起点到多个终点的批量算路功能，在驾车、步行、骑行模式下，快速批量计算多个起点分别到多个终点的路线距离和耗时。

接口说明
以下是路径规划功能相关接口，主要由navi命名空间下的方法提供，更多接口及使用方法请参见接口文档。

接口名

描述

getDrivingMatrix(params: DrivingMatrixParams): Promise<MatrixResult>

驾车批量算路。

getDrivingMatrix(context: common.Context, params: DrivingMatrixParams): Promise<MatrixResult>

驾车批量算路。支持传入Context上下文。

getWalkingMatrix(params: MatrixParams): Promise<MatrixResult>

步行批量算路。

getWalkingMatrix(context: common.Context, params: MatrixParams): Promise<MatrixResult>

步行批量算路。支持传入Context上下文。

getCyclingMatrix(params: MatrixParams): Promise<MatrixResult>

骑行批量算路。

getCyclingMatrix(context: common.Context, params: MatrixParams): Promise<MatrixResult>

骑行批量算路。支持传入Context上下文。

DrivingMatrixParams

驾车批量算路的参数。

MatrixParams

步行、骑行批量算路的参数。

MatrixResult

批量算路的结果。

开发步骤
导入相关模块。
import { navi } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
驾车批量算路
根据多组起终点坐标批量检索符合条件的驾车路径规划方案。支持以下功能：

支持未来出行规划。
支持根据实时路况进行合理路线规划。
支持多种路线偏好选择，如时间最短、避免经过收费的公路、避开高速公路、距离优先等。
说明
限制：起点数乘以终点数需小于100。

async testDrivingMatrix() {
  let params: navi.DrivingMatrixParams = {
    // 起点的经纬度
    origins: [{
      latitude: 31.9844,
      longitude: 118.766253
    }, {
      latitude: 31.9644,
      longitude: 118.746253
    }],
    // 终点的经纬度
    destinations: [{
      latitude: 31.9344,
      longitude: 118.706253
    }],
    // 时间预估模型
    trafficMode: 2,
    language: 'zh_CN'
  };
  try {
    const result = await navi.getDrivingMatrix(params);
    console.info(`Succeeded in getting driving matrix. result is ${JSON.stringify(result)}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed in getting driving matrix. Code is ${err.code}, message is ${err.message}`);
  }
}
步行批量算路
根据多组起终点坐标批量检索符合条件的步行路径规划方案。支持以下功能：

支持150km以内的步行路径规划能力。
融入出行策略（时间最短、避免轮渡）。
说明
限制：起点数乘以终点数需小于100。

async testWalkingMatrix() {
  let params: navi.MatrixParams = {
    // 起点的经纬度
    origins: [
      { 
        latitude: 31.9844,
        longitude: 118.766253 
      }, { 
      latitude: 31.9644,
      longitude: 118.746253 
    }],
    // 终点的经纬度
    destinations: [{ 
      latitude: 31.9344,
      longitude: 118.706253 
    }],
    language: 'zh_CN'
  };
  try {
    const result = await navi.getWalkingMatrix(params);
    console.info(`Succeeded in getting walking matrix. result is ${JSON.stringify(result)}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed in getting walking matrix. Code is ${err.code}, message is ${err.message}`);
  }
}
骑行批量算路
根据多组起终点坐标批量检索符合条件的骑行路径规划方案。支持以下功能：

支持500km以内的骑行路径规划能力。
融入出行策略（时间最短、避免轮渡）。
说明
限制：起点数乘以终点数需小于100。

async testCyclingMatrix() {
  let params: navi.MatrixParams = {
    // 起点的经纬度
    origins: [{ 
      latitude: 31.9844,
      longitude: 118.766253
    }, { 
      latitude: 31.9644,
      longitude: 118.746253
    }],
    // 终点的经纬度
    destinations: [{ 
      latitude: 31.9344,
      longitude: 118.706253
    }],
    language: 'zh_CN'
  };
  try {
    const result = await navi.getCyclingMatrix(params);
    console.info(`Succeeded in getting cycling matrix. result is ${JSON.stringify(result)}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed in getting cycling matrix. Code is ${err.code}, message is ${err.message}`);
  }
}
### 地图详细展示
场景介绍
本章节将向您介绍如何集成地点详情展示控件，该控件为您提供了便捷的地点详情展示功能实现方案，无需自行开发地图页面。此外，该控件还具备导航功能，您可通过点击"路线"按钮直接启动导航功能，或通过点击相邻的打车按钮快速发起打车服务。需要注意的是，该控件暂不支持在智能表设备上调用。

图1 地点详情
点击放大
约束与限制
使用该功能需满足以下条件：

仅支持手机、平板和2in1设备。
接口说明
地点详情控件功能主要由sceneMap命名空间下的queryLocation方法提供，更多接口及使用方法请参见接口文档。

接口名

描述

LocationQueryOptions

查询地点详情的参数。

queryLocation(context: common.UIAbilityContext, options: LocationQueryOptions): Promise<void>

查询地点详情。

开发步骤
导入相关模块。
import { sceneMap } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
创建查询地点详情参数，调用queryLocation方法拉起地点详情页。
// 方式一：传入siteId
let queryLocationOptions: sceneMap.LocationQueryOptions = { 
  siteId: "922207154068557824" 
};
// 拉起地点详情页
sceneMap.queryLocation(this.getUIContext().getHostContext() as common.UIAbilityContext, queryLocationOptions)
  .then(() => {
    console.info("QueryLocation", "Succeeded in querying location.");
  })
  .catch((err: BusinessError) => {
    console.error("QueryLocation", `Failed to query Location, code: ${err.code}, message: ${err.message}`);
  });

// 方式二：传入location和name
let queryLocationOptions: sceneMap.LocationQueryOptions = {
  location: {
    latitude: 39.9175,
    longitude: 116.3972
  },
  name: '故宫博物院'
};
// 拉起地点详情页
sceneMap.queryLocation(this.getUIContext().getHostContext() as common.UIAbilityContext, queryLocationOptions)
  .then(() => {
    console.info("QueryLocation", "Succeeded in querying location.");
  })
  .catch((err: BusinessError) => {
    console.error("QueryLocation", `Failed to query Location, code: ${err.code}, message: ${err.message}`);
  });
  ### 地点选取
  场景介绍
本章节将向您介绍如何集成地点选取控件，您无需自己开发地图页面，可快速实现地点选取的能力。该控件不支持在智能表设备中调用。

图1 地点选取页
点击放大

图2 地点选取
点击放大

约束与限制
使用该功能需满足以下条件：

仅支持手机、平板和2in1设备。
接口说明
地点选取控件功能主要由sceneMap命名空间下的chooseLocation方法提供，更多接口及使用方法请参见接口文档。

接口名

描述

LocationChoosingOptions

地点选取的参数。

chooseLocation(context: common.UIAbilityContext, options: LocationChoosingOptions): Promise<LocationChoosingResult>

地点选取。

LocationChoosingResult

地点选取的返回结果。

开发步骤
导入相关模块。
import { sceneMap } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
创建地点选取参数，调用chooseLocation方法拉起地点选取页。
let locationChoosingOptions: sceneMap.LocationChoosingOptions = {
  // 地图中心点坐标
  location: { 
    latitude: 39.91804051376904,
    longitude: 116.3970536796932
  },
  // 展示搜索控件
  searchEnabled: true,
  // 展示附近POI
  showNearbyPoi: true
};
// 拉起地点选取页
sceneMap.chooseLocation(this.getUIContext().getHostContext() as common.UIAbilityContext,
  locationChoosingOptions).then((data) => {
  console.info("ChooseLocation", "Succeeded in choosing location.");
}).catch((err: BusinessError) => {
  console.error("ChooseLocation", `Failed to choose location, code: ${err.code}, message: ${err.message}`);
});
###  通过地图实现导航能力
通过地图应用实现导航等能力
更新时间: 2025-12-30 15:45
场景介绍
从5.0.3(15)开始，支持地图应用首页、搜索地点、查看地点详情、规划路线和进行导航功能；从6.0.1(21)开始，支持地图应用发起打车功能。

本章节将向您介绍如何打开地图应用实现如下能力：

打开地图应用首页
打开地图应用搜索地点
打开地图应用查看地点详情
打开地图应用规划路线
打开地图应用进行导航
打开地图应用发起打车
接口说明
调用地图应用的功能主要通过petalMaps命名空间下的openMapHomePage、openMapTextSearch、openMapPoiDetail、openMapRoutePlan、openMapNavi、openMapTaxi等接口实现，更多接口及使用方法请参见接口文档。

接口说明

描述

TextSearchParams

文本搜索的参数。

PoiDetailParams

POI详情的参数。

RoutePlanParams

路线规划的参数。

NaviParams

导航的参数。

TaxiParams

打车的参数。

openMapHomePage(context: common.Context): Promise<void>

打开地图应用首页。

openMapTextSearch(context: common.Context, textSearchParams: TextSearchParams): Promise<void>

打开地图应用搜索地点。

openMapPoiDetail(context: common.Context, poiDetailParams: PoiDetailParams): Promise<void>

打开地图应用查看地点详情。

openMapRoutePlan(context: common.Context, routePlanParams: RoutePlanParams): Promise<void>

打开地图应用规划路线。

openMapNavi(context: common.Context, naviParams: NaviParams): Promise<void>

打开地图应用进行导航。

openMapTaxi(context: common.Context, taxiParams: TaxiParams): Promise<void>

打开地图应用打车页面。

地图应用使用的坐标类型
在国内站点，中国大陆使用GCJ02坐标系，中国台湾使用WGS84坐标系。

在海外站点，统一使用WGS84坐标系。坐标系转换参考：坐标纠偏。

开发步骤
导入相关模块

import { petalMaps } from '@kit.MapKit'
打开地图应用首页
通过openMapHomePage，打开地图应用首页。

try {
  await petalMaps.openMapHomePage(this.getUIContext().getHostContext());
} catch (e) {
  console.error(`code:${e.code}, message:${e.message}`);
}
图1 打开地图应用首页
点击放大

打开地图应用进行地点搜索
通过openMapTextSearch，传入搜索目标名称，打开地图应用进行地点搜索。
try {
  let params: petalMaps.TextSearchParams = {
    destinationName: '云谷'
  };
  await petalMaps.openMapTextSearch(this.getUIContext().getHostContext(), params);
} catch (e) {
  console.error(`code:${e.code}, message:${e.message}`);
}
图2 打开地图应用进行地点搜索
点击放大

打开地图应用查看地点详情
通过openMapPoiDetail，传入地点的经纬度，打开地图应用查看地点详情。
try {
  let params: petalMaps.PoiDetailParams = {
    destinationPosition: {
      latitude: 32.02065982629459,
      longitude: 118.788899213002
    },
    destinationPoiId: '563233191438217472'
  };
  await petalMaps.openMapPoiDetail(this.getUIContext().getHostContext(), params);
} catch (e) {
  console.error(`code:${e.code}, message:${e.message}`);
}
图3 打开地图应用查看地点详情
点击放大
打开地图应用规划路线
通过openMapRoutePlan，传入终点经纬度，打开地图应用规划路线。
try {
  let params: petalMaps.RoutePlanParams = {
    destinationPosition: {
      latitude: 31.983015468224288,
      longitude: 118.78058590757131
    }
  };
  await petalMaps.openMapRoutePlan(this.getUIContext().getHostContext(), params);
} catch (e) {
  console.error(`code:${e.code}, message:${e.message}`);
}
图4 打开地图应用规划路线

打开地图应用进行导航
通过openMapNavi，传入终点经纬度，打开地图应用发起导航。
try {
  let params: petalMaps.NaviParams = {
    destinationPosition: {
      latitude: 31.983015468224288,
      longitude: 118.78058590757131
    }
  };
  await petalMaps.openMapNavi(this.getUIContext().getHostContext(), params);
} catch (e) {
  console.error(`code:${e.code}, message:${e.message}`);
}
图5 打开地图应用进行导航

打开地图应用打车页面
通过openMapTaxi，传入终点经纬度，打开地图应用发起打车。
try {
  let params: petalMaps.TaxiParams = {
    destinationPosition: {
      latitude: 31.983015468224288,
      longitude: 118.78058590757131
    }
  };
  await petalMaps.openMapTaxi(this.getUIContext().getHostContext(), params);
} catch (e) {
  console.error(`code:${e.code}, message:${e.message}`);
}
图6 打开地图应用进行打车
点击放大
### 获取设备的位置信息开发指导
获取设备的位置信息开发指导（ArkTS）
更新时间: 2025-12-30 15:45
场景概述
开发者可以调用HarmonyOS位置相关接口，获取设备实时位置，或者最近的历史位置，以及监听设备的位置变化。

对于位置敏感的应用业务，建议获取设备实时位置信息。如果不需要设备实时位置信息，并且希望尽可能的节省耗电，开发者可以考虑获取最近的历史位置。

接口说明
获取设备的位置信息所使用的接口如下，详细说明参见：Location Kit API参考。

本模块能力仅支持WGS-84坐标系，如需转换成其他坐标系，请参考坐标转换工具。

表2 获取设备的位置信息接口介绍

接口名

功能描述

on(type: 'locationChange', request: LocationRequest | ContinuousLocationRequest, callback: Callback<Location>): void

开启位置变化订阅，并发起定位请求。

off(type: 'locationChange', callback?: Callback<Location>): void

关闭位置变化订阅，并删除对应的定位请求。

getCurrentLocation(request: CurrentLocationRequest | SingleLocationRequest, callback: AsyncCallback<Location>): void

获取当前位置，使用callback回调异步返回结果。

getCurrentLocation(request?: CurrentLocationRequest | SingleLocationRequest): Promise<Location>

获取当前位置，使用Promise方式异步返回结果。

getLastLocation(): Location

获取最近一次定位结果。

isLocationEnabled(): boolean

判断位置服务是否已经开启。

开发步骤
获取设备的位置信息，需要有位置权限，位置权限申请的方法和步骤见申请位置权限开发指导。

导入geoLocationManager模块，所有与基础定位能力相关的功能API，都是通过该模块提供的。

import { geoLocationManager } from '@kit.LocationKit';
调用获取位置接口之前需要先判断位置开关是否打开。

查询当前位置开关状态，返回结果为布尔值，true代表位置开关开启，false代表位置开关关闭，示例代码如下：

import { geoLocationManager } from '@kit.LocationKit';
try {
    let locationEnabled = geoLocationManager.isLocationEnabled();
} catch (err) {
    console.error("errCode:" + err.code + ", message:"  + err.message);
}
如果位置开关未开启，可以拉起全局开关设置弹框，引导用户打开位置开关，具体可参考拉起全局开关设置弹框。

单次获取当前设备位置。多用于查看当前位置、签到打卡、服务推荐等场景。

方式一：获取系统缓存的最新位置。

如果系统当前没有缓存位置会返回错误码。

推荐优先使用该接口获取位置，可以减少系统功耗。

如果对位置的新鲜度比较敏感，可以先获取缓存位置，将位置中的时间戳与当前时间对比，若新鲜度不满足预期可以使用方式二获取位置。

import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit'
try {
    let location = geoLocationManager.getLastLocation();
} catch (err) {
    console.error("errCode:" + JSON.stringify(err));
}
方式二：获取当前位置。

首先要实例化SingleLocationRequest对象，用于告知系统该向应用提供何种类型的位置服务，以及单次定位超时时间。

设置LocatingPriority：

如果对位置的返回精度要求较高，建议LocatingPriority参数优先选择PRIORITY_ACCURACY，会将一段时间内精度较好的结果返回给应用。

如果对定位速度要求较高，建议LocatingPriority参数选择PRIORITY_LOCATING_SPEED，会将最先拿到的定位结果返回给应用。

两种定位策略均会同时使用GNSS定位和网络定位技术，以便在室内和户外场景下均可以获取到位置结果，对设备的硬件资源消耗较大，功耗也较大。

设置locatingTimeoutMs：

因为设备环境、设备所处状态、系统功耗管控策略等的影响，定位返回的时延会有较大波动，建议把单次定位超时时间设置为10秒。

以快速定位策略(PRIORITY_LOCATING_SPEED)为例，调用方式如下：

import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit'
let request: geoLocationManager.SingleLocationRequest = {
   'locatingPriority': geoLocationManager.LocatingPriority.PRIORITY_LOCATING_SPEED,
   'locatingTimeoutMs': 10000
}
try {
   geoLocationManager.getCurrentLocation(request).then((result) => { // 调用getCurrentLocation获取当前设备位置，通过promise接收上报的位置
      console.log('current location: ' + JSON.stringify(result));
   })
   .catch((error:BusinessError) => { // 接收上报的错误码
      console.error('promise, getCurrentLocation: error=' + JSON.stringify(error));
   });
 } catch (err) {
   console.error("errCode:" + JSON.stringify(err));
 }
通过本模块获取到的坐标均为WGS-84坐标系坐标点，如需使用其它坐标系类型的坐标点，请进行坐标系转换后再使用。

可使用三方地图提供的SDK能力进行坐标系转换。

持续定位。多用于导航、运动轨迹、出行等场景。

首先要实例化ContinuousLocationRequest对象，用于告知系统该向应用提供何种类型的位置服务，以及位置结果上报的频率。

设置locationScenario：

建议locationScenario参数优先根据应用的使用场景进行设置，该参数枚举值定义参见UserActivityScenario，例如地图在导航时使用NAVIGATION参数，可以持续在室内和室外场景获取位置用于导航。

设置interval：

表示上报位置信息的时间间隔，单位是秒，默认值为1秒。如果对位置上报时间间隔无特殊要求，可以不填写该字段。

以地图导航场景为例，调用方式如下：

import { geoLocationManager } from '@kit.LocationKit';
let request: geoLocationManager.ContinuousLocationRequest= {
   'interval': 1,
   'locationScenario': geoLocationManager.UserActivityScenario.NAVIGATION
}
let locationCallback = (location:geoLocationManager.Location):void => {
   console.log('locationCallback: data: ' + JSON.stringify(location));
};
try {
   geoLocationManager.on('locationChange', request, locationCallback);
} catch (err) {
   console.error("errCode:" + JSON.stringify(err));
}
如果不主动结束定位可能导致设备功耗高，耗电快；建议在不需要获取定位信息时及时结束定位。

geoLocationManager.off('locationChange', locationCallback);
### 位置服务API
位置服务提供GNSS定位、网络定位（蜂窝基站、WLAN、蓝牙定位技术）、地理编码、逆地理编码、国家码和地理围栏等基本功能。

使用位置服务时请打开设备“位置”开关。如果“位置”开关关闭并且代码未设置捕获异常，可能导致应用异常。

说明
本模块首批接口从API version 9开始支持。后续版本的新增接口，采用上角标单独标记接口的起始版本。

本模块能力仅支持WGS-84坐标系。

申请权限
支持设备PhonePC/2in1TabletWearable
请参考申请位置权限开发指导。

导入模块
支持设备PhonePC/2in1TabletWearable
import { geoLocationManager } from '@kit.LocationKit';
ReverseGeoCodeRequest
支持设备PhonePC/2in1TabletWearable
逆地理编码请求参数。

系统能力：SystemCapability.Location.Location.Geocoder

名称	类型	只读	可选	说明
locale	string	否	是	指定位置描述信息的语言，“zh”代表中文，“en”代表英文。默认值从设置中的“语言和地区”获取。
country	string	否	是	限制查询结果在指定的国家内，采用ISO 3166-1 alpha-2 。“CN”代表中国。默认值从设置中的“语言和地区”获取。
latitude	number	否	否	表示纬度信息，正值表示北纬，负值表示南纬。取值范围为-90到90。仅支持WGS84坐标系。
longitude	number	否	否	表示经度信息，正值表示东经，负值表示西经。取值范围为-180到180。仅支持WGS84坐标系。
maxItems	number	否	是	指定返回位置信息的最大个数。取值范围为大于等于0，推荐该值小于10。默认值是1。
GeoCodeRequest
支持设备PhonePC/2in1TabletWearable
地理编码请求参数。

系统能力：SystemCapability.Location.Location.Geocoder

名称	类型	只读	可选	说明
locale	string	否	是	表示位置描述信息的语言，“zh”代表中文，“en”代表英文。默认值从设置中的“语言和地区”获取。
country	string	否	是	限制查询结果在指定的国家内，采用ISO 3166-1 alpha-2 。“CN”代表中国。默认值从设置中的“语言和地区”获取。
description	string	否	否	表示位置信息描述，如“上海市浦东新区xx路xx号”，字符串长度不超过100。
maxItems	number	否	是	表示返回位置信息的最大个数。取值范围为大于等于0，推荐该值小于10。默认值是1。
minLatitude	number	否	是	表示最小纬度信息，与下面三个参数一起，表示一个经纬度范围。取值范围为-90到90。仅支持WGS84坐标系。如果该参数有值时，下面三个参数必填。
minLongitude	number	否	是	表示最小经度信息。取值范围为-180到180。仅支持WGS84坐标系。
maxLatitude	number	否	是	表示最大纬度信息。取值范围为-90到90。仅支持WGS84坐标系。
maxLongitude	number	否	是	表示最大经度信息。取值范围为-180到180。仅支持WGS84坐标系。
GeoAddress
支持设备PhonePC/2in1TabletWearable
地理编码地址信息。

系统能力：SystemCapability.Location.Location.Geocoder

名称	类型	只读	可选	说明
latitude	number	否	是	表示纬度信息，正值表示北纬，负值表示南纬。取值范围为-90到90。仅支持WGS84坐标系。
longitude	number	否	是	表示经度信息，正值表示东经，负值表是西经。取值范围为-180到180。仅支持WGS84坐标系。
locale	string	否	是	表示位置描述信息的语言，“zh”代表中文，“en”代表英文。
placeName	string	否	是	表示详细地址信息。
countryCode	string	否	是	表示国家码信息。
countryName	string	否	是	表示国家信息。
administrativeArea	string	否	是	表示国家以下的一级行政区，一般是省/州。
subAdministrativeArea	string	否	是	表示国家以下的二级行政区，一般是市。
locality	string	否	是	表示城市信息，一般是市。
subLocality	string	否	是	表示子城市信息，一般是区/县。
roadName	string	否	是	表示路名信息。
subRoadName	string	否	是	表示子路名信息。
premises	string	否	是	表示门牌号信息。
postalCode	string	否	是	表示邮政编码信息。
phoneNumber	string	否	是	表示联系方式信息。
addressUrl	string	否	是	表示位置信息附件的网址信息。
descriptions	Array<string>	否	是	表示附加的描述信息。目前包含城市编码cityCode（Array下标为0）和区划编码adminCode（Array下标为1），例如["025","320114001"]。
descriptionsSize	number	否	是	表示附加的描述信息数量。取值范围为大于等于0，推荐该值小于10。
LocationRequest
支持设备PhonePC/2in1TabletWearable
位置信息请求参数。

元服务API： 从API version 11开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Location.Location.Core

名称	类型	只读	可选	说明
priority	LocationRequestPriority	否	是	表示优先级信息。当scenario取值为UNSET时，priority参数生效，否则priority参数不生效；当scenario和priority均取值为UNSET时，无法发起定位请求。取值范围见LocationRequestPriority的定义。默认值为FIRST_FIX。
scenario	LocationRequestScenario	否	是	表示场景信息。当scenario取值为UNSET时，priority参数生效，否则priority参数不生效；当scenario和priority均取值为UNSET时，无法发起定位请求。取值范围见LocationRequestScenario的定义。默认值为UNSET。
timeInterval	number	否	是	
表示上报位置信息的时间间隔，单位为秒。

取值范围为大于等于0的值。

默认值为对应定位模式下允许的最小时间间隔：

默认值在GNSS定位时为1秒，网络定位时为20秒。

当设置值小于最小间隔时，以最小时间间隔生效。

设置为0时不对时间间隔进行校验，直接上报位置信息。

distanceInterval	number	否	是	表示上报位置信息的距离间隔。单位是米，默认值为0，取值范围为大于等于0。等于0时对位置上报距离间隔无限制。
maxAccuracy	number	否	是	
应用向系统请求位置信息时要求的精度值，单位为米。该参数仅在精确位置功能场景（即同时授权了ohos.permission.APPROXIMATELY_LOCATION和ohos.permission.LOCATION 权限）下有效，模糊位置功能生效场景（即仅授权了ohos.permission.APPROXIMATELY_LOCATION 权限）下该字段无意义。

该参数生效的情况下，系统会对比GNSS或网络定位服务上报的位置信息与应用的位置信息申请。当位置信息Location中的精度值（accuracy）小于等于应用要求的精度值（maxAccuracy）时，位置信息会返回给应用；否则系统将丢弃本次收到的位置信息。

默认值为0，表示不限制位置信息的精度，取值范围为大于等于0。

当scenario为NAVIGATION/TRAJECTORY_TRACKING/CAR_HAILING或者priority为ACCURACY时建议设置maxAccuracy为大于10的值。

当scenario为DAILY_LIFE_SERVICE/NO_POWER或者priority为LOW_POWER/FIRST_FIX时建议设置maxAccuracy为大于100的值。

CurrentLocationRequest
支持设备PhonePC/2in1TabletWearable
当前位置信息请求参数。

元服务API： 从API version 11开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Location.Location.Core

名称	类型	只读	可选	说明
priority	LocationRequestPriority	否	是	表示优先级信息。当scenario取值为UNSET时，priority参数生效，否则priority参数不生效；当scenario和priority均取值为UNSET时，无法发起定位请求。取值范围见LocationRequestPriority的定义。默认值为FIRST_FIX。
scenario	LocationRequestScenario	否	是	表示场景信息。当scenario取值为UNSET时，priority参数生效，否则priority参数不生效；当scenario和priority均取值为UNSET时，无法发起定位请求。取值范围见LocationRequestScenario的定义。默认值为UNSET。
maxAccuracy	number	否	是	
应用向系统请求位置信息时要求的精度值，单位为米。该参数仅在精确位置功能场景（即同时授权了ohos.permission.APPROXIMATELY_LOCATION和ohos.permission.LOCATION 权限）下有效，模糊位置功能生效场景（即仅授权了ohos.permission.APPROXIMATELY_LOCATION 权限）下该字段无意义。

该参数生效的情况下，系统会对比GNSS或网络定位服务上报的位置信息与应用的位置信息申请。当位置信息Location中的精度值（accuracy）小于等于应用要求的精度值（maxAccuracy）时，位置信息会返回给应用；否则系统将丢弃本次收到的位置信息。

默认值为0，表示不限制位置信息的精度，取值范围为大于等于0。

当scenario为NAVIGATION/TRAJECTORY_TRACKING/CAR_HAILING或者priority为ACCURACY时建议设置maxAccuracy为大于10的值。

当scenario为DAILY_LIFE_SERVICE/NO_POWER或者priority为LOW_POWER/FIRST_FIX时建议设置maxAccuracy为大于100的值。

timeoutMs	number	否	是	表示超时时间，单位是毫秒，最小为1000毫秒。取值范围为大于等于1000。
ContinuousLocationRequest
支持设备PhonePC/2in1TabletWearable
持续定位的请求参数。

元服务API： 从API version 12开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Location.Location.Core

名称	类型	只读	可选	说明
interval	number	否	否	表示上报位置信息的时间间隔，单位是秒。默认值为1，取值范围为大于等于0。等于0时对位置上报时间间隔无限制。
locationScenario	UserActivityScenario | PowerConsumptionScenario	否	否	表示定位的场景信息。取值范围见UserActivityScenario和PowerConsumptionScenario的定义。
needPoi	boolean	否	是	
表示是否需要获取当前位置附近的POI信息。false代表不需要获取当前位置附近的POI信息，true代表需要获取当前位置附近的POI信息。不设置时，默认值为false。

该参数仅在精确位置功能场景（即同时授权了ohos.permission.APPROXIMATELY_LOCATION和ohos.permission.LOCATION 权限）下有效，模糊位置功能生效场景（即仅授权了ohos.permission.APPROXIMATELY_LOCATION 权限）下不返回POI信息。

元服务API： 从API version 19开始，该接口支持在元服务中使用。

SingleLocationRequest
支持设备PhonePC/2in1TabletWearable
单次定位的请求参数。

元服务API： 从API version 12开始，该接口支持在元服务中使用。

系统能力：SystemCapability.Location.Location.Core

名称	类型	只读	可选	说明
locatingPriority	LocatingPriority	否	否	表示优先级信息。取值范围见LocatingPriority的定义。
locatingTimeoutMs	number	否	否	表示超时时间，单位是毫秒，最小为1000毫秒。取值范围为大于等于1000。
needPoi	boolean	否	是	
表示是否需要获取当前位置附近的POI信息。false代表不需要获取当前位置附近的POI信息，true代表需要获取当前位置附近的POI信息。不设置时，默认值为false。

该参数仅在精确位置功能场景（即同时授权了ohos.permission.APPROXIMATELY_LOCATION和ohos.permission.LOCATION 权限）下有效，模糊位置功能生效场景（即仅授权了ohos.permission.APPROXIMATELY_LOCATION 权限）下不返回POI信息。

元服务API： 从API version 19开始，该接口支持在元服务中使用。

SatelliteStatusInfo
支持设备PhoneTabletWearable
卫星状态信息。

系统能力：SystemCapability.Location.Location.Gnss

名称	类型	只读	可选	说明
satellitesNumber	number	否	否	表示卫星个数。取值范围为大于等于0。
satelliteIds	Array<number>	否	否	表示每个卫星的ID，数组类型。取值范围为大于等于0。
carrierToNoiseDensitys	Array<number>	否	否	表示载波噪声功率谱密度比，即cn0。取值范围为大于0。
altitudes	Array<number>	否	否	表示卫星高度角信息。单位是“度”，取值范围为-90到90。
azimuths	Array<number>	否	否	表示方位角。单位是“度”，取值范围为0到360。
carrierFrequencies	Array<number>	否	否	表示载波频率。单位是Hz，取值范围为大于等于0。
satelliteConstellation	Array<SatelliteConstellationCategory>	否	是	表示卫星星座类型。
satelliteAdditionalInfo	Array<number>	否	是	
表示卫星的附加信息。

每个比特位代表不同含义，具体定义参见SatelliteAdditionalInfo。

CachedGnssLocationsRequest
支持设备PhoneTabletWearable
请求订阅GNSS缓存位置上报功能接口的配置参数。

系统能力：SystemCapability.Location.Location.Gnss

名称	类型	只读	可选	说明
reportingPeriodSec	number	否	否	表示GNSS缓存位置上报的周期，单位是毫秒。取值范围为大于0。
wakeUpCacheQueueFull	boolean	否	否	
true表示GNSS芯片底层缓存队列满之后会主动唤醒AP芯片，并把缓存位置上报给应用。

false表示GNSS芯片底层缓存队列满之后不会主动唤醒AP芯片，会把缓存位置直接丢弃。

Geofence
支持设备PhoneTablet
GNSS围栏的配置参数。目前只支持圆形围栏。

系统能力：SystemCapability.Location.Location.Geofence

名称	类型	只读	可选	说明
latitude	number	否	否	表示纬度。取值范围为-90到90。
longitude	number	否	否	表示经度。取值范围为-180到180。
coordinateSystemType	CoordinateSystemType	否	是	
表示地理围栏圆心坐标的坐标系。

APP应先使用getGeofenceSupportedCoordTypes查询支持的坐标系，然后传入正确的圆心坐标。

radius	number	否	否	表示圆形围栏的半径。单位是米，取值范围为大于0。
expiration	number	否	否	围栏存活的时间，单位是毫秒。取值范围为大于0。
GeofenceRequest
支持设备PhoneTablet
请求添加GNSS围栏消息中携带的参数，包括定位场景和围栏信息。

系统能力：SystemCapability.Location.Location.Geofence

名称	类型	只读	可选	说明
scenario	LocationRequestScenario	否	否	表示定位场景。
geofence	Geofence	否	否	表示围栏信息。
LocationCommand
支持设备PhonePC/2in1TabletWearable
扩展命令参数。

系统能力：SystemCapability.Location.Location.Core

名称	类型	只读	可选	说明
scenario	LocationRequestScenario	否	否	表示定位场景。
command	string	否	否	扩展命令字符串，字符串长度不超过100。
Location
支持设备PhonePC/2in1TabletWearable
位置信息。

系统能力：SystemCapability.Location.Location.Core

名称	类型	只读	可选	说明
latitude	number	否	否	
表示纬度信息，正值表示北纬，负值表示南纬。取值范围为-90到90。仅支持WGS84坐标系。

元服务API： 从API version 11开始，该接口支持在元服务中使用。

longitude	number	否	否	
表示经度信息，正值表示东经，负值表是西经。取值范围为-180到180。仅支持WGS84坐标系。

元服务API： 从API version 11开始，该接口支持在元服务中使用。

altitude	number	否	否	
表示高度信息，单位米。

元服务API： 从API version 11开始，该接口支持在元服务中使用。

accuracy	number	否	否	
表示精度信息，单位米。

元服务API： 从API version 11开始，该接口支持在元服务中使用。

speed	number	否	否	
表示速度信息，单位米每秒。

元服务API： 从API version 11开始，该接口支持在元服务中使用。

timeStamp	number	否	否	
表示位置时间戳，UTC格式。

元服务API： 从API version 11开始，该接口支持在元服务中使用。

direction	number	否	否	
表示航向信息。单位是“度”，取值范围为0到360。

元服务API： 从API version 11开始，该接口支持在元服务中使用。

timeSinceBoot	number	否	否	
表示获取位置成功的时间戳，值表示从本次开机到获取位置成功所经过的时间，单位为纳秒。

元服务API： 从API version 11开始，该接口支持在元服务中使用。

additions	Array<string>	否	是	
附加信息。

元服务API： 从API version 11开始，该接口支持在元服务中使用。

additionSize	number	否	是	
附加信息数量。取值范围为大于等于0。

元服务API： 从API version 11开始，该接口支持在元服务中使用。

additionsMap	Map<string, string>	否	是	
附加信息。具体内容和顺序与additions一致。

元服务API： 从API version 12开始，该接口支持在元服务中使用。

altitudeAccuracy	number	否	是	
表示高度信息的精度，单位米。

元服务API： 从API version 12开始，该接口支持在元服务中使用。

speedAccuracy	number	否	是	
表示速度信息的精度，单位米每秒。

元服务API： 从API version 12开始，该接口支持在元服务中使用。

directionAccuracy	number	否	是	
表示航向信息的精度。单位是“度”，取值范围为0到360。

元服务API： 从API version 12开始，该接口支持在元服务中使用。

uncertaintyOfTimeSinceBoot	number	否	是	
表示位置时间戳的不确定度。

元服务API： 从API version 12开始，该接口支持在元服务中使用。

sourceType	LocationSourceType	否	是	
表示定位结果的来源。

元服务API： 从API version 12开始，该接口支持在元服务中使用。

poi	PoiInfo	否	是	
表示当前位置附近的POI信息。

元服务API： 从API version 19开始，该接口支持在元服务中使用。

GeofenceTransition
支持设备PhoneTablet
地理围栏事件信息；包含地理围栏ID和具体的地理围栏事件。

系统能力：SystemCapability.Location.Location.Geofence

名称	类型	只读	可选	说明
geofenceId	number	否	否	表示地理围栏ID。
transitionEvent	GeofenceTransitionEvent	否	否	表示当前发生的地理围栏事件。
beaconFence	BeaconFence	否	是	
beacon围栏的参数配置。仅beacon围栏使用。

从API version 20开始，支持该字段。

GnssGeofenceRequest
支持设备PhoneTablet
GNSS地理围栏请求参数。

系统能力：SystemCapability.Location.Location.Geofence

名称	类型	只读	可选	说明
geofence	Geofence	否	否	表示地理围栏信息，包含圆形围栏圆心坐标、半径等信息。
monitorTransitionEvents	Array<GeofenceTransitionEvent>	否	否	表示APP监听的地理围栏事件列表。数组长度不超过3。
notifications	Array<NotificationRequest>	否	是	
表示地理围栏事件发生后弹出的通知对象列表。

monitorTransitionEvents与notifications中的顺序要一一对应，例如monitorTransitionEvents[0]为GeofenceTransitionEvent.GEOFENCE_TRANSITION_EVENT_ENTER，那notifications[0]中就需要填入用户进入围栏时需要弹出的通知对象。默认值为空数组。

geofenceTransitionCallback	AsyncCallback<GeofenceTransition>	否	否	表示用于接收地理围栏事件的回调函数。
### 官方demo示例：
园区地图demo代码实现
地图包括标记园区区域、标记项目点、路径规划、定位、导航功能。使用Map Kit的主要功能入口类MapComponentCotroller，接入地图功能。

标记园区区域功能是使用addPolygon接口在地图上添加一个多边形，传入区域顶点经纬度坐标。

// features/MapService/src/main/ets/components/MapPage.ets
let polygonOptions: mapCommon.MapPolygonOptions = {
  points: [

    { latitude: 31.92076, longitude: 118.884807 },
    { latitude: 31.920765, longitude: 118.901785 },
    { latitude: 31.875771, longitude: 118.885653 },
    { latitude: 31.895816, longitude: 118.851926 },
    { latitude: 31.92315, longitude: 118.849931 },
    { latitude: 31.925617, longitude: 118.882312 }
  ],
  holes: [],
  clickable: true,
  fillColor: 0x00000000,
  geodesic: false,
  strokeColor: 0xff000000,
  jointType: mapCommon.JointType.DEFAULT,
  patterns: [],
  strokeWidth: 10,
  visible: true,
  zIndex: 0
};
await this.mapController.addPolygon(polygonOptions);
标记项目点功能使用addMarker接口，传入经纬度坐标生成标记位。

// features/MapService/src/main/ets/components/MapPage.ets
// 创建Marker
this.marker = await this.mapController.addMarker(markerOptions);
this.marker.setTitle('初始位置')
this.marker.setSnippet("这是子标题")
this.marker.setClickable(true)

this.addBasicPoints()
// features/MapService/src/main/ets/components/MapPage.ets
async addBasicPoints() {
  let markerOptions3: mapCommon.MarkerOptions = {
    position: {
      latitude: 31.891836,
      longitude: 118.876121
    },
    rotation: 0,
    visible: true,
    zIndex: 0,
    alpha: 1,
    anchorU: 0.5,
    anchorV: 1,
    clickable: true,
    draggable: true,
    flat: false,
    icon: $r('app.media.startIcon')
  };
  // 创建Marker3
  let marker3 = await this.mapController?.addMarker(markerOptions3) as map.Marker;
  marker3.setTitle('白龙凹瀑布')
  marker3.setSnippet("保护区")
  marker3.setClickable(true)
路径规划使用了Map kit中navi模块。

// features/MapService/src/main/ets/components/MapPage.ets
async getRoutes() {
  try {
    let result: navi.RouteResult;
    this.drivingRouteParams.origins = this.marker?.getPosition() ? [this.marker?.getPosition()] : [];
    this.drivingRouteParams.destination = { latitude: 31.904083, longitude: 118.88457 };
    result = await navi.getDrivingRoutes(this.drivingRouteParams);
    result.routes[0].steps.forEach(async (step) => {
      this.routes.push({
        distance: step.distance,
        distanceDescription: step.distanceDescription,
        duration: step.duration,
        durationDescription: step.durationDescription,
        durationInTraffic: step.durationInTraffic,
        durationInTrafficDescription: step.durationInTrafficDescription,
      })
      step.roads.forEach((road) => {
        road.polyline.forEach((polyline) => {
          this.points.push(polyline)
        })
      })
    })
    const points = result.routes[0].overviewPolyline == null ? this.points : result.routes[0].overviewPolyline;
    if (points.length >= 1000) {
      this.polylineOption.points = points.filter((item, index) => index % 50 === 0 || index === points.length - 1);
    } else {
      this.polylineOption.points = points.filter((item, index) => index % 2 === 0 || index === points.length - 1);
    }
    if (this.mapPolyline) {
      this.mapPolyline.setPoints(this.polylineOption.points);
    } else {
      this.mapPolyline = await this.mapController?.addPolyline(this.polylineOption)
    }
  } catch (err) {
    Logger.error("naviDemo", "getDrivingRoutes fail err =" + JSON.stringify(err));
  }
}
定位功能需要在module.json5添加权限ohos.permission.LOCATION，可以获取到精准位置。

// phone/src/main/module.json5
"requestPermissions": [
  {
    "name": "ohos.permission.LOCATION",
    "reason": "$string:permission_location_reason",
    "usedScene": {
      "abilities": [
        "EntryAbility"
      ]
    }
  }
]
导航使用Want方式进行应用跳转并传入终点经纬度，在跳转的应用中直接发起导航。

// features/MapService/src/main/ets/components/MainPage.ets
build() {
  Column() {
    Text('导航去' + this.distinction)
      .fontSize(30)
      .height(100)
    Button('开始导航')
      .onClick(() => {
        let petalMapWant: Want = {
          bundleName: 'com.huawei.hmos.maps.app',
          uri: 'maps://navigation',
          parameters: {
            linkSource: 'com.example.touristparkdemo',
            destinationLatitude: this.distinclat,
            destinationLongitude: this.distinclon,
            destinationName: this.distinction,
            vehicleType: 0
          }
        }
        let context = getContext(this) as common.UIAbilityContext;
        context.startAbility(petalMapWant);

      })
      .margin(20)
  }
}