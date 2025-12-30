//  ParkingAppApp.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI
import CoreData   // ← 必须导入，才能访问 NSPersistentContainer 和 viewContext

@main
struct ParkingAppApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    let persistenceController = PersistenceController.shared
    
    init() {
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
