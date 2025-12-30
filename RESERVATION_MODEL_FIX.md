# Reservation 模型字段统一修复

## 问题

项目中存在 Reservation 模型字段不一致的问题。

## 实际的 Reservation 模型字段

根据 `ParkingApp/Models/Reservation.swift`，正确的字段是：

```swift
struct Reservation: Codable, Identifiable {
    let id: String
    let userId: String
    let parkingSpotId: String  // ✅ 正确的字段名
    var startTime: Date
    var endTime: Date?         // ✅ 可选
    var status: ReservationStatus
    var totalCost: Double      // ✅ 正确的字段名
    var paymentStatus: PaymentStatus
}
```

## 已修复的地方

### ✅ ReservationViewModel.swift
- 使用正确的字段：`parkingSpotId`, `status`, `totalCost`, `paymentStatus`
- 使用 `reservations` 顶级集合（不是子集合）
- 字段转换方法 `reservation(from:data:id:)` 和 `firestoreData(from:)` 正确

### ✅ NetworkService.swift (FirebaseService)
- 已修复 `syncReservations()` 方法，使用正确的字段
- 已修复 `fetchReservations()` 方法，使用正确的字段
- 注意：这个服务类目前未被使用（AuthenticationViewModel 和 ReservationViewModel 直接使用 Firebase）

## Firestore 数据结构（已统一）

### reservations 集合
```
reservations/{reservationId}
{
  "userId": String,
  "parkingSpotId": String,      // ✅ 使用 parkingSpotId（不是 lotId）
  "startTime": Timestamp,
  "endTime": Timestamp?,        // ✅ 可选
  "status": String,             // "active" | "completed" | "cancelled"
  "totalCost": Number,          // ✅ 使用 totalCost（不是 price）
  "paymentStatus": String       // "pending" | "paid" | "refunded"
}
```

## 注意事项

1. **集合路径统一**：使用 `reservations` 顶级集合，不是 `users/{userId}/reservations` 子集合
2. **字段名称**：必须使用 `parkingSpotId` 和 `totalCost`，不是 `lotId` 和 `price`
3. **可选字段**：`endTime` 是可选字段，需要正确处理 `nil` 情况
4. **枚举类型**：`status` 和 `paymentStatus` 需要正确序列化/反序列化为字符串

## 状态

✅ **所有 Reservation 模型使用已统一**
- ReservationViewModel 使用正确字段 ✅
- NetworkService.swift 已修复为使用正确字段 ✅
- Firestore 存储结构已统一 ✅

