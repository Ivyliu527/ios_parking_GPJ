# Core Data 模型说明

## 需要创建的 Core Data 模型文件

在 Xcode 中需要创建 `ParkingDataModel.xcdatamodeld` 文件，包含以下实体：

### 1. ParkingLotEntity
- **id**: String (必需)
- **name**: String (必需)
- **address**: String (必需)
- **latitude**: Double (必需)
- **longitude**: Double (必需)
- **totalSpaces**: Int32 (可选)
- **availableSpaces**: Int32 (可选)
- **openingHours**: String? (可选)
- **priceRules**: String? (可选)
- **contactPhone**: String? (可选)
- **covered**: Bool (默认 false)
- **cctv**: Bool (默认 false)
- **evChargerCount**: Int32 (默认 0)
- **evChargerTypes**: [String]? (可选，使用 Transformable)
- **lastUpdated**: Date? (可选)
- **cachedAt**: Date (必需，用于缓存时间戳)

### 2. ReservationEntity
- **id**: String (必需)
- **userId**: String (必需)
- **parkingSpotId**: String (必需)
- **startTime**: Date (必需)
- **endTime**: Date? (可选)
- **status**: String (必需，枚举值: "active", "completed", "cancelled")
- **totalCost**: Double (必需)
- **paymentStatus**: String (必需，枚举值: "pending", "paid", "refunded")
- **syncedAt**: Date (可选，用于同步时间戳)

### 3. FavoriteEntity
- **userId**: String (必需)
- **parkingLotId**: String (必需)
- **createdAt**: Date (必需)

## 创建步骤

1. 在 Xcode 中，右键点击 `ParkingApp` 文件夹
2. 选择 "New File..."
3. 选择 "Data Model"
4. 命名为 `ParkingDataModel`
5. 添加上述三个实体及其属性
6. 确保所有实体都继承自 `NSManagedObject`

## 注意事项

- `evChargerTypes` 使用 Transformable 类型存储数组
- 所有 Date 类型使用 Date 类型
- 所有 String 类型使用 String 类型
- 所有 Int 类型使用 Int32 类型
- 所有 Bool 类型使用 Bool 类型

