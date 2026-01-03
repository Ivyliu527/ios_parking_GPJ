//
//  PersistenceController.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreData

// MARK: - Core Data 持久化控制器

/// Core Data 持久化控制器
/// 管理 Core Data 堆栈的初始化和上下文管理
class PersistenceController {
    static let shared = PersistenceController()
    
    // MARK: - 属性
    
    /// Core Data 容器
    let container: NSPersistentContainer
    
    // MARK: - 初始化方法
    
    /// 初始化方法
    /// - Parameter inMemory: 是否使用内存存储（用于测试）
    init(inMemory: Bool = false) {
        // ⚠️ 重要：确保模型文件名与这里一致
        // 如果模型文件是 ParkingDataModel.xcdatamodeld，则使用 "ParkingDataModel"
        container = NSPersistentContainer(name: "ParkingDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                // 改为非致命错误，避免应用崩溃
                print("⚠️ Core Data 加载失败: \(error.localizedDescription)")
                print("⚠️ 请检查：")
                print("   1. ParkingDataModel.xcdatamodeld 文件是否存在")
                print("   2. 文件是否已添加到 Target Membership")
                print("   3. 模型文件中是否包含 FavoriteEntity, ParkingLotEntity")
                // 不 fatalError，允许应用继续运行（但收藏功能可能不可用）
                // fatalError("Core Data 加载失败: \(error.localizedDescription)")
            } else {
                print("✅ Core Data 加载成功")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - 数据保存
    
    /// 保存上下文
    /// 保存 Core Data 上下文中的所有更改
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("保存失败: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - 上下文管理
    
    /// 创建后台上下文
    /// 创建一个新的后台上下文，用于后台数据操作
    /// - Returns: 后台上下文实例
    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
}
