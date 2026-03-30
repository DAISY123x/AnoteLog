# 鸿蒙高级认证考试通关秘籍：理论与编程核心考点清单

> **目标**：快速掌握鸿蒙高级认证（HarmonyOS Advanced Certification）所需的理论体系与编程核心，助你一次通过！
> **适用人群**：鸿蒙初学者、备考开发者

---

## 📚 第一部分：鸿蒙系统架构与核心概念 (The Big Picture)

### 1.1 系统架构 (四层楼)
想象鸿蒙系统是一栋四层大楼，从下到上分别是：
*   **内核层 (Kernel Layer)**: 地基。Linux内核/LiteOS，负责硬件调度。
    *   *考点*: 知道它是多内核设计 (Multi-kernel)。
*   **系统服务层 (System Service Layer)**: 物业管理。提供分布式任务调度、公共通信、多媒体能力。
*   **框架层 (Framework Layer)**: 装修队工具箱。ArkUI、ArkTS运行时、各种Kit（Map Kit, Location Kit等）。
*   **应用层 (Application Layer)**: 也就是你写的App。

### 1.2 核心技术特性
*   **一次开发，多端部署**: 一套代码跑在手机、平板、手表上。
*   **可分可合**: 比如原子化服务 (Atomic Service)，免安装。
*   **统一OS，弹性部署**: 大到车机，小到手环，用同一个OS。

---

## 🛠️ 第二部分：ArkTS 语言基础 (The Tool)

ArkTS 是鸿蒙的主力开发语言，它是 TypeScript 的**超集**。

### 2.1 基础语法
*   **静态类型**: 变量必须声明类型 (`let name: string = "Harmony"`).
*   **装饰器 (Decorators)**: ArkTS的灵魂。
    *   `@Entry`: 标记这是个**页面**入口，像大门。
    *   `@Component`: 标记这是个**自定义组件**，像积木块。
    *   `@Builder`: 轻量级UI复用函数，像一个盖章工具，哪里需要盖哪里。
    *   `@Styles` / `@Extend`: 用于复用样式。

---

## 🎨 第三部分：ArkUI 声明式开发 (The Face)

### 3.1 布局容器 (Layouts) - 排兵布阵
*   **Row / Column**: 线性布局。最常用！
    *   `justifyContent` (主轴对齐): 比如 Row 的水平方向。
    *   `alignItems` (交叉轴对齐): 比如 Row 的垂直方向。
*   **Stack**: 层叠布局。像叠盘子，后写的盖在上面。
*   **Flex**: 弹性布局。处理换行 (`wrap`) 很好用。
*   **RelativeContainer**: 相对布局。通过锚点 (`alignRules`) 定位，性能更好，适合复杂界面。
*   **Grid / GridItem**: 网格布局。相册、九宫格。
*   **List / ListItem**: 列表布局。朋友圈、新闻列表。

### 3.2 渲染控制 (Rendering Control)
*   **if/else**: 条件渲染。控制组件生或死（从DOM树移除）。
*   **ForEach**: 循环渲染。适合数据量不大的列表。
    *   *考点*: 第三个参数 `keyGenerator` 很重要，决定复用效率。
*   **LazyForEach**: 懒加载。**必考！** 配合 `IDataSource` 使用，只渲染屏幕看得到的数据，处理成千上万条数据必备。

---

## 🧠 第四部分：状态管理 (The Brain) - 重中之重

这是考试最难也最重要的部分。把组件想象成家庭成员，状态就是他们手里的钱或信息。

### 4.1 V1 状态管理 (常用)
| 装饰器 | 作用 | 比喻 | 初始化 | 传递方向 |
| :--- | :--- | :--- | :--- | :--- |
| **@State** | 组件内部状态 | **私房钱**。只有自己能用，变了自己刷新。 | 必须 | - |
| **@Prop** | 父子单向同步 | **复印件**。爸爸给儿子的文件，儿子涂改不影响爸爸的原件。 | 允许不初始化 | 父 -> 子 |
| **@Link** | 父子双向同步 | **共享文档**。爸爸和儿子共用一份，谁改了对方都看得到。 | 禁止 | 父 <-> 子 |
| **@Provide / @Consume** | 跨代组件通信 | **村里的大喇叭**。爷爷喊一声，孙子、重孙子都能听到。无需层层传递。 | Provide必须 | 祖先 <-> 后代 |
| **@ObjectLink / @Observed** | 嵌套对象数组 | **显微镜**。`@State` 只能监听到第一层变化，如果是数组里的对象属性变了，需要用这个组合。 | - | - |
| **@Watch** | 状态监听 | **看门狗**。当状态改变时，自动触发一个回调函数。 | - | - |

