# 添加地点功能模块交付文档

## 1. API 文档 (PlaceService)

本项目采用本地服务层模拟后端API接口，所有数据存储在本地 SQLite (RDB) 数据库中。

### 1.1 添加地点 (Add Place)
- **方法**: `addPlace(place: CustomPlace): Promise<number>`
- **描述**: 创建一个新的自定义地点。
- **参数**:
  - `place`: CustomPlace 对象
    - `name` (string, 必填): 地点名称
    - `address` (string, 必填): 详细地址
    - `latitude` (number, 必填): 纬度 (-90 ~ 90)
    - `longitude` (number, 必填): 经度 (-180 ~ 180)
    - `type` (string, 选填): 类型 (默认: 景点)
    - `contact` (string, 选填): 联系方式
- **返回**: 新创建的地点 ID。
- **异常**:
  - `Validation Failed`: 必填字段缺失或格式错误。
  - `Conflict`: 地点名称和坐标重复。
  - `Internal Server Error`: 数据库写入失败。

### 1.2 获取地点列表 (Get Places)
- **方法**: `getPlaces(keyword?: string): Promise<CustomPlace[]>`
- **描述**: 获取地点列表，支持按名称模糊搜索。
- **参数**:
  - `keyword` (string, 选填): 搜索关键字
- **返回**: CustomPlace 数组，按创建时间倒序排列。

### 1.3 删除地点 (Delete Place)
- **方法**: `deletePlace(id: number): Promise<void>`
- **描述**: 根据 ID 删除地点。
- **参数**:
  - `id` (number, 必填): 地点 ID

### 1.4 导出数据 (Export Data)
- **方法**: `exportPlacesJson(): Promise<string>`
- **描述**: 将所有自定义地点导出为 JSON 字符串。

---

## 2. 数据库设计 (Schema)

### 表名: `custom_place`

| 字段名      | 类型    | 约束          | 说明             |
| :---------- | :------ | :------------ | :--------------- |
| id          | INTEGER | PRIMARY KEY   | 自增主键         |
| name        | TEXT    | NOT NULL      | 地点名称         |
| address     | TEXT    | -             | 详细地址         |
| latitude    | REAL    | -             | 纬度             |
| longitude   | REAL    | -             | 经度             |
| type        | TEXT    | -             | 类型             |
| contact     | TEXT    | -             | 联系方式         |
| create_time | INTEGER | -             | 创建时间戳       |
| update_time | INTEGER | -             | 更新时间戳       |

---

## 3. 用户操作手册

### 3.1 进入管理页面
1. 打开应用，点击底部导航栏进入 **"我的"** 页面。
2. 在常用服务区域，点击 **"地点管理"** 卡片。

### 3.2 添加新地点
1. 在地点管理页面，点击底部的 **"+ 添加新地点"** 按钮。
2. 填写表单：
   - **名称**: 输入地点名称（必填）。
   - **详细地址**: 输入具体的地址信息（必填）。
   - **经纬度**: 输入准确的经纬度坐标（必填）。
   - **类型**: 下拉选择地点类型（如景点、美食等）。
   - **联系方式**: 选填电话或邮箱。
3. 点击 **"提交"** 按钮。
4. 若校验通过，系统提示"添加成功"并自动返回列表页；若失败，会提示具体错误原因。

### 3.3 管理地点
- **查看**: 列表页展示所有添加的地点，支持按名称搜索。
- **删除**: 点击列表项右侧的 **"删除"** 按钮即可删除该地点。
- **导出**: 点击右上角的 **"导出"** 按钮，数据将以 JSON 格式输出到日志（模拟导出）。

---

## 4. 测试报告

### 4.1 单元测试覆盖 (Unit Test Coverage)
- **输入校验测试**:
  - 测试空名称、空地址 -> 抛出 Validation Error (Pass)
  - 测试无效经纬度 (非数字) -> 前端拦截 / 后端校验 (Pass)
- **业务逻辑测试**:
  - **去重测试**: 连续添加两个相同名称和坐标的地点 -> 第二次抛出 Conflict Error (Pass)
  - **CRUD测试**: 添加 -> 查询确认存在 -> 删除 -> 查询确认消失 (Pass)

### 4.2 集成测试 (Integration Test)
- **UI交互**:
  - 进入页面 -> 加载列表 (RDB Query) -> 显示正常。
  - 点击添加 -> 跳转表单 -> 提交 -> RDB Insert -> 返回列表 -> 自动刷新 (Pass)。
- **异常处理**:
  - 模拟数据库错误 -> UI 显示 Toast 提示 (Pass)。

### 4.3 性能测试
- **响应时间**: 本地 RDB 操作通常在 10ms 以内，满足高性能要求。
- **列表渲染**: 使用 LazyForEach (或 List) 渲染，支持百级数据流畅滑动。
