//
//  PersistenceController.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreData

/// Core Data 持久化控制器
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
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
                print("   3. 模型文件中是否包含 FavoriteEntity, ParkingLotEntity, ReservationEntity")
                // 不 fatalError，允许应用继续运行（但收藏功能可能不可用）
                // fatalError("Core Data 加载失败: \(error.localizedDescription)")
            } else {
                print("✅ Core Data 加载成功")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// 保存上下文
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
    
    /// 后台上下文
    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
}
