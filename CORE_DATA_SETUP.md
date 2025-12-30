# Core Data 模型配置指南

## ⚠️ 重要：解决 FavoriteEntity 崩溃问题

### 问题描述
应用启动时崩溃：`NSFetchRequest could not locate an NSEntityDescription for entity name 'FavoriteEntity'`

### 原因
Core Data 模型文件（.xcdatamodeld）不存在或未正确配置。

---

## 解决步骤

### 步骤 1：创建 Core Data 模型文件

1. **在 Xcode 中创建模型文件**
   - 右键点击 `ParkingApp` 文件夹
   - 选择 "New File..."
   - 选择 "Data Model"
   - 命名为 `ParkingDataModel`（必须与 `PersistenceController.swift` 中的名称一致）

2. **确保文件位置正确**
   - 文件应位于：`ParkingApp/ParkingDataModel.xcdatamodeld`
   - 确保文件已添加到 Target Membership（在 File Inspector 中勾选你的 App Target）

### 步骤 2：创建实体

在 `ParkingDataModel.xcdatamodeld` 文件中创建以下三个实体：

#### 1. FavoriteEntity
- **实体名称**：`FavoriteEntity`（区分大小写，必须完全一致）
- **属性**：
  - `userId`: String（非可选）
  - `parkingLotId`: String（非可选）
  - `createdAt`: Date（可选）

#### 2. ParkingLotEntity
- **实体名称**：`ParkingLotEntity`
- **属性**：
  - `id`: String（非可选）
  - `name`: String（可选）
  - `address`: String（可选）
  - `latitude`: Double
  - `longitude`: Double
  - `totalSpaces`: Integer 32（可选，默认 0）
  - `availableSpaces`: Integer 32（可选，默认 0）
  - `openingHours`: String（可选）
  - `priceRules`: String（可选）
  - `contactPhone`: String（可选）
  - `covered`: Boolean（默认 false）
  - `cctv`: Boolean（默认 false）
  - `evChargerCount`: Integer 32（默认 0）
  - `evChargerTypes`: Transformable（可选，类型设为 [String]）
  - `lastUpdated`: Date（可选）
  - `cachedAt`: Date（可选）

#### 3. ReservationEntity
- **实体名称**：`ReservationEntity`
- **属性**：
  - `id`: String（非可选）
  - `userId`: String（非可选）
  - `parkingSpotId`: String（非可选）
  - `startTime`: Date（非可选）
  - `endTime`: Date（可选）
  - `status`: String（非可选）
  - `totalCost`: Double（默认 0.0）
  - `paymentStatus`: String（非可选）
  - `syncedAt`: Date（可选）

### 步骤 3：配置 Codegen

对于每个实体：

1. 选中实体
2. 在 **Data Model Inspector** 中：
   - **Codegen**: 选择 `Class Definition`（推荐）或 `Category/Extension`
   - **Module**: 选择 `Current Product Module`
   - **Class**: 留空（使用默认名称）

### 步骤 4：验证配置

1. **检查模型文件名**
   - 文件必须命名为 `ParkingDataModel.xcdatamodeld`
   - 与 `PersistenceController.swift` 中的 `NSPersistentContainer(name: "ParkingDataModel")` 一致

2. **检查 Target Membership**
   - 在 File Inspector 中确保 `ParkingDataModel.xcdatamodeld` 已勾选你的 App Target

3. **检查实体名称**
   - `FavoriteEntity`（不是 `Favorite` 或 `favoriteEntity`）
   - `ParkingLotEntity`
   - `ReservationEntity`

---

## 已添加的保护措施

为了避免崩溃，代码中已添加以下保护：

### 1. CoreDataService 保护
- `isCoreDataReady()` 方法检查模型是否已加载
- 所有收藏相关方法在调用前都会检查 Core Data 是否就绪

### 2. AuthenticationViewModel 保护
- 所有收藏方法都检查 `isAuthenticated` 和 `currentUser`
- 只有在用户已登录时才访问 Core Data

### 3. 错误处理
- 所有 Core Data 操作都包含 try-catch
- 错误时返回安全默认值，不会崩溃

---

## 测试

配置完成后：

1. **清理构建**
   - Product → Clean Build Folder (Shift+Cmd+K)

2. **重新构建**
   - Product → Build (Cmd+B)

3. **运行应用**
   - 应用应该可以正常启动，不再崩溃
   - 登录后可以正常使用收藏功能

---

## 如果仍然崩溃

1. **检查控制台输出**
   - 查看是否有 "⚠️ Core Data 模型中未找到 FavoriteEntity 实体" 的警告
   - 查看具体的错误信息

2. **验证模型文件**
   - 在 Xcode 中打开 `ParkingDataModel.xcdatamodeld`
   - 确认三个实体都存在
   - 确认实体名称完全一致（区分大小写）

3. **检查文件路径**
   - 确保模型文件在正确的位置
   - 确保文件已添加到项目

4. **重新创建模型文件**
   - 如果问题持续，可以删除现有模型文件
   - 按照步骤 1-3 重新创建

---

## 注意事项

- ⚠️ 实体名称必须与代码中完全一致（区分大小写）
- ⚠️ 模型文件名必须与 `PersistenceController` 中的名称一致
- ⚠️ 确保文件已添加到 Target Membership
- ⚠️ 如果使用 Codegen，确保设置为 `Class Definition` 或 `Category/Extension`

---

*最后更新: 2025年*

