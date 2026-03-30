# Anote 项目重构详细执行计划

> 生成时间: 2026-03-30  
> 项目路径: `e:\HarmonyOS\iniateDemoone\Anote`  
> 重构目标: 分层解耦、清理无用代码、添加注解、提升可维护性  

---

## 目录

- [一、当前项目问题清单](#一当前项目问题清单)
- [二、重构总体策略](#二重构总体策略)
- [三、执行阶段总览](#三执行阶段总览)
- [四、Phase 0: 基础设施搭建](#四phase-0-基础设施搭建)
- [五、Phase 1: 代码清理](#五phase-1-代码清理)
- [六、Phase 2: 架构分层](#六phase-2-架构分层)
- [七、Phase 3: UI 组件拆分](#七phase-3-ui-组件拆分)
- [八、Phase 4: 关键问题修复](#八phase-4-关键问题修复)
- [九、Phase 5: 注解与文档](#九phase-5-注解与文档)
- [十、Git 分支管理规范](#十git-分支管理规范)
- [十一、验证机制](#十一验证机制)
- [十二、紧急回滚方案](#十二紧急回滚方案)
- [十三、后期扩展功能清单](#十三后期扩展功能清单)
- [十四、后端规划（并行）](#十四后端规划并行)
- [十五、HarmonyOS ArkTS 特殊注意事项](#十五harmonyos-arts-特殊注意事项)
  - [14.1 技术选型决策](#141-技术选型决策)
  - [14.2 项目结构](#142-项目结构)
  - [14.3 数据库设计](#143-数据库设计)
  - [14.4 API 接口规范](#144-api-接口规范)
  - [14.5 地图 & AI 集成方案](#145-地图--ai-集成方案)
  - [14.6 前端 Mock 切换说明](#146-前端-mock-切换说明)
  - [14.7 环境配置清单](#147-环境配置清单)
  - [14.8 前后端联调流程](#148-前后端联调流程)
---
## 一、当前项目问题清单

### 1.0 紧急发现：地图和认证模块实际状态

> **已验证的正确配置（分层时需保持）**：

| 模块 | 状态 | 配置位置 |
|------|------|---------|
| 华为地图 | ✅ 可用 | `module.json5` 的 `client_id: "1851853890664827264"` |
| 华为认证 | ✅ 已集成 | `LoginPage.ets` 使用 `@kit.AccountKit` |
| 华为推送 | ⚠️ 初始化但未实现 | `EntryAbility.ets` 有 PushKit 初始化代码 |
| 华为凭据 | ⚠️ 已配置 | `agconnect-services.json` 有完整的 app_id、client_id |

> **发现的重复代码（分层时需处理）**：

| 发现 | 详情 | 处理方案 |
|------|------|---------|
| 路径规划重复 | `MapService.ets` 和 `RouteService.ets` 都实现了 `planDrivingRoute`，调用同一个 `navi.getDrivingRoutes()` | Phase 2 保留 `RouteService`，`MapService` 只保留 `searchPlaces` |
| TripCard 重复 | `RecentTripsPage.ets` 和 `PendingTripsPage.ets` 各自定义了 `TripCard Builder` | Phase 3 抽取为共享组件 |
| 地图组件重复 | `NewTripPage.ets` 内有 `MapContainer`，`ItineraryEditComponent.ets` 内有 `MapComponent` | Phase 3 统一用 `MapContainer` |

### 1.1 文件结构问题
| 文件 | 行数 | 问题等级 | 问题描述 |
|------|------|---------|---------|
| `RdbManager.ets` | 742 | P1 | 单文件处理 7 张表的 CRUD，职责过重 |
| `Index.ets` | 615 | P1 | 内联 BannerView、FeatureGrid、TripFeed Builder |
| `RecentTripsPage.ets` | 529 | P1 | TripCard Builder 与 PendingTripsPage 重复定义 |
| `PlaceDetailPage.ets` | 509 | P1 | PlaceCard 子组件嵌套在同一文件 |
| `NewTripPage.ets` | 425 | P1 | PlaceItem Builder 过长，功能耦合 |
| `PendingTripsPage.ets` | 354 | P1 | Mock 数据注释，数据库未连接 |
| `NoteDetailPage.ets` | 330 | P2 | Sidebar/ImageGallery 内嵌未拆分|
| `NoteListPage.ets` | 339 | P2 | 结构较好，但仍可微调|

### 1.2 安全问题

| 优先级 | 问题 | 位置 | 说明 |
|--------|------|------|------|
| **P0** | **API Key 暴露** | `AIService.ets:40` | DeepSeek API Key: `sk-bfc458a...` **必须立即迁移** |
| P1 | 隐私协议未验证 | `LoginPage.ets` | 勾选状态可被绕过 |
| P2 | 签名凭据 | `build-profile.json5` | 加密存储，但仍需注意 |

### 1.3 功能问题

| 优先级 | 问题 | 位置 | 说明 |
|--------|------|------|------|
| P0 | Mock 数据未清除 | `MyLikesPage.ets:21-25` | 数据库调用被注释，页面为空 |
| P0 | Mock 数据未清除 | `PendingTripsPage.ets:54-74` | 同上，替换为硬编码示例 |
| P1 | 职责重叠 | `TripDetailPage.ets` / `NewTripPage.ets` | 查看/编辑/新建职责不清 |
| P1 | 重复地图实现 | `ItineraryEditComponent.ets` | 与 NewTripPage 的 MapContainer 重复 |
| P2 | RouterManager 空实现 | `RouterManager.ets:106` | checkCanNavigate 始终返回 true |
| P2 | 成就系统占位 | `MineComponent.ets:88-121` | 硬编码静态数据，无实际功能 |
| P2 | 通知系统占位 | `NotificationPage.ets:14-36` | 硬编码列表，未接入 PushKit |
| P3 | Logger 扩展名不一致 | `utils/Logger.ts` | 其他文件均为 .ets |
| P3 | 日志混用 | 多个文件 | console.log 与 Logger 混用 |

### 1.4 各页面/模块功能说明

#### 页面层 (pages/)

| 文件 | 行数 | 核心功能 | 依赖服务 | 备注 |
|------|------|---------|---------|------|
| `Index.ets` | 615 | 首页：Banner轮播、功能入口、推荐行程 | Mock数据 | 大文件，需拆分 |
| `LoginPage.ets` | 234 | 登录：华为ID快捷登录 + 手机号密码 | AuthService | 有隐私协议漏洞 |
| `NewTripPage.ets` | 425 | 新建行程：行程基本信息录入、日期选择 | TripRepository, MapService | 有重复地图组件 |
| `TripDetailPage.ets` | 288 | 行程详情：查看/编辑已有行程 | TripRepository, RouteService | 职责与NewTripPage重叠 |
| `RecentTripsPage.ets` | 529 | 历史行程列表：筛选已完成行程 | TripRepository | 有重复TripCard |
| `PendingTripsPage.ets` | 354 | 待完成行程：筛选计划中/进行中的行程 | TripRepository | Mock数据未连接DB |
| `PlaceDetailPage.ets` | 509 | 景点详情：景点信息展示 + AI生成介绍 | MapService, AIService | PlaceCard嵌套在同文件 |
| `PlaceManagementPage.ets` | 155 | 地点管理：用户自定义地点列表 | PlaceService | |
| `AddPlacePage.ets` | 232 | 添加地点：新增自定义地点表单 | PlaceService | |
| `SearchPage.ets` | 255 | 搜索：关键字搜索地点 | MapService | |
| `NoteListPage.ets` | 339 | 笔记列表：分类查看所有笔记 | NoteRepository | |
| `NoteDetailPage.ets` | 330 | 笔记详情：查看/编辑笔记内容 | NoteRepository | Sidebar/ImageGallery未拆分 |
| `NoteEditPage.ets` | 222 | 笔记编辑：新建/编辑笔记 | NoteRepository | |
| `MyLikesPage.ets` | 203 | 我的点赞：收藏的笔记和地点列表 | LikeRepository | Mock数据未连接DB |
| `FeedbackPage.ets` | 148 | 反馈：提交用户反馈意见 | FeedbackRepository | |
| `AttractionInfoPage.ets` | 176 | AI景点介绍：AI生成的景点详细信息 | AIService | |
| `ProfileEditPage.ets` | 150 | 编辑个人资料 | AuthService | |
| `NotificationPage.ets` | 125 | 通知列表：系统通知展示 | Mock数据 | 硬编码列表，未接入PushKit |
| `DeviceSyncPage.ets` | 120 | 设备同步：设备间数据同步 | DeviceService | 占位页面 |
| `AdvicePage.ets` | 98 | 旅游建议：已分享的优质笔记 | NoteRepository | |

#### 服务层 (service/)

| 文件 | 行数 | 核心功能 | 外部依赖 |
|------|------|---------|---------|
| `AuthService.ets` | 128 | 用户认证：手机号+密码登录、Huawei ID登录 | @kit.AccountKit |
| `AIService.ets` | 283 | AI生成：景点介绍、路线优化（DeepSeek API） | DeepSeek API **⚠️ 有暴露Key** |
| `MapService.ets` | 271 | 地图搜索：地点搜索、地理编码、路线规划 | @kit.MapKit (site+navi) **⚠️ 与RouteService重复** |
| `RouteService.ets` | 110 | 路径规划：驾车路线规划、TSP优化 | @kit.MapKit (navi) **⚠️ 与MapService重复** |
| `PlaceService.ets` | 112 | 地点管理：自定义地点CRUD | RdbManager |
| `MyServiceWrapper.ets` | 89 | 综合服务封装：笔记/行程/点赞/反馈聚合 | 各DAO |

#### 视图层 (view/)

| 文件 | 行数 | 核心功能 | 使用页面 |
|------|------|---------|---------|
| `MapContainer.ets` | 177 | 地图组件：MapComponent封装、标记点、路径展示 | NewTripPage, ItineraryEditComponent |
| `MineComponent.ets` | 179 | 个人中心：头像、成就、统计 | Index |
| `ItineraryEditComponent.ets` | 403 | 行程编辑：**⚠️ 有重复地图实现** | TripDetailPage |
| `CreateTripDialog.ets` | 187 | 创建行程弹窗：行程名+地点+时间录入 | Index, TripDetailPage |

#### 视图模型层 (viewmodel/)

| 文件 | 行数 | 核心功能 | 使用页面 |
|------|------|---------|---------|
| `TripViewModel.ets` | 266 | 行程视图模型：按天分组地点、调用RouteService规划路线、TSP优化 | NewTripPage, TripDetailPage |

#### 数据层 (common/database/)

| 文件 | 行数 | 核心功能 | 处理的表 |
|------|------|---------|---------|
| `RdbManager.ets` | 742 | 数据库管理：**⚠️ 7张表全在一个文件** | note, trip, trip_place, user_like, saved_place, custom_place, feedback |

---

---

## 二、重构总体策略

### 2.1 执行顺序原则

```
架构优先：先分层(P2)再拆UI(P3)
不留 stubs：旧文件拆分后直接删除，不保留注释
Mock 保底：功能演示不受影响，待接后端时启用真实数据
```

### 2.2 分层架构目标

```
pages (页面层)
    ↓
service (业务服务层)     ← PlaceService, MyServiceWrapper, AIService, ConfigService
    ↓
dao (数据访问层)         ← TripDAO, LikeDAO, FeedbackDAO
    ↓
repository (仓储层) ★     ← NoteRepository, TripRepository, LikeRepository, 
                              PlaceRepository, FeedbackRepository (新增)
    ↓
RdbManager (数据层)       ← 降级为底层数据库连接，仅负责 init / createTables
    ↓
common/constants (常量)   ← AppConstants, ErrorCode
common/types (类型)      ← CommonTypes
common/utils (工具)       ← Logger, NetworkUtil
```

### 2.3 预期收益

| 维度 | 重构前 | 重构后 |
|------|--------|--------|
| 最大文件行数 | 742 行 | < 300 行 |
| 数据层职责 | 1 个文件 7 张表 | 1 个底层 + 5 个 Repository |
| 页面组件复用 | TripCard 在 2 处重复定义 | 独立组件，可复用 |
| Mock 数据 | 散落在多处 | 集中在 mock/ 目录 |
| 文档注解 | 几乎无 | 核心模块 100% 覆盖 |

---

## 三、执行阶段总览

| 阶段 | 名称 | 工期 | 核心任务 | 验证标准 |
|------|------|------|---------|---------|
| Phase 0 | 基础设施 | 2 天 | Logger 统一、创建常量/类型/规则文件 | 项目可编译运行 |
| Phase 1 | 代码清理 | 1 天 | 删除 Mock 注释、console→Logger、移除重复 | 项目可编译运行 |
| Phase 2 | 架构分层 | 3 天 | Repository 拆分、重构依赖关系 | 20 个页面全部可正常跳转 |
| Phase 3 | UI 拆分 | 3 天 | 6 个大页面拆为小组件 | UI 与重构前完全一致 |
| Phase 4 | 关键修复 | 2 天 | API Key 迁移、Mock 连接 DB、职责统一 | 功能逻辑与重构前一致 |
| Phase 5 | 注解文档 | 1 天 | JSDoc 添加、README 编写 | 所有模块有完整注解 |

### 并行任务：后端开发

| 时间 | 任务 | 交付物 |
|------|------|--------|
| Day 1-2 | 项目初始化 + 数据库设计 | Spring Boot 项目 + SQL 脚本 |
| Day 3-4 | 认证 + 笔记 CRUD | AuthController + NoteController |
| Day 5-6 | 行程 CRUD + AI 接口 | TripController + AIService |
| Day 7-8 | 点赞 + 反馈 + 统一响应 | LikeController + FeedbackController |
| Day 9-10 | 本地测试 + API 文档 | Swagger 文档 + 单元测试 |
| Day 11+ | 部署 + 前后端联调 | 线上可用版本 |

**预估总工期**: 前端约 12 天（可部分并行），后端约 10 天  
**安全机制**: 每阶段完成 → Git 提交 → 验证成功 → 下一阶段  
**回滚保障**: 每个阶段独立 Git tag，出现问题可直接回退

### 前后端并行时间线

```
Day 1-2:  Phase 0 (前端) + 后端项目初始化 (并行)
Day 3-5:   Phase 1 + Phase 2 (前端) + 后端 CRUD 开发 (并行)
Day 6-7:   Phase 3 (前端 UI 拆分) + 后端 AI 接口 (并行)
Day 8-10:  Phase 4 (前端关键修复) + 后端测试 (并行)
Day 11+:   Phase 5 (前端注解) + 前后端联调
```

> **重要**：前端重构期间使用 Mock 数据，不依赖后端。后端完成后仅需修改 1 行配置即可切换真实接口。

---

## 四、Phase 0: 基础设施搭建

**目标**: 建立重构基础设施，不改变任何业务逻辑  
**前置条件**: 无  
**Git 分支**: `refactor/phase-0-infrastructure`

### 0.1 统一工具类扩展名

- [ ] 将 `entry/src/main/ets/utils/Logger.ts` 重命名为 `Logger.ets`

### 0.2 重构 Logger.ets（统一日志）

**当前问题**: `Logger.ts` 使用 `console.info/debug/warn/error`，未使用 HarmonyOS hilog  
**修改内容**: 重构为使用 `hilog` 模块

```ets
import hilog from '@ohos.hilog';

export class Logger {
  private static readonly DOMAIN = 0x0000;
  private static readonly PREFIX = 'Anote';

  static info(tag: string, message: string, ...args: Object[]): void {
    hilog.info(DOMAIN, tag, `[${this.PREFIX}] ${message}`, args);
  }

  static warn(tag: string, message: string, ...args: Object[]): void {
    hilog.warn(DOMAIN, tag, `[${this.PREFIX}] ${message}`, args);
  }

  static error(tag: string, message: string, ...args: Object[]): void {
    hilog.error(DOMAIN, tag, `[${this.PREFIX}] ${message}`, args);
  }
}
```

### 0.3 创建 Cursor Rules

**文件**: `.cursor/rules/harmony-standards.mdc`

```markdown
---
description: HarmonyOS ArkTS 编码规范
alwaysApply: true
---
# HarmonyOS ArkTS 编码规范

## 文件命名
- 页面组件: `XxxPage.ets`
- 可复用组件: `XxxComponent.ets`
- Builder 组件: `XxxBuilder.ets` (放在所属页面目录下)
- 工具类: `XxxUtil.ets` 或 `XxxManager.ets`
- 常量: `AppConstants.ets`
- 类型: `XxxTypes.ets` 或 `CommonTypes.ets`

## 架构分层
- pages/ → 页面层 (只做 UI 组合，不含业务逻辑)
- service/ → 业务服务层
- dao/ → 数据访问层
- repository/ → 仓储层 (★新增)
- model/ → 数据模型层
- view/ → 可复用视图组件
- viewmodel/ → 视图模型
- common/ → 公共基础设施 (database, constants, types, utils)
```

**文件**: `.cursor/rules/project-architecture.mdc`

```markdown
---
description: Anote 项目架构约束
globs: entry/src/main/ets/**/*.ets
alwaysApply: true
---
# Anote 项目架构约束

## 禁止事项
1. **禁止**在 pages/ 目录下直接调用 RdbManager，应通过 service/ 或 dao/ 访问
2. **禁止**在 pages/ 目录下编写业务逻辑，应在 service/ 中实现
3. **禁止**硬编码 API Key，必须通过 ConfigService 读取
4. **禁止**使用 console.log，必须使用 Logger
5. **禁止**在单文件中定义超过 3 个 @Builder

## 必须事项
1. 每个 .ets 文件必须有 @file JSDoc 注释
2. 每个 service/repository/dao 必须有单例 getInstance()
3. 所有接口定义放在 model/ 或 common/types/
4. Mock 数据配置必须放在 `resources/rawfile/` 目录下，禁止放在 `src/mock/` 目录
```

### 0.4 创建常量和枚举

**文件**: `entry/src/main/ets/common/constants/AppConstants.ets`

```ets
/**
 * @file AppConstants.ets
 * @brief 应用全局常量定义
 * @description 集中管理分页大小、缓存 key、存储 key 等常量
 */
export class AppConstants {
  // ==================== 分页配置 ====================
  static readonly PAGE_SIZE_DEFAULT: number = 15;
  static readonly PAGE_SIZE_SMALL: number = 10;
  static readonly PAGE_SIZE_LARGE: number = 20;

  // ==================== 存储 Keys ====================
  static readonly PREF_AUTH: string = 'auth_prefs';
  static readonly PREF_AI_CACHE: string = 'ai_cache_store';
  static readonly STORAGE_KEY_IS_LOGIN: string = 'isLogin';
  static readonly STORAGE_KEY_USER_INFO: string = 'userInfo';
  static readonly STORAGE_KEY_SELECTED_SEARCH: string = 'selectedSearchResult';
  static readonly STORAGE_KEY_NETWORK_AVAILABLE: string = 'isNetworkAvailable';

  // ==================== AI 配置 ====================
  static readonly AI_CACHE_TTL_MS: number = 30 * 60 * 1000; // 30 min
  static readonly AI_REQUEST_TIMEOUT_MS: number = 60000;
  static readonly AI_MAX_RETRIES: number = 3;
  static readonly AI_MAX_TOKENS: number = 500;

  // ==================== 笔记分类 ====================
  static readonly NOTE_CATEGORIES: string[] = ['经验', '美食', '住宿', '交通', '景点'];
  static readonly NOTE_CATEGORY_DEFAULT: string = '经验';

  // ==================== 地点类型 ====================
  static readonly PLACE_TYPES: string[] = ['景点', '美食', '酒店', '交通', '购物', '其他'];
  static readonly PLACE_TYPE_DEFAULT: string = '景点';

  // ==================== 行程状态 ====================
  static readonly TRIP_STATUS_PLANNING: string = 'planning';
  static readonly TRIP_STATUS_ONGOING: string = 'ongoing';
  static readonly TRIP_STATUS_COMPLETED: string = 'completed';

  // ==================== 数据库配置 ====================
  static readonly DB_NAME: string = 'Anote.db';
  static readonly DB_SECURITY_LEVEL: string = 'S1';
}
```

**文件**: `entry/src/main/ets/common/constants/ErrorCode.ets`

```ets
/**
 * @file ErrorCode.ets
 * @brief 应用统一错误码枚举
 * @description 按模块分组，便于问题定位
 */
export enum ErrorCode {
  // ==================== 数据库错误 (1xxx) ====================
  DB_INIT_FAILED = 1001,
  DB_QUERY_FAILED = 1002,
  DB_INSERT_FAILED = 1003,
  DB_UPDATE_FAILED = 1004,
  DB_DELETE_FAILED = 1005,

  // ==================== 网络错误 (2xxx) ====================
  NETWORK_UNAVAILABLE = 2001,
  HTTP_REQUEST_FAILED = 2002,
  HTTP_TIMEOUT = 2003,

  // ==================== 认证错误 (3xxx) ====================
  AUTH_NOT_LOGIN = 3001,
  AUTH_INVALID_TOKEN = 3002,
  AUTH_PERMISSION_DENIED = 3003,

  // ==================== 业务错误 (4xxx) ====================
  VALIDATION_FAILED = 4001,
  DUPLICATE_RESOURCE = 4002,
  RESOURCE_NOT_FOUND = 4003,

  // ==================== AI 服务错误 (5xxx) ====================
  AI_SERVICE_ERROR = 5001,
  AI_API_KEY_INVALID = 5002,
  AI_REQUEST_TIMEOUT = 5003,
}
```

### 0.5 创建通用类型定义

**文件**: `entry/src/main/ets/common/types/CommonTypes.ets`

```ets
/**
 * @file CommonTypes.ets
 * @brief 应用通用类型定义
 * @description 抽取散布在各处的内联 interface，统一管理
 */

// ==================== 首页相关类型 ====================

/**
 * 首页 Banner 项目
 */
export interface BannerItem {
  id: number;
  imageSrc: string;
  title: string;
}

/**
 * 首页功能卡片
 */
export interface FunctionalCardItem {
  id: number;
  title: string;
  icon: ResourceStr;
  colors: [ResourceColor, number][];
  shadowColor: string;
}

/**
 * 首页推荐行程卡片
 */
export interface UserTripItem {
  id: number;
  userName: string;
  userAvatar: string;
  imageSrc: string;
  title: string;
  date: string;
  location: string;
  likes: number;
}

// ==================== 通知相关类型 ====================

/**
 * 通知项
 */
export interface NotificationItem {
  id: number;
  title: string;
  content: string;
  time: string;
  isRead: boolean;
}

// ==================== 搜索相关类型 ====================

/**
 * 搜索结果项 (SearchPage 内部使用)
 */
export interface SearchResult {
  id: number | string;
  title: string;
  address: string;
  type: string;
  icon?: string;
  latitude?: number;
  longitude?: number;
}

// ==================== 通用类型别名 ====================

/**
 * 行程状态
 */
export type TripStatus = 'planning' | 'ongoing' | 'completed';

/**
 * 点赞类型
 */
export type LikeType = 'note' | 'place';

/**
 * HTTP 请求方法
 */
export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
```

### 0.6 创建 Mock 数据目录

**文件**: `entry/resources/rawfile/mock-config.json`

```json5
{
  // Mock 数据配置
  // TODO: 待接入后端时，将此处配置设为启用
  enabled: false,
  
  // 首页推荐数据
  banners: [
    { id: 1, imageSrc: 'https://...', title: '瑞士阿尔卑斯山' },
    { id: 2, imageSrc: 'https://...', title: '马尔代夫群岛' },
  ],

  // 示例行程数据
  sampleTrips: [
    {
      id: 1,
      name: '示例行程 (测试数据)',
      location: '巴黎',
      status: 'planning',
    }
  ],

  // 示例通知
  notifications: [
    { id: 1, title: '系统通知', content: '欢迎使用旅游攻略助手！', time: '10:00', isRead: false }
  ]
}
```

### 0.7 验证清单

完成 Phase 0 后，逐项验证：

- [ ] `Logger.ets` 使用 hilog，项目可编译
- [ ] `.cursor/rules/` 下有 2 个规则文件
- [ ] `AppConstants.ets` 和 `ErrorCode.ets` 存在
- [ ] `CommonTypes.ets` 存在且包含所有内联 interface
- [ ] `entry/resources/rawfile/mock-config.json` 存在
- [ ] 编译日志无新增 error

### 0.8 Git 提交

```bash
git checkout -b refactor/phase-0-infrastructure
git add .
git commit -m "refactor(phase-0): 基础设施搭建

- 统一 Logger 为 .ets 扩展名，重构为 hilog
- 新增 Cursor 规则文件 (harmony-standards, project-architecture)
- 新增 AppConstants, ErrorCode 常量模块
- 新增 CommonTypes 统一类型定义
- 新增 resources/rawfile/mock-config.json Mock 数据配置
- 所有修改已验证可编译运行

tag: phase-0-infrastructure"
git tag phase-0-infrastructure
```

---

## 五、Phase 1: 代码清理

**目标**: 删除明显死代码和注释，不涉及逻辑修改  
**前置条件**: Phase 0 验证通过  
**Git 分支**: `refactor/phase-1-cleanup` (从 `phase-0-infrastructure` 拉出)

### 1.1 清理注释掉的 Mock 数据

#### MyLikesPage.ets (行 21-25)

**修改前**:
```ets
// MOCK DATA - Database operations removed for navigation testing
// this.notes = await RdbManager.getInstance().getLikedNotes();
// this.places = await RdbManager.getInstance().getLikedPlaces();
this.notes = [];
this.places = [];
```

**修改后**:
```ets
// @deprecated: 待接入后端后启用真实数据库调用
// this.notes = await RdbManager.getInstance().getLikedNotes();
// this.places = await RdbManager.getInstance().getLikedPlaces();
this.notes = [];  // TODO: 替换为上方真实调用
this.places = []; // TODO: 替换为上方真实调用
```

#### PendingTripsPage.ets (行 54-74)

**修改前**:
```ets
// MOCK DATA - Database operations removed for navigation testing
// const trips = await RdbManager.getInstance().getTrips(100, 0, this.searchText, 'all');
// const filtered = trips.filter(t => t.status === 'planning' || t.status === 'ongoing');
// this.trips = await this.enrichTrips(filtered);

this.trips = [
  {
    id: 1,
    name: '示例行程 (测试数据)',
    ...
  }
];
```

**修改后**:
```ets
// @deprecated: 待接入后端后启用真实数据库调用
// const trips = await RdbManager.getInstance().getTrips(100, 0, this.searchText, 'all');
// const filtered = trips.filter(t => t.status === 'planning' || t.status === 'ongoing');
// this.trips = await this.enrichTrips(filtered);
this.trips = [
  {
    id: 1,
    name: '示例行程 (测试数据)',
    ...
  }
];  // TODO: 替换为上方真实调用
```

#### FeedbackPage.ets (行 21-22)

**修改前**:
```ets
// MOCK ACTION - Database operations removed for navigation testing
// await MyServiceWrapper.getInstance().submitFeedback(this.content, this.contact);
await new Promise<void>(resolve => setTimeout(resolve, 1000));
```

**修改后**:
```ets
// @deprecated: 待接入后端后启用真实数据库调用
// await MyServiceWrapper.getInstance().submitFeedback(this.content, this.contact);
await new Promise<void>(resolve => setTimeout(resolve, 1000)); // TODO: 替换为真实调用
```

### 1.2 清理 Index.ets 的 Mock 数据

**文件**: `Index.ets` (行 75-160)

删除内联硬编码数据：

- `@State banners: BannerItem[]` 数组 (行 76-92) → 改为从服务获取或标注 TODO
- `@State functionalCards: FunctionalCardItem[]` 数组 (行 94-127) → 可保留（功能入口定义）
- `@State userTrips: UserTripItem[]` 数组 (行 129-160) → 改为从服务获取或标注 TODO

```ets
// @deprecated: 首页推荐数据应从后端API获取
// @see TripService.getRecommendedTrips()
@State banners: BannerItem[] = []; // TODO: 接入后端后改为真实数据
@State userTrips: UserTripItem[] = []; // TODO: 接入后端后改为真实数据
```

### 1.3 统一日志调用

**目标**: 所有 `console.log/info/error/warn` 替换为 `Logger`

需检查替换的文件：

| 文件 | 当前使用 console 的行数 | 优先级 |
|------|----------------------|--------|
| `RdbManager.ets` | ~15 处 | P1 |
| `AIService.ets` | ~8 处 | P1 |
| `PlaceService.ets` | ~4 处 | P2 |
| `MapService.ets` | ~10 处 | P2 |
| `AuthService.ets` | ~2 处 | P2 |
| `TripViewModel.ets` | ~3 处 | P2 |
| `NoteListPage.ets` | ~2 处 | P2 |
| 其他页面文件 | 各 1-3 处 | P3 |

**替换规则**:
```typescript
// 替换前
console.info(`[DEBUG] TripDAO: 获取待完成行程`);

// 替换后
Logger.info('TripDAO', '获取待完成行程');
```

### 1.4 移除重复定义

#### 重复的 TripViewModel 接口

以下文件各自定义了 `TripViewModel extends Trip`:

- `PendingTripsPage.ets` (行 8-12)
- `RecentTripsPage.ets` (行 7-11)
- `TripDetailPage.ets` (行 14-16)

**处理**: 删除页面内的重复定义，直接 import `TripWithPlaces` from `TripModel.ets`

#### 空回调清理

`CreateTripDialog.ets` (行 17-18):

```ets
cancel: () => void = () => {}  // 空实现从未使用
```

改为:

```ets
// @deprecated: cancel 回调暂未使用
cancel: (() => void) | undefined = undefined;
```

### 1.5 验证清单

- [ ] `MyLikesPage.ets` Mock 数据有 `@deprecated` 标注
- [ ] `PendingTripsPage.ets` Mock 数据有 `@deprecated` 标注
- [ ] `FeedbackPage.ets` Mock 数据有 `@deprecated` 标注
- [ ] `Index.ets` banners 和 userTrips 有 TODO 标注
- [ ] RdbManager.ets 所有 console.* 替换为 Logger
- [ ] AIService.ets 所有 console.* 替换为 Logger
- [ ] 重复的 TripViewModel 接口已移除
- [ ] 项目可编译运行
- [ ] 主要页面可正常打开

### 1.6 Git 提交

```bash
git checkout -b refactor/phase-1-cleanup
git add .
git commit -m "refactor(phase-1): 代码清理

- 清理 Mock 数据，统一添加 @deprecated 标注
- 清理 Index.ets 内联硬编码推荐数据
- 统一所有 console.* 为 Logger
- 移除 PendingTrips/RecentTrips/TripDetail 中的重复 TripViewModel 定义
- 所有修改已验证可编译运行

tag: phase-1-cleanup"
git tag phase-1-cleanup
```

---

## 六、Phase 2: 架构分层

**目标**: 建立 Repository 层，拆分 RdbManager，重构依赖关系  
**前置条件**: Phase 1 验证通过  
**Git 分支**: `refactor/phase-2-architecture` (从 `phase-1-cleanup` 拉出)

### 2.1 拆分 RdbManager

**当前**: `RdbManager.ets` 742 行处理 7 张表的所有 CRUD  
**目标**: 降级为底层连接器，CRUD 职责分散到 5 个 Repository

#### 步骤 2.1.1: 创建 Repository 基接口

**文件**: `entry/src/main/ets/repository/IRepository.ets` (新建)

```ets
/**
 * @file IRepository.ets
 * @brief Repository 基接口
 * @description 定义所有 Repository 必须实现的标准方法
 */
export interface IRepository<T> {
  /**
   * 根据 ID 获取单条记录
   * @param id - 记录 ID
   * @returns 记录实体或 null
   */
  getById(id: number): Promise<T | null>;

  /**
   * 获取所有记录
   * @returns 记录列表
   */
  getAll(): Promise<T[]>;

  /**
   * 插入新记录
   * @param entity - 记录实体
   * @returns 新记录 ID
   */
  insert(entity: T): Promise<number>;

  /**
   * 更新记录
   * @param entity - 记录实体
   * @returns 受影响行数
   */
  update(entity: T): Promise<number>;

  /**
   * 删除记录
   * @param id - 记录 ID
   * @returns 受影响行数
   */
  delete(id: number): Promise<number>;
}
```

#### 步骤 2.1.2: 创建 NoteRepository

**文件**: `entry/src/main/ets/repository/NoteRepository.ets` (新建)

职责: `note` 表的完整 CRUD

```ets
/**
 * @file NoteRepository.ets
 * @brief 笔记数据访问层
 * @description 负责 Note 实体的数据库 CRUD 操作
 */
import { Note } from '../model/NoteModel';
import { RdbManager } from '../common/database/RdbManager';
import { Logger } from '../common/utils/Logger';

const TAG = 'NoteRepository';

export class NoteRepository {
  // ==================== 基础 CRUD ====================

  async getById(id: number): Promise<Note | null> {
    const notes = await this.query({ id, limit: 1 });
    return notes.length > 0 ? notes[0] : null;
  }

  async getAll(): Promise<Note[]> {
    return this.query({});
  }

  async insert(note: Note): Promise<number> {
    Logger.info(TAG, 'insert: Creating note', [note.title]);
    return RdbManager.getInstance().insertNote(note);
  }

  async update(note: Note): Promise<number> {
    Logger.info(TAG, 'update: Updating note', [note.id]);
    return RdbManager.getInstance().updateNote(note);
  }

  async delete(id: number): Promise<number> {
    Logger.info(TAG, 'delete: Deleting note', [id]);
    return RdbManager.getInstance().deleteNote(id);
  }

  // ==================== 高级查询 ====================

  /**
   * 分页查询笔记
   * @param page - 页码 (从 0 开始)
   * @param pageSize - 每页数量
   * @param isShared - 是否分享 (undefined = 全部)
   * @param category - 分类 (undefined = 全部)
   */
  async query(params: {
    id?: number;
    limit?: number;
    offset?: number;
    isShared?: boolean;
    category?: string;
  }): Promise<Note[]> {
    const { limit, offset, isShared, category } = params;
    return RdbManager.getInstance().getNotes(limit, offset, isShared, category);
  }
}
```

#### 步骤 2.1.3: 创建 TripRepository

**文件**: `entry/src/main/ets/repository/TripRepository.ets` (新建)

职责: `trip` 表 + `trip_place` 表的完整 CRUD

#### 步骤 2.1.4: 创建 LikeRepository

**文件**: `entry/src/main/ets/repository/LikeRepository.ets` (新建)

职责: `user_like` 表操作 + 点赞关联查询

#### 步骤 2.1.5: 创建 PlaceRepository

**文件**: `entry/src/main/ets/repository/PlaceRepository.ets` (新建)

职责: `saved_place` 表 + `custom_place` 表的完整 CRUD

#### 步骤 2.1.6: 创建 FeedbackRepository

**文件**: `entry/src/main/ets/repository/FeedbackRepository.ets` (新建)

职责: `feedback` 表的完整 CRUD

#### 步骤 2.1.7: 降级 RdbManager

**文件**: `entry/src/main/ets/common/database/RdbManager.ets`

删除所有业务方法，只保留:

- `init(context)`
- `getInstance()`
- `createTables()`
- 底层 `insert/update/delete/query` 基础方法

### 2.2 重构 DAO 层

当前: DAO 直接调用 RdbManager  
目标: DAO 调用对应的 Repository

```ets
// TripDAO 重构前
import { RdbManager } from '../common/database/RdbManager';
export class TripDAO {
  async getPendingTrips(): Promise<Trip[]> {
    const allTrips = await RdbManager.getInstance().getTrips(100, 0, '', 'all');
    return allTrips.filter(t => t.status === 'planning' || t.status === 'ongoing');
  }
}

// TripDAO 重构后
import { TripRepository } from '../repository/TripRepository';
export class TripDAO {
  private repository = new TripRepository();

  async getPendingTrips(): Promise<Trip[]> {
    const allTrips = await this.repository.getAll();
    return allTrips.filter(t => t.status === 'planning' || t.status === 'ongoing');
  }
}
```

重构顺序:

1. `TripDAO` → 依赖 `TripRepository`
2. `LikeDAO` → 依赖 `LikeRepository`
3. `FeedbackDAO` → 依赖 `FeedbackRepository`

### 2.3 重构 Service 层

1. `PlaceService` → 依赖 `PlaceRepository`
2. `MyServiceWrapper` → 依赖所有 DAO (保持不变)

### 2.4 页面层逐步迁移

迁移顺序（按依赖关系）:

1. `NoteListPage` / `NoteDetailPage` / `NoteEditPage` → `NoteRepository`
2. `RecentTripsPage` / `PendingTripsPage` / `NewTripPage` / `TripDetailPage` → `TripRepository`
3. `PlaceDetailPage` → `LikeRepository` / `PlaceRepository`
4. `FeedbackPage` → `FeedbackRepository`
5. `PlaceManagementPage` / `AddPlacePage` → `PlaceRepository`

### 2.5 验证清单

- [ ] 5 个 Repository 文件全部创建
- [ ] RdbManager 精简至 < 200 行
- [ ] 3 个 DAO 重构完成
- [ ] 所有 Service 重构完成
- [ ] 20 个页面全部可正常编译
- [ ] 所有页面跳转正常（重点测试: 笔记 CRUD / 行程 CRUD）

### 2.6 Git 提交

```bash
git checkout -b refactor/phase-2-architecture
git add .
git commit -m "refactor(phase-2): 架构分层

- 新增 Repository 层: NoteRepository, TripRepository, LikeRepository,
  PlaceRepository, FeedbackRepository
- RdbManager 降级为底层连接器，精简至 < 200 行
- 重构 DAO 层: TripDAO/LikeDAO/FeedbackDAO 依赖对应 Repository
- 重构 Service 层: PlaceService 依赖 PlaceRepository
- 页面层逐步迁移: 所有页面通过 Repository 访问数据
- 所有修改已验证可编译运行，20个页面跳转正常

tag: phase-2-architecture"
git tag phase-2-architecture
```

---

## 七、Phase 3: UI 组件拆分

**目标**: 将超长页面拆分为小组件，不改变 UI 逻辑  
**前置条件**: Phase 2 验证通过  
**Git 分支**: `refactor/phase-3-ui-split` (从 `phase-2-architecture` 拉出)

### 3.1 拆分策略

每个页面拆分为:
- `主页面.ets` — Tab 容器 + 组合子组件 (< 300 行)
- `子组件1.ets` — 可复用的 @Component
- `子组件2.ets` — 可复用的 @Component
- ...

### 3.2 Index.ets 拆分 (615 → 5 个文件)

```
pages/Index.ets (主容器, ~200行)
  ↓ 组合
view/index/TopBar.ets          (顶部搜索栏)
view/index/BannerView.ets       (轮播图)
view/index/FeatureGrid.ets      (四宫格)
view/index/TripFeed.ets         (推荐列表)
```

### 3.3 RecentTripsPage.ets 拆分 (529 → 4 个文件)

```
pages/RecentTripsPage.ets (主容器, ~200行)
  ↓ 组合
view/trip/TripFilterBar.ets    (筛选栏, 新建)
view/trip/TripCard.ets         (行程卡片, 从 PendingTripsPage 抽取)
view/trip/TripListView.ets     (列表逻辑)
```

### 3.4 PlaceDetailPage.ets 拆分 (509 → 3 个文件)

```
pages/PlaceDetailPage.ets (主容器, ~200行)
  ↓ 组合
view/place/PlaceCard.ets       (景点卡片 @Component)
view/place/PlaceSwiperContent.ets (Swiper包装)
```

### 3.5 NewTripPage.ets 拆分 (425 → 4 个文件)

```
pages/NewTripPage.ets (主容器, ~200行)
  ↓ 组合
view/trip/TripTopBar.ets       (顶部输入栏)
view/trip/DayTabBar.ets        (天数Tab)
view/trip/PlaceItemBuilder.ets (地点列表项)
```

### 3.6 NoteDetailPage.ets 拆分 (330 → 3 个文件)

```
pages/NoteDetailPage.ets (主容器, ~180行)
  ↓ 组合
view/note/SidebarContent.ets   (右侧边栏)
view/note/ImageGallery.ets     (图片轮播)
```

### 3.7 验证清单

- [ ] 6 个主页面文件均 < 300 行
- [ ] 所有子组件抽离为独立 .ets 文件
- [ ] TripCard 在 RecentTripsPage 和 PendingTripsPage 中复用同一文件
- [ ] UI 表现与拆分前完全一致（逐页面截图对比）
- [ ] 项目可编译运行

### 3.8 Git 提交

```bash
git commit -m "refactor(phase-3): UI组件拆分

- 拆分 Index.ets: TopBar, BannerView, FeatureGrid, TripFeed
- 拆分 RecentTripsPage.ets: TripFilterBar, TripCard(复用), TripListView
- 拆分 PlaceDetailPage.ets: PlaceCard, PlaceSwiperContent
- 拆分 NewTripPage.ets: TripTopBar, DayTabBar, PlaceItemBuilder
- 拆分 NoteDetailPage.ets: SidebarContent, ImageGallery
- 所有主页面文件均控制在 300 行以内
- TripCard 抽取为独立组件，供两处复用
- UI 表现验证与重构前完全一致

tag: phase-3-ui-split"
git tag phase-3-ui-split
```

---

## 八、Phase 4: 关键问题修复

**目标**: 修复安全问题和功能缺陷  
**前置条件**: Phase 3 验证通过  
**Git 分支**: `refactor/phase-4-critical-fix` (从 `phase-3-ui-split` 拉出)

### 4.1 API Key 安全迁移

#### 步骤 1: 创建配置文件

**文件**: `entry/src/main/resources/base/profile/app_config.json` (新建)

```json
{
  "ai": {
    "provider": "deepseek",
    "apiUrl": "https://api.deepseek.com/v1/chat/completions",
    "model": "deepseek-chat",
    "apiKey": "YOUR_API_KEY_HERE"
  },
  "map": {
    "apiKey": "YOUR_MAP_API_KEY_HERE"
  }
}
```

> 注意: 此文件应加入 `.gitignore`，避免提交真实 key

#### 步骤 2: 创建 ConfigService

**文件**: `entry/src/main/ets/service/ConfigService.ets` (新建)

```ets
/**
 * @file ConfigService.ets
 * @brief 配置服务
 * @description 统一读取 app_config.json 配置文件
 */
export class ConfigService {
  private static instance: ConfigService;
  private config: Record<string, Object> = {};

  static getInstance(): ConfigService { ... }

  async init(context: common.UIAbilityContext): Promise<void> {
    // 从 app_config.json 读取配置
  }

  getAIConfig(): { apiKey: string; apiUrl: string; model: string } {
    return this.config['ai'] as any;
  }
}
```

#### 步骤 3: 修改 AIService

```ets
// 修改前
private readonly API_KEY = 'sk-bfc458a122374f1f82353c2b4d7b58d6';

// 修改后
private readonly API_KEY: string = ConfigService.getInstance().getAIConfig().apiKey;
```

### 4.2 Mock 页面连接真实数据库

#### MyLikesPage.ets

取消 `@deprecated` 注释，连接 `LikeRepository`:

```ets
aboutToAppear() {
  this.refreshData();
}

async refreshData() {
  this.isLoading = true;
  try {
    this.notes = await this.likeRepository.getLikedNotes();
    this.places = await this.likeRepository.getLikedPlaces();
  } catch (e) {
    // @deprecated: 降级到 Mock 数据
    this.notes = [];
    this.places = [];
  } finally {
    this.isLoading = false;
  }
}
```

#### PendingTripsPage.ets

取消 `@deprecated` 注释，连接 `TripRepository`:

```ets
async refreshData() {
  try {
    const allTrips = await this.tripRepository.getAll();
    this.trips = this.enrichTrips(
      allTrips.filter(t => t.status === 'planning' || t.status === 'ongoing')
    );
  } catch (e) {
    // @deprecated: 降级到 Mock 数据
    this.trips = [{ id: 1, name: '示例行程', ... }];
  }
}
```

### 4.3 TripDetailPage 职责统一

**问题**: `TripDetailPage` 和 `NewTripPage` 职责重叠  
**解决**:

- `TripDetailPage` → 只做查看 + 编辑已有行程
- `NewTripPage` → 只做新建行程
- `ItineraryEditComponent` → 抽取为共享的行程编辑组件，两页面共用

### 4.4 验证清单

- [ ] `app_config.json` 创建完成
- [ ] `ConfigService` 创建完成
- [ ] `AIService` 不再包含硬编码 API Key
- [ ] `MyLikesPage` 正常显示点赞数据
- [ ] `PendingTripsPage` 正常显示待完成行程
- [ ] `TripDetailPage` 和 `NewTripPage` 职责清晰分离
- [ ] 项目可编译运行

### 4.5 Git 提交

```bash
git commit -m "fix(phase-4): 关键问题修复

- 新增 app_config.json 配置文件 (API Key 迁移)
- 新增 ConfigService 统一读取配置
- AIService 不再包含硬编码 API Key
- MyLikesPage 连接真实 LikeRepository
- PendingTripsPage 连接真实 TripRepository
- 统一 TripDetailPage/NewTripPage 职责
- 所有功能验证正常

tag: phase-4-critical-fix"
git tag phase-4-critical-fix
```

---

## 九、Phase 5: 注解与文档

**目标**: 所有核心模块添加完整 JSDoc，创建项目文档  
**前置条件**: Phase 4 验证通过  
**Git 分支**: `refactor/phase-5-docs` (从 `phase-4-critical-fix` 拉出)

### 5.1 模块级 JSDoc 规范

每个 `.ets` 文件头添加:

```ets
/**
 * @file XxxRepository.ets
 * @brief 简短描述
 * @description 详细描述职责、使用方式、依赖关系
 * @author Anote Team
 * @version 1.0.0
 * @date 2026-03-30
 * @see 相关模块
 * @deprecated 废弃说明 (如有)
 */
```

### 5.2 注解覆盖清单

| 层级 | 文件 | 注解级别 |
|------|------|---------|
| repository | 5 个 Repository | 文件 + 所有方法 |
| service | AIService, AuthService, PlaceService, ConfigService, MyServiceWrapper | 文件 + 所有方法 |
| dao | 3 个 DAO | 文件 + 所有方法 |
| model | 3 个 Model | 文件 + 所有接口字段 |
| view | 10+ 个组件 | 文件 |
| pages | 20 个页面 | 文件 |
| utils | Logger, NetworkUtil | 文件 + 所有方法 |

### 5.3 创建 README.md

**文件**: `README.md` (项目根目录)

```markdown
# Anote - 旅游攻略助手

## 项目简介
...

## 目录结构

```
entry/src/main/ets/
├── pages/           # 页面层 (20个页面)
├── service/         # 业务服务层
├── dao/             # 数据访问层
├── repository/      # 仓储层 ★
├── model/           # 数据模型层
├── view/            # 可复用视图组件
├── viewmodel/      # 视图模型
└── common/          # 公共基础设施
    ├── database/    # 数据库管理
    ├── constants/   # 常量定义
    ├── types/       # 类型定义
    └── utils/       # 工具类
```

## 分层架构

[分层架构图]

## 模块说明

### Repository 层
...

### Service 层
...

## 开发指南

### 环境配置
...

### 添加新页面
...

### 添加新数据模型
...
```

### 5.4 验证清单

- [ ] 所有 Repository 文件有完整 JSDoc
- [ ] 所有 Service 文件有完整 JSDoc
- [ ] 所有 DAO 文件有完整 JSDoc
- [ ] 所有 Model 文件有完整 JSDoc
- [ ] README.md 包含完整项目文档
- [ ] 项目可编译运行

### 5.5 Git 提交

```bash
git commit -m "docs(phase-5): 注解与文档

- 所有 Repository 文件添加 JSDoc (文件 + 方法)
- 所有 Service 文件添加 JSDoc (文件 + 方法)
- 所有 DAO 文件添加 JSDoc (文件 + 方法)
- 所有 Model 文件添加 JSDoc (文件 + 接口字段)
- 所有 View 组件添加 JSDoc
- 创建完整的 README.md 项目文档
- 重构全部完成

tag: phase-5-docs"
git tag phase-5-docs
git checkout main
git merge refactor/phase-5-docs
git tag v2.0.0-refactored
```

---

## 十、Git 分支管理规范

### 10.1 分支命名

```
main                          # 稳定版本
refactor/phase-0-infrastructure  # Phase 0
refactor/phase-1-cleanup        # Phase 1
refactor/phase-2-architecture    # Phase 2
refactor/phase-3-ui-split        # Phase 3
refactor/phase-4-critical-fix    # Phase 4
refactor/phase-5-docs           # Phase 5
```

### 10.2 每个 Phase 的 Git 工作流

```
1. 从上一个 phase 的 tag 拉出新分支
   git checkout -b refactor/phase-X-xxx

2. 完成开发和自测

3. 提交代码
   git add .
   git commit -m "描述..."

4. 打 tag 标记阶段完成
   git tag phase-X-xxx

5. 推送 tag
   git push origin phase-X-xxx
   git push origin --tags

6. 切换到 main 并合并
   git checkout main
   git merge refactor/phase-X-xxx
```

### 10.3 回滚命令

```bash
# 回滚到任意阶段
git checkout phase-0-infrastructure
# 或
git reset --hard phase-3-ui-split
```

---

## 十一、验证机制

### 11.1 每阶段验证标准

| 阶段 | 最低验证要求 |
|------|-------------|
| Phase 0 | 项目可编译，无新增 error |
| Phase 1 | 所有 console.* 替换为 Logger，项目可编译 |
| Phase 2 | 20 个页面全部可跳转，数据库 CRUD 正常 |
| Phase 3 | UI 表现与重构前一致，无视觉差异 |
| Phase 4 | Mock 页面显示真实数据，API Key 不暴露 |
| Phase 5 | 核心模块 100% 注解覆盖 |

### 11.2 验证检查清单

每个阶段完成后，执行以下检查:

```bash
# 1. 编译检查
npm run build  # 或 hvigor 构建

# 2. 页面完整性检查 (20个页面)
grep -c "export default" pages/*.ets  # 应为 20

# 3. 日志规范性检查
grep -r "console\." entry/src/main/ets/  # 应为 0 (除 Logger.ets 内部)

# 4. API Key 检查
grep -r "sk-" entry/src/main/ets/  # 应为 0 (ConfigService 除外)

# 5. Mock 数据标注检查
grep -r "@deprecated" entry/src/main/ets/  # 应 > 0
```

### 11.3 功能回归测试

| 功能模块 | 测试用例 |
|---------|---------|
| 笔记 | 新建笔记 → 编辑笔记 → 删除笔记 → 查看列表 |
| 行程 | 新建行程 → 添加景点 → AI 规划 → 保存行程 |
| 收藏 | 点赞笔记 → 点赞景点 → 我的点赞页面查看 |
| 登录 | 手机号注册 → 登录 → 退出登录 |
| 搜索 | 搜索景点 → 选择景点 → 添加到行程 |
| 地图 | 地图加载 → 标记点显示 → 路径规划显示 |

---

## 十二、紧急回滚方案

### 12.1 自动回滚触发条件

遇到以下情况，立即触发回滚:

1. 编译 error 无法在 2 小时内解决
2. 页面跳转 404 (路由错误)
3. 数据丢失 (CRUD 异常)
4. UI 严重错位 (> 3 个页面)

### 12.2 回滚操作流程

```bash
# 1. 确认当前阶段
git status

# 2. 查看所有 tag
git tag -l

# 3. 回滚到上一个稳定阶段
git checkout main
git reset --hard [上一个成功的 tag]

# 4. 通知团队
echo "已回滚到 [tag], 问题原因: ..."

# 5. 分析问题后重新开始该阶段
git checkout -b refactor/phase-X-retry
```

### 12.3 风险预案

| 风险 | 概率 | 影响 | 预案 |
|------|------|------|------|
| 编译失败 | 低 | 中 | 回滚至上一个 tag，修复后重试 |
| 页面空白 | 低 | 高 | 检查路由配置，逐页面验证 |
| 数据丢失 | 极低 | 严重 | 回滚 + 数据恢复 |
| UI 错位 | 中 | 中 | 逐页面截图对比，定位差异 |

---

## 十三、后期扩展功能清单

以下功能可在重构完成后按优先级逐步添加:

### P0 - 核心功能补全

| 功能 | 说明 | 依赖 |
|------|------|------|
| 后端 API 接入 | 将 Mock 数据替换为真实 API | Phase 4 完成 |
| 用户认证后端 | 华为 AppGallery Connect | ConfigService |
| 笔记图片上传 | 华为云存储服务 | Phase 5 完成 |

### P1 - 体验优化

| 功能 | 说明 | 实现难度 |
|------|------|---------|
| 离线地图 | 下载地图瓦片包 | 高 |
| 行程导出 PDF | 生成精美行程单 | 低 |
| Push 通知 | 行程提醒、活动通知 | 低 |
| 天气插件 | 行程日期天气预览 | 低 |

### P2 - 社交功能

| 功能 | 说明 | 实现难度 |
|------|------|---------|
| 社交分享 | 分享到微信/微博 | 中 |
| 用户成就系统 | 旅行打卡、徽章 | 低 |
| AI 智能推荐 | 基于用户偏好的景点推荐 | 高 |

### P3 - 高级功能

| 功能 | 说明 | 实现难度 |
|------|------|---------|
| 云端数据同步 | 华为云 RDS / 对象存储 | 高 |
| AR 景点导览 | 摄像头 AR 叠加信息 | 高 |
| 语音导览 | 景点语音介绍播放 | 中 |

---

| 2026-03-30 | v1.0 | 初稿创建 | Claude |

---

## 十四、后端规划（并行）

> **重要说明**：后端与前端重构并行执行，不互相阻塞。
> 前端使用 Mock 数据完成重构，后端完成后通过配置切换即可切换到真实接口。

### 14.1 技术选型决策

#### 14.1.1 后端技术选型：Java Spring Boot

| 维度 | 华为云函数 | Java Spring Boot | 说明 |
|------|-----------|-----------------|------|
| 部署复杂度 | 低（一键部署） | 中（需服务器/VPS） | 华为云函数更简单 |
| 调试体验 | 差（日志不直观） | 好（本地 Debug） | Spring Boot 本地可断点 |
| AI 对接 | 受限（30s 超时） | 无限制 | AI 生成景点介绍可能 > 30s |
| 数据库访问 | VPC 配置复杂 | 直连 RDS | Spring Boot 更灵活 |
| 生态成熟度 | 一般 | 非常成熟 | Spring Boot 资料更多 |
| **综合推荐** | ❌ | **推荐** | 1 周速成选 Spring Boot |

**最终选择：Java Spring Boot**
- 开发工具：IntelliJ IDEA / VS Code + Spring Boot
- 部署：华为云 ECS 或自建服务器（或容器化）
- 数据库：华为云 RDS MySQL

#### 14.1.2 前端 Mock 策略

**开发阶段**：前端所有接口使用 Mock 数据（Phase 4 中的 `@deprecated` 标注位置）  
**联调阶段**：修改配置文件 `entry/resources/rawfile/mock-config.json` 中 `enabled: true` 即可切换真实接口

```json5
{
  // mock-config.json
  enabled: true,   // 改为 true 启用真实 API
  baseUrl: 'http://your-server:8080/api',  // 后端地址
  
  // 可分模块控制
  modules: {
    note: true,      // 笔记启用真实 API
    trip: false,     // 行程仍用 Mock
    user: false,     // 用户仍用 Mock
  }
}
```

---

### 14.2 项目结构

#### 14.2.1 仓库结构

```
e:\HarmonyOS\                    # 当前前端项目
└── Anote\                       # 前端代码 (HarmonyOS)

e:\HarmonyOS\                    # 同级目录
└── backend-anote\                # 后端项目 (新建)
    ├── src/main/java/com/anote/
    │   ├── controller/          # REST 控制器
    │   ├── service/             # 业务逻辑
    │   ├── repository/          # 数据访问
    │   ├── model/               # 实体类
    │   ├── config/              # 配置类
    │   ├── dto/                 # 数据传输对象
    │   └── util/                # 工具类
    ├── src/main/resources/
    │   └── application.yml     # Spring Boot 配置
    ├── pom.xml                  # Maven 依赖
    └── README.md                # 后端文档
```

#### 14.2.2 后端包结构

```
com.anote
├── AnoteApplication.java       # 启动类
├── config/
│   ├── CorsConfig.java         # 跨域配置
│   ├── SecurityConfig.java      # 安全配置 (可选)
│   └── WebConfig.java          # Web 配置
├── controller/
│   ├── AuthController.java     # 认证接口
│   ├── NoteController.java     # 笔记 CRUD
│   ├── TripController.java     # 行程 CRUD
│   ├── PlaceController.java    # 地点管理
│   ├── LikeController.java     # 点赞接口
│   └── FeedbackController.java  # 反馈接口
├── service/
│   ├── AuthService.java
│   ├── NoteService.java
│   ├── TripService.java
│   ├── PlaceService.java
│   └── AIService.java          # AI 生成景点介绍
├── repository/
│   ├── NoteRepository.java
│   ├── TripRepository.java
│   ├── UserRepository.java
│   └── PlaceRepository.java
├── model/
│   ├── Note.java
│   ├── Trip.java
│   ├── TripPlace.java
│   ├── User.java
│   └── CustomPlace.java
├── dto/
│   ├── request/                # 请求 DTO
│   └── response/               # 响应 DTO (统一格式)
└── util/
    ├── Result.java             # 统一响应封装
    └── JwtUtil.java           # JWT 工具
```

---

### 14.3 数据库设计

#### 14.3.1 ER 图

```
┌─────────┐     ┌─────────┐     ┌──────────────┐
│  User   │────<│  Note   │     │  TripPlace  │
│  用户   │     │  笔记   │     │   行程景点   │
└─────────┘     └─────────┘     └──────────────┘
                       │                 │
                       │              ┌────┴────┐
                       │              │  Trip   │
                       │              │  行程   │
                       ▼              └─────────┘
                 ┌──────────┐
                 │ Feedback │   ┌──────────────┐
                 │  反馈   │   │ CustomPlace │
                 └──────────┘   │  自定义地点  │
                                └──────────────┘
```

#### 14.3.2 数据表定义

```sql
-- 用户表
CREATE TABLE user (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,        -- BCrypt 加密
    phone VARCHAR(20) UNIQUE,
    nickname VARCHAR(50),
    avatar VARCHAR(255),
    signature VARCHAR(200),
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 笔记表
CREATE TABLE note (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    title VARCHAR(100) NOT NULL,
    content TEXT,
    location VARCHAR(100),
    images JSON,                          -- JSON 数组
    category VARCHAR(20) DEFAULT '经验',
    is_shared BOOLEAN DEFAULT FALSE,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(id)
);

-- 行程表
CREATE TABLE trip (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    cover_image VARCHAR(255),
    status ENUM('planning','ongoing','completed') DEFAULT 'planning',
    start_date DATETIME,
    end_date DATETIME,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(id)
);

-- 行程景点表
CREATE TABLE trip_place (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    trip_id BIGINT NOT NULL,
    title VARCHAR(100) NOT NULL,
    type VARCHAR(20),
    address VARCHAR(200),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    distance_km DECIMAL(10,2),
    duration_min INT,
    note TEXT,
    order_index INT DEFAULT 0,
    day_index INT DEFAULT 0,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES trip(id) ON DELETE CASCADE
);

-- 点赞表
CREATE TABLE user_like (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    target_id BIGINT NOT NULL,
    type ENUM('note','place') NOT NULL,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(id),
    UNIQUE KEY uk_user_target (user_id, target_id, type)
);

-- 自定义地点表
CREATE TABLE custom_place (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    type VARCHAR(20),
    contact VARCHAR(50),
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(id)
);

-- 反馈表
CREATE TABLE feedback (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    content TEXT NOT NULL,
    contact VARCHAR(50),
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

---

### 14.4 API 接口规范

#### 14.4.1 统一响应格式

```java
// Result.java
public class Result<T> {
    private int code;       // 状态码
    private String msg;     // 消息
    private T data;         // 数据

    public static <T> Result<T> success(T data) {
        return new Result<>(200, "success", data);
    }

    public static <T> Result<T> error(String msg) {
        return new Result<>(500, msg, null);
    }
}
```

#### 14.4.2 接口列表

| 模块 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 认证 | POST | `/api/auth/register` | 注册 |
| 认证 | POST | `/api/auth/login` | 登录 |
| 认证 | POST | `/api/auth/logout` | 登出 |
| 笔记 | GET | `/api/notes` | 分页获取笔记 |
| 笔记 | GET | `/api/notes/{id}` | 获取笔记详情 |
| 笔记 | POST | `/api/notes` | 创建笔记 |
| 笔记 | PUT | `/api/notes/{id}` | 更新笔记 |
| 笔记 | DELETE | `/api/notes/{id}` | 删除笔记 |
| 笔记 | GET | `/api/notes/shared` | 获取已分享笔记（旅游建议） |
| 行程 | GET | `/api/trips` | 获取行程列表 |
| 行程 | GET | `/api/trips/{id}` | 获取行程详情（含景点） |
| 行程 | POST | `/api/trips` | 创建行程 |
| 行程 | PUT | `/api/trips/{id}` | 更新行程 |
| 行程 | DELETE | `/api/trips/{id}` | 删除行程 |
| 行程景点 | POST | `/api/trips/{id}/places` | 添加景点 |
| 行程景点 | DELETE | `/api/trips/{id}/places/{placeId}` | 删除景点 |
| 地点 | GET | `/api/places` | 获取自定义地点 |
| 地点 | POST | `/api/places` | 添加地点 |
| 地点 | DELETE | `/api/places/{id}` | 删除地点 |
| AI | POST | `/api/ai/attraction` | 生成景点详情 |
| AI | POST | `/api/ai/route` | AI 路线规划 |
| 点赞 | POST | `/api/likes` | 点赞/取消点赞 |
| 点赞 | GET | `/api/likes` | 获取我的点赞 |
| 反馈 | POST | `/api/feedback` | 提交反馈 |

#### 14.4.3 接口示例

**创建笔记**

```
POST /api/notes
Content-Type: application/json
Authorization: Bearer <token>

Request:
{
  "title": "北京之旅",
  "content": "今天去了故宫...",
  "location": "北京",
  "category": "景点",
  "isShared": true
}

Response:
{
  "code": 200,
  "msg": "success",
  "data": {
    "id": 1,
    "title": "北京之旅",
    "createTime": "2026-03-30T10:00:00"
  }
}
```

---

### 14.5 地图 & AI 集成方案

#### 14.5.1 地图方案

**现状**：华为 MapKit 需要配置 `client_id`（ecoServiceId），只能在真机调试  
**开发期 Mock 方案**：

```ets
// MapService.ets
import { ConfigService } from './ConfigService';

export class MapService {
  // @deprecated: 地图需真机调试，开发期使用 Mock 数据
  async searchPlaces(query: string): Promise<PlaceResult[]> {
    if (ConfigService.getInstance().isMockEnabled('map')) {
      Logger.info('MapService', 'Using mock data for search');
      return this.getMockSearchResults(query);
    }
    // 真实调用 MapKit
    return this.realSearchPlaces(query);
  }

  // Mock 数据
  private getMockSearchResults(query: string): PlaceResult[] {
    return [
      { id: '1', name: `${query} - 故宫`, address: '北京市东城区', location: { latitude: 39.9, longitude: 116.4 }, type: 'sights' },
      { id: '2', name: `${query} - 天安门`, address: '北京市东城区', location: { latitude: 39.9, longitude: 116.4 }, type: 'sights' },
    ];
  }
}
```

**联调期**：真机 + 正确 client_id 配置

#### 14.5.2 AI 集成方案

后端 Spring Boot 调用 DeepSeek API：

```java
// AIService.java
@Service
public class AIService {

    @Value("${deepseek.api-key}")
    private String apiKey;

    @Value("${deepseek.api-url}")
    private String apiUrl;

    public AttractionDetailDTO generateAttractionDetail(String placeName) {
        // 调用 DeepSeek API
        // 无超时限制（后端处理）
        // 返回结构化 JSON
    }

    public List<String> optimizeRoute(List<String> places) {
        // AI 路线优化
    }
}
```

**优势**：后端调用 AI 无 30s 超时限制，可处理复杂生成请求

---

### 14.6 前端 Mock 切换说明

#### 14.6.1 切换机制

```ets
// ApiClient.ets - 统一 HTTP 客户端
export class ApiClient {
  private static instance: ApiClient;
  private baseUrl: string;
  private mockEnabled: boolean;

  static getInstance(): ApiClient {
    if (!ApiClient.instance) {
      const config = ConfigService.getInstance().getApiConfig();
      this.instance = new ApiClient();
      this.instance.baseUrl = config.baseUrl;
      this.instance.mockEnabled = config.mockEnabled;
    }
    return this.instance;
  }

  async get<T>(path: string): Promise<T> {
    if (this.mockEnabled) {
      return MockService.get<T>(path);
    }
    return httpRequest<T>(this.baseUrl + path);
  }

  async post<T>(path: string, data: object): Promise<T> {
    if (this.mockEnabled) {
      return MockService.post<T>(path, data);
    }
    return httpRequest<T>(this.baseUrl + path, 'POST', data);
  }
}
```

#### 14.6.2 Mock 数据目录

```
entry/src/main/resources/rawfile/
├── mock-config.json        # Mock 开关配置
├── MockService.ets         # Mock 服务入口
├── MockNotes.ets           # 笔记 Mock 数据
├── MockTrips.ets           # 行程 Mock 数据
├── MockPlaces.ets          # 地点 Mock 数据
└── MockUsers.ets           # 用户 Mock 数据
```

---

### 14.7 环境配置清单

#### 14.7.1 你需要手动配置的内容

| 序号 | 配置项 | 位置 | 说明 | 你的操作 |
|------|--------|------|------|---------|
| 1 | client_id | `entry/src/main/module.json5` | 华为地图 SDK | 在 AGC 创建应用后获取 |
| 2 | client_id | `entry/src/main/module.json5` | 华为 Push SDK | 在 AGC 创建应用后获取 |
| 3 | API Key | `backend/src/main/resources/application.yml` | DeepSeek API Key | 在 DeepSeek 平台申请 |
| 4 | 数据库 | `backend/src/main/resources/application.yml` | MySQL 连接信息 | 华为云 RDS 或本地 MySQL |
| 5 | JWT Secret | `backend/src/main/resources/application.yml` | JWT 签名密钥 | 自定义随机字符串 |

#### 14.7.2 华为云必需配置（手动）

```
AGC (AppGallery Connect) 控制台：
├── 我的应用
│   ├── 添加应用 (HarmonyOS)
│   ├── 开通 Map Kit (地图服务)
│   ├── 开通 Push Kit (推送服务)
│   ├── 开通 Cloud DB (可选，云数据库)
│   └── 获取 Client ID
│
华为云 RDS：
├── 创建 MySQL 实例
├── 创建数据库 anote
├── 创建用户 anote_user
└── 获取连接信息 (host, port, user, password)

DeepSeek 平台：
└── 申请 API Key (https://platform.deepseek.com/)
```

#### 14.7.3 本地开发配置

后端 `application.yml`：

```yaml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:mysql://your-rds-host:3306/anote?useSSL=false&serverTimezone=Asia/Shanghai
    username: anote_user
    password: your-password
    driver-class-name: com.mysql.cj.jdbc.Driver

  jpa:
    hibernate:
      ddl-auto: update   # 开发期用 update，上线改为 validate
    show-sql: true

deepseek:
  api-key: your-deepseek-api-key
  api-url: https://api.deepseek.com/v1/chat/completions
  model: deepseek-chat

jwt:
  secret: your-random-secret-key-32chars
  expiration: 86400000  # 24小时
```

---

### 14.8 前后端联调流程

#### 14.8.1 联调步骤

```
Phase 5 完成后，前端进入联调阶段：

Step 1: 后端部署
├── 后端项目部署到服务器（或本地 Ngrok 穿透）
└── 验证: GET http://localhost:8080/api/health → {"status": "ok"}

Step 2: 前端配置
├── 修改 entry/resources/rawfile/mock-config.json
│   └── enabled: true
│   └── baseUrl: 'http://your-server:8080/api'
└── 修改 entry/src/main/module.json5
    └── 添加 client_id (华为地图)

Step 3: 真机测试
├── 使用华为真机 (模拟器不支持 MapKit)
├── 安装签名后的 HAP
└── 测试完整功能链路

Step 4: 分模块切换
├── 先开笔记模块 (notes: true)
├── 再开行程模块 (trip: true)
└── 最后开用户模块 (user: true)
```

#### 14.8.2 地图调试特殊说明

**问题**：`ecoServiceId` / `client_id` 需要在 AGC 配置，虚拟设备无法加载真实地图  
**解决方案**：

| 阶段 | 方案 |
|------|------|
| 开发期 | Mock 数据 + 假坐标（固定显示北京区域） |
| 联调期 | 真机 + 正确 client_id + 真实地图 |
| 生产期 | 保持 client_id 配置 |

**AGC 配置步骤**：

1. 登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/agconnect.html)
2. 创建应用（选择 HarmonyOS）
3. 在「用户访问」中开通 Map Kit、Push Kit
4. 获取 Client ID
5. 在 DevEco Studio 中配置签名（必须使用华为开发者账号）
6. 安装到真机测试

---

### 14.9 后端开发计划（与前端并行）

| 时间 | 任务 | 交付物 |
|------|------|--------|
| Day 1-2 | 项目初始化 + 数据库设计 | Spring Boot 项目 + SQL 脚本 |
| Day 3-4 | 认证 + 笔记 CRUD | AuthController + NoteController |
| Day 5-6 | 行程 CRUD + AI 接口 | TripController + AIService |
| Day 7-8 | 点赞 + 反馈 + 统一响应 | LikeController + FeedbackController |
| Day 9-10 | 本地测试 + API 文档 | Swagger 文档 + 单元测试 |
| Day 11+ | 部署 + 前后端联调 | 线上可用版本 |

---

### 14.10 关键风险与预案

| 风险 | 概率 | 影响 | 预案 |
|------|------|------|------|
| 华为云函数调试复杂 | 中 | 放弃云函数，改用 Spring Boot | 已决策用 Spring Boot |
| 地图真机调试不便 | 高 | 开发期无法验证地图 | Mock 数据方案已规划 |
| AI 接口超时 | 中 | DeepSeek API 不稳定 | 后端做重试 + 降级 Mock |
| 华为云 RDS 配置复杂 | 低 | 网络访问受限 | 可先用本地 MySQL 开发 |
| 1 周时间不足 | 中 | 延期交付 | 优先级排序：认证 > 笔记 > 行程 > AI |

---

## 十五、HarmonyOS ArkTS 特殊注意事项

> 本节记录在 HarmonyOS 项目中容易出错的地方，基于实际构建经验总结。

### 15.1 源码目录结构

**⚠️ 禁止将配置文件放在 `src/` 下的自定义目录**

- `src/mock/`、`src/config/` 等自定义目录会被 hvigor 视为源码目录并尝试编译
- 如果里面包含 `.json5`、`.json` 等文件，会报 `E00303096 Configuration Error` 错误
- **正确做法**：配置文件放在 `resources/rawfile/` 目录下

```
✅ 正确: resources/rawfile/mock-config.json
❌ 错误: src/mock/mock-config.json5  (会触发 BUILD FAILED)
```

### 15.2 文件扩展名

**⚠️ 所有 ArkTS 代码必须使用 `.ets` 扩展名**

- `.ts` 文件不会被 hvigor 识别为 ArkTS 源码
- 如果 `src/` 下有遗留的 `.ts` 文件，需要改名为 `.ets`
- 导入路径不带扩展名（如 `from '../utils/Logger'`），HarmonyOS 模块解析会自动找到对应的 `.ets` 文件

### 15.3 ArkTS 严格类型检查

**⚠️ ArkTS 是 TypeScript 的超集，有更严格的限制**

| 问题 | 错误示例 | 正确写法 |
|------|---------|---------|
| 类型不匹配 | `private count: number = '1'` | `private count: number = 1` |
| null 安全 | `let x = obj.field` 可能为 null | 使用 `obj?.field` 或显式类型 |
| 装饰器 | `@State`、`@Link` 等必须精确导入 | `import { State } from '@kit.ArkUI'` |
| @Builder 参数 | Builder 内无法访问外部 this | 使用 `this.keyword` 或箭头函数 |

### 15.4 日志输出

**⚠️ 使用 `@ohos.hilog` 而不是 `console.*`**

```ets
// ❌ 错误 - console.* 在生产构建中可能不输出
console.info('debug message');

// ✅ 正确 - 使用 hilog
import hilog from '@ohos.hilog';
hilog.info(0x0000, 'Tag', 'message');
```

### 15.5 HarmonyOS SDK 模块导入

**⚠️ 正确导入华为 HMS Kit 模块**

```ets
// ✅ 正确导入方式
import { site, mapCommon } from '@kit.MapKit';
import { AccountAuthRequest, AuthAccount } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import abilityAccessCtrl from '@kit.AbilityKit';

// ❌ 错误 - 混用导入来源
import router from '@kit.RouterKit';  // router 实际来自 @kit.ArkUI
```

### 15.6 Map Kit 调试限制

- Map Kit (`@kit.MapKit`) 需要正确的 `client_id`（在 `module.json5` 的 metadata 中配置）
- **虚拟设备不支持 Map Kit**，地图显示为空白
- 开发期使用 Mock 坐标数据，真机调试时再验证真实地图

### 15.7 构建验证

每次修改后都需要在 DevEco Studio 中执行 **Build > Rebuild Project** 验证是否报错，而不仅仅依赖语法检查。

---

## 变更记录

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-03-30 | v1.0 | 初稿创建 | Claude |
| 2026-03-30 | v1.1 | Phase 0 完成；新增 HarmonyOS 特殊注意事项 | Claude |

