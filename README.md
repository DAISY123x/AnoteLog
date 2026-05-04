# Anote 艾笔记 - 作品介绍

## 一、项目概述

**Anote（艾笔记）** 是一款基于 HarmonyOS Next 开发的智能旅行攻略助手应用，深度集成华为 HMS Core 生态服务（地图、认证、推送）和 DeepSeek AI 大模型能力，为用户提供旅行规划、地点收藏、笔记记录、AI 智能推荐的全链路功能。

**技术栈**：HarmonyOS ArkTS / ArkUI / HMS Kit / DeepSeek AI

---

## 二、核心功能

### 2.1 华为账号登录（AccountKit）

支持华为一键登录（SSO）和手机号密码登录两种方式。华为账号登录成功后，用户信息（OpenID、昵称、头像）通过 AuthService 持久化到本地，支持会话恢复。

**技术实现**：
- `@kit.AccountKit` 华为认证服务
- AppStorage 全局状态管理
- Preferences 本地会话持久化
- 模拟器环境自动降级为模拟登录

### 2.2 华为地图服务（MapKit）

整合华为 MapKit 实现地图展示、POI 搜索、路径规划功能。

| 功能 | API | 说明 |
|------|------|------|
| 地点搜索 | `site.searchByText()` | 关键词搜索周边地点 |
| 逆地理编码 | `site.geocode()` | 坐标转地址 |
| 路线规划 | `navi.getDrivingRoutes()` | 驾车路径计算 |
| POI 图标 | PlaceResult.icon | 华为 POI 真实图标展示 |

**架构设计**：
- `MapService`：POI 搜索、地理编码
- `RouteService`：路径规划
- `MapContainer`：统一地图 UI 组件

### 2.3 华为推送服务（PushKit）

实现系统通知栏和应用内通知列表两种形态。

**消息链路**：
```
华为 Push 服务 → onReceiveMessage 回调 → 解析 payload → 写入本地 → NotificationPage 展示 → Badge 未读数
```

### 2.4 AI 景点介绍（DeepSeek）

基于 DeepSeek API 生成景点详细信息，包含开放时间、游览建议、注意事项等。

**技术优化**：
- **三级缓存**：内存缓存 → Preferences(30min TTL) → API 请求 → Mock 降级
- **指数退避重试**：1s → 2s → 4s
- **贪心最近邻 TSP 算法**：智能优化多地点游览顺序

### 2.5 天气服务

首页天气胶囊实时展示当前位置天气，点击展开详情（城市、温度、湿度、风力、出行建议）。

**定位链路**：
```
GPS 定位 → 逆地理编码获取城市 → 高德天气 API → 天气实况
     ↓（GPS 不可用）
IP 定位 → 城市 → 高德天气 API
     ↓（均失败）
默认城市回退
```

---

## 三、鸿蒙服务优化

### 3.1 分层架构重构

对原始项目进行分层解耦，建立清晰的架构层次：

```
pages/ (页面层) → service/ (业务服务层) → repository/ (仓储层) → dao/ (数据访问层) → RdbManager (数据库)
```

| 优化项 | 优化前 | 优化后 |
|--------|--------|--------|
| RdbManager | 742 行 7 张表 | 底层连接器，职责分离 |
| 文件行数 | 最大 615 行 | 单文件 < 300 行 |
| 代码复用 | TripCard 重复定义 | 独立组件复用 |
| 日志规范 | console.log 混用 | 统一 Logger (hilog) |

### 3.2 华为服务接口优化

| 模块 | 优化内容 |
|------|---------|
| **AuthService** | 华为登录会话持久化、模拟器环境检测、LoginType 枚举区分登录类型 |
| **MapService** | POI 图标字段透传、占位降级、华为 POI icon 支持 |
| **RouteService** | 路径规划结果缓存、TSP 路线优化 |
| **PushService** | 消息持久化、未读 Badge 同步、NotificationPage 联动 |
| **WeatherService** | GPS/IP 双定位降级、Mock 兜底、30min 内存缓存 |

### 3.3 智能降级机制

所有外部 API 调用均实现智能降级：