### 4.2 AppStorage / LocalStorage
*   **AppStorage**: 全局单例。整个App都能访问的全局变量。
*   **LocalStorage**: 页面级或Ability级的存储。

---

## 🏗️ 第五部分：Stage 模型 (The Skeleton)

### 5.1 基本概念
*   **UIAbility**: 包含UI界面的应用组件。一个App可以有多个UIAbility。
*   **ExtensionAbility**: 没有界面的服务，比如后台卡片、输入法。

### 5.2 UIAbility 生命周期 (Lifecycle) - 必考
想象你在演话剧：
1.  **Create (创建)**: 演员化妆，准备道具。初始化数据。
2.  **Foreground (前台)**: 幕布拉开，灯光打亮。用户看得到你了，可以交互。
3.  **Background (后台)**: 幕布合上，但还没退场。用户按了Home键，App还在运行但不可见。
4.  **Destroy (销毁)**: 演出结束，卸妆回家。释放资源。

### 5.3 Want
*   **Want**: 这是一个**信使**。用于在 Ability 之间传递信息（比如启动另一个App，或者告诉下一个页面带什么参数）。

---

## 🛣️ 第六部分：路由与导航 (Navigation)

### 6.1 Router (老版本，但仍常用)
*   `router.pushUrl()`: 跳转新页面，压入栈。
*   `router.replaceUrl()`: 替换当前页面，不保留历史。
*   `router.back()`: 返回。

### 6.2 Navigation (新版本，官方推荐)
*   组件级路由，支持分栏显示，更适合折叠屏和平板。
*   使用 `NavPathStack` 来控制页面跳转。

---

## 💾 第七部分：数据与网络 (Data & Net)

### 7.1 数据持久化
*   **用户首选项 (Preferences)**: 存简单的 Key-Value，比如“是否夜间模式”、“字体大小”。**轻量级**。
*   **关系型数据库 (RelationalStore)**: 也就是 SQLite。存复杂的结构化数据，比如聊天记录、文章列表。

### 7.2 网络请求 (HTTP)
*   使用 `http.createHttp()` 发起请求。
*   **权限**: 必须在 `module.json5` 里申请 `ohos.permission.INTERNET`。

---

## 🚀 第八部分：高级特性与性能优化

### 8.1 多线程 (TaskPool / Worker)
*   ArkTS 主线程不能阻塞（否则界面卡死）。
*   耗时操作（如解压文件、复杂计算）必须放到子线程。
*   **TaskPool**: 推荐。系统自动管理线程生命周期，用完即走。
*   **Worker**: 常驻线程，适合长时间运行的后台任务，需手动管理。

### 8.2 性能优化口诀
1.  **少用 `forEach`，多用 `LazyForEach`**。
2.  **图片要压缩，不要渲染超大图**。
3.  **状态管理要精准**，不要把整个大对象都 `@State`，只更新需要更新的属性。

### 8.3 HSP / HAR / HAP
*   **HAP (Harmony Ability Package)**: 应用安装的基本单位。
*   **HAR (Harmony Archive)**: 静态共享包。代码编译后打进去，每个引用它的模块都有一份拷贝（体积大，但独立）。
*   **HSP (Harmony Shared Package)**: 动态共享包。代码只存一份，多个模块共享（体积小，适合主包和分包共用代码）。

---

## 📝 编程题实战技巧 (Cheat Sheet)

1.  **构建界面**: 看到图，先拆解。上下结构用 `Column`，左右结构用 `Row`。
2.  **实现列表**: 看到列表，马上写 `List` + `ListItem`。
3.  **点击事件**: `.onClick(() => { ... })` 是最常用的交互。
4.  **页面跳转**: 记住 `router.pushUrl({ url: '...' })`。
5.  **异步处理**: 遇到网络请求或数据库，记得用 `async/await` 或 `Promise`，否则拿不到数据。

---

> **祝你考试顺利！逢考必过！** 💯
