# 任务清单

## 项目信息
- 分支：feature/location-parkinglots-i18n
- iOS 最低版本：17.0
- 目标：实现定位、停车场数据、多语言支持

## 构建问题修复记录

### Info.plist 重复处理问题
**问题**：Multiple commands produce ... ParkingApp.app/Info.plist
**原因**：项目同时启用了 `GENERATE_INFOPLIST_FILE = YES` 和存在手动 Info.plist 文件，且通过 PBXFileSystemSynchronizedRootGroup 自动同步到资源阶段，导致同一个文件被处理两次。
**处理**：
- 将 `GENERATE_INFOPLIST_FILE` 设置为 `NO`
- 添加 `INFOPLIST_FILE = ParkingApp/Info.plist` 明确指定使用手动的 Info.plist
- 确保 Xcode 只通过 "Process Info.plist Files" 阶段处理，不会在 "Copy Bundle Resources" 阶段重复处理

### ObservableObject 协议问题
**问题**：Type 'AuthenticationViewModel' does not conform to protocol 'ObservableObject'
**原因**：缺少 Combine 框架导入，@Published 需要 Combine 框架支持
**处理**：在所有 ViewModel 文件中添加 `import Combine`

### iOS 部署目标
**问题**：IPHONEOS_DEPLOYMENT_TARGET 设置为 26.0（不正确）
**处理**：修改为 17.0 以符合要求

---

## 任务进度

### ✅ 任务 0：项目初始化与构建修复
- [x] 创建分支 feature/location-parkinglots-i18n
- [x] 修复 Info.plist 重复处理问题
- [x] 修复 ObservableObject 协议问题
- [x] 修复 iOS 部署目标为 17.0
- [x] 确认项目可编译运行

### ✅ 任务 1：启用定位与当前位置显示
- [x] 在 Info.plist 添加 NSLocationWhenInUseUsageDescription（中文）
- [x] 新建 LocationManager.swift
- [x] 在 ParkingMapView 中集成定位功能
- [x] 实现授权被拒绝时的提示与设置按钮

### ✅ 任务 2：新增"停车场"模型与服务骨架
- [x] 新建 ParkingLot.swift 模型
- [x] 新建 ParkingLotProviding 协议
- [x] 新建 ParkingLotService 实现
- [x] 新建 ParkingLotViewModel

### ✅ 任务 3：从真实数据源抓取香港停车场信息
- [x] 实现从 data.gov.hk 抓取数据（框架已搭建，待接入真实 API）
- [x] 实现字段映射到 ParkingLot
- [x] 实现本地缓存（24小时过期）
- [x] 在 ViewModel 中集成数据源

### ✅ 任务 4：列表/地图双视图对接"停车场"数据
- [x] 新建 ParkingLotsMapView
- [x] 新建 ParkingLotsListView
- [x] 在 MainTabView 中替换为新的停车场版本
- [x] 实现搜索功能

### ✅ 任务 5：筛选与排序
- [x] 实现筛选 UI（空位、EV、有盖、CCTV）
- [x] 实现排序 UI（距离、空位、价格）
- [x] 实现 applyFiltersAndSort 逻辑

### ✅ 任务 6：停车场详情页
- [x] 新建 ParkingLotDetailView
- [x] 实现详情页 UI
- [x] 实现拨打电话功能
- [x] 实现打开 Apple 地图导航

### ✅ 任务 7：一键导航
- [x] 实现外部导航（Apple 地图）
- [x] 实现内置导航（MKDirections 计算路线）

### ✅ 任务 8：多语言（i18n）
- [x] 启用本地化（中英双语）
- [x] 创建 Localizable.strings
- [x] 抽取所有硬编码文案
- [x] 配置 InfoPlist.strings

### 📋 任务 9（可选）：数据更新与稳定性
- [ ] 实现手动刷新功能
- [ ] 实现错误提示与重试
- [ ] 添加单元测试

---

## 备注
- 数据集来源：待确定 data.gov.hk 的具体数据集链接
- 代码风格：新增文件需添加文档注释与 TODO 标记
- 与现有 Reservation 流程的衔接：暂时保留现有 mock 车位预定功能