```typescript
// 优先后端 API
try {
  const resp = await ApiService.getInstance().getNotes();
  if (resp.code === 200) return resp.data;
} catch (e) {
  Logger.warn('NoteRepository', 'API 失败，降级到本地数据库');
}
// 降级到本地 SQLite
return RdbManager.getInstance().getNotes();
```

### 3.4 安全规范

- API Key 通过 `ConfigService` 读取 `rawfile/app_config.json`，禁止硬编码
- 密码 SHA256 哈希存储（`@kit.CryptoArchitectureKit`）
- 敏感配置不提交到公开仓库

### 3.5 HarmonyOS 特性适配

| 问题 | 解决方案 |
|------|---------|
| `@Prop` 禁止函数类型 | 中转页法（`aboutToAppear` 打开弹窗） |
| `@BuilderParam` 只传 UI 块 | 组件内直接路由跳转 |
| MapKit 模拟器限制 | productModel 检测 + 模拟登录降级 |
| Mock 数据编译错误 | 配置文件放 `resources/rawfile/` |

---

## 四、AI 技术落地

### 4.1 DeepSeek API 集成

```typescript
// 请求格式
{
  "model": "deepseek-chat",
  "messages": [{ "role": "user", "content": prompt }],
  "temperature": 0.7,
  "max_tokens": 500
}
```

### 4.2 三级缓存策略

```
请求 → 内存缓存(Map) → Preferences缓存(30min) → API请求 → Mock兜底
```

### 4.3 TSP 贪心最近邻算法

```typescript
// 从起点开始，每次选择最近的未访问地点
while (unvisited.length > 0) {
  const nearest = unvisited.sort((a, b) => 
    distance(current, a) - distance(current, b)
  )[0];
  route.push(nearest);
  unvisited.remove(nearest);
  current = nearest;
}
```

---

## 五、数据库设计

### 5.1 核心表结构

| 表名 | 说明 |
|------|------|
| `trip` | 行程主表 |
| `trip_place` | 行程景点表（含 POI 图标字段） |
| `note` | 笔记表 |
| `user_like` | 点赞表 |
| `saved_place` | 收藏地点表 |
| `custom_place` | 自定义地点表 |
| `feedback` | 反馈表 |

---

## 六、测试验证

### 6.1 后端接口测试（25/25 通过）

| 模块 | 接口数 | 状态 |
|------|--------|------|
| 认证 | 2 | ✅ |
| 笔记 | 6 | ✅ |
| 行程 | 8 | ✅ |
| 地点 | 5 | ✅ |
| 点赞 | 3 | ✅ |
| 反馈 | 1 | ✅ |

### 6.2 华为服务测试

| 服务 | 测试项 | 结果 |
|------|--------|------|
| AccountKit | 华为一键登录授权 | ✅ |
| MapKit | POI 搜索 + 路线规划 | ✅ |
| PushKit | 消息接收 + 应用内列表 | ✅ |
| WeatherService | 定位 + 天气获取 + 降级 | ✅ |
| AIService | 景点生成 + 缓存 + 重试 | ✅ |

---

## 七、项目结构

```
entry/src/main/ets/
├── entryability/EntryAbility.ets      # 应用入口
├── pages/                              # 20个页面
│   ├── Index.ets                     # 首页
│   ├── LoginPage.ets                 # 登录页
│   ├── NewTripPage.ets               # 新建行程
│   └── ...
├── service/                          # 业务服务层
│   ├── MapService.ets               # 华为地图服务
│   ├── RouteService.ets             # 路径规划
│   ├── AIService.ets                # AI服务
│   ├── AuthService.ets              # 认证服务
│   ├── PushService.ets              # 推送服务
│   └── WeatherService.ets           # 天气服务
├── repository/                       # 仓储层
├── dao/                              # 数据访问层
├── model/                            # 数据模型
├── view/                             # 视图组件
└── common/                          # 公共基础设施
    ├── database/RdbManager.ets      # SQLite数据库
    ├── constants/AppConstants.ets   # 全局常量
    └── utils/Logger.ets             # 日志工具
```
