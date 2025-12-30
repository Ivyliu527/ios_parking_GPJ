# API 配置说明

## 问题

如果遇到"未能找到使用指定主机名的服务器"错误，说明 API 服务器地址未正确配置。

## 解决方案

### 方案 1：配置实际的 API 服务器地址（推荐）

#### 方式 A：直接在代码中修改

1. 打开 `ParkingApp/Services/NetworkService.swift`
2. 找到第 25 行左右的 `baseURL` 配置
3. 将 `"https://your-api-server.com/api"` 替换为您的实际 API 地址

例如：
```swift
return "https://api.yourdomain.com/api"  // 替换为您的 API 地址
```

或者本地开发：
```swift
return "http://localhost:3000/api"  // 本地开发服务器
```

#### 方式 B：通过 Info.plist 配置（推荐用于生产环境）

1. 打开 `ParkingApp/Info.plist`
2. 找到注释部分（约第 55-59 行）
3. 取消注释并修改：
```xml
<key>APIBaseURL</key>
<string>https://your-api-server.com/api</string>
```

### 方案 2：使用 Firebase Authentication（如果使用 Firebase）

如果您想使用 Firebase Authentication 而不是自定义 API，需要：

1. 确保已添加 Firebase Authentication SDK 到项目
2. 修改 `AuthenticationViewModel.swift` 使用 Firebase Auth
3. 参考 Firebase 官方文档：https://firebase.google.com/docs/auth/ios/start

### 方案 3：临时禁用网络请求（仅用于测试 UI）

如果暂时没有服务器，可以修改 `NetworkService.swift` 让注册/登录功能暂时返回模拟数据（仅用于测试 UI，不推荐用于生产）。

---

## 当前配置状态

当前 `baseURL` 配置位置：`ParkingApp/Services/NetworkService.swift` 第 18-26 行

默认值：`"https://your-api-server.com/api"`（占位符，需要替换）

---

## 验证配置

配置完成后，运行应用并尝试注册/登录。如果配置正确，应该能够连接到服务器。

如果仍然遇到错误，请检查：
1. API 服务器是否正在运行
2. URL 是否正确（包含协议 http:// 或 https://）
3. 网络连接是否正常
4. 服务器是否允许来自该应用的请求（CORS/防火墙设置）

