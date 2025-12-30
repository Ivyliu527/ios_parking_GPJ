//  ParkingAppApp.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI
import CoreData   // ← 必须导入，才能访问 NSPersistentContainer 和 viewContext
import FirebaseCore

// MARK: - Firebase 模块导入
import FirebaseAuth         // Firebase Authentication - 用户登录注册
import FirebaseFirestore    // Cloud Firestore 数据库 - 存储用户数据和预定记录
// import FirebaseFirestoreSwift // Firestore 的 Codable 支持（可选）
// import FirebaseStorage      // Firebase Storage（文件存储，如需要存储图片等）

@main
struct ParkingAppApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    let persistenceController = PersistenceController.shared
    
    init() {
        // 初始化 Firebase（必须在其他初始化之前）
        // 在 AppDelegate.application(_:didFinishLaunching…) 或 SwiftUI @main App 的 init() 中调用
        FirebaseApp.configure()
        
        // 初始化 Core Data（确保容器加载）
        _ = PersistenceController.shared
        
        // 启动网络监控（离线模式依赖）
        _ = NetworkMonitor.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                // 注入 Core Data 上下文到环境
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
