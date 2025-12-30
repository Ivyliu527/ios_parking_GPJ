//
//  CoreDataService.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import CoreData

/// Core Data 数据服务
class CoreDataService {
    static let shared = CoreDataService()
    
    private let persistenceController = PersistenceController.shared
    
    private init() {}
    
    // MARK: - 停车场缓存
    
    /// 保存停车场列表到 Core Data
    func saveParkingLots(_ lots: [ParkingLot]) {
        let context = persistenceController.newBackgroundContext()
        context.perform {
            for lot in lots {
                _ = ParkingLotEntity.createOrUpdate(from: lot, in: context)
            }
            
            // 更新缓存时间戳
            self.updateCacheTimestamp(in: context)
            
            do {
                try context.save()
            } catch {
                print("保存停车场数据失败: \(error)")
            }
        }
    }
    
    /// 从 Core Data 加载停车场列表
    func loadParkingLots() -> [ParkingLot] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ParkingLotEntity> = ParkingLotEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            let entities = try context.fetch(request)
            return entities.map { $0.toParkingLot() }
        } catch {
            print("加载停车场数据失败: \(error)")
            return []
        }
    }
    
    /// 获取缓存时间戳
    func getCacheTimestamp() -> Date? {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ParkingLotEntity> = ParkingLotEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "cachedAt", ascending: false)]
        request.fetchLimit = 1
        
        do {
            if let entity = try context.fetch(request).first {
                return entity.cachedAt
            }
        } catch {
            print("获取缓存时间戳失败: \(error)")
        }
        return nil
    }
    
    private func updateCacheTimestamp(in context: NSManagedObjectContext) {
        // 更新所有实体的缓存时间
        let request: NSFetchRequest<ParkingLotEntity> = ParkingLotEntity.fetchRequest()
        if let entities = try? context.fetch(request) {
            for entity in entities {
                entity.cachedAt = Date()
            }
        }
    }
    
    // MARK: - 用户收藏
    
    /// 切换收藏状态
    func toggleFavorite(userId: String, parkingLotId: String) -> Bool {
        let context = persistenceController.container.viewContext
        let isFavorite = FavoriteEntity.toggleFavorite(userId: userId, parkingLotId: parkingLotId, in: context)
        
        do {
            try context.save()
        } catch {
            print("保存收藏状态失败: \(error)")
        }
        
        return isFavorite
    }
    
    /// 检查是否已收藏
    func isFavorite(userId: String, parkingLotId: String) -> Bool {
        let context = persistenceController.container.viewContext
        return FavoriteEntity.isFavorite(userId: userId, parkingLotId: parkingLotId, in: context)
    }
    
    /// 获取用户的所有收藏
    func getFavorites(userId: String) -> [String] {
        let context = persistenceController.container.viewContext
        return FavoriteEntity.getFavorites(userId: userId, in: context)
    }
    
    // MARK: - 预定记录
    
    /// 保存预定记录
    func saveReservation(_ reservation: Reservation) {
        let context = persistenceController.newBackgroundContext()
        context.perform {
            _ = ReservationEntity.createOrUpdate(from: reservation, in: context)
            
            do {
                try context.save()
            } catch {
                print("保存预定记录失败: \(error)")
            }
        }
    }
    
    /// 保存多个预定记录
    func saveReservations(_ reservations: [Reservation]) {
        let context = persistenceController.newBackgroundContext()
        context.perform {
            for reservation in reservations {
                _ = ReservationEntity.createOrUpdate(from: reservation, in: context)
            }
            
            do {
                try context.save()
            } catch {
                print("保存预定记录失败: \(error)")
            }
        }
    }
    
    /// 加载用户的预定记录
    func loadReservations(userId: String) -> [Reservation] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ReservationEntity> = ReservationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            return entities.map { $0.toReservation() }
        } catch {
            print("加载预定记录失败: \(error)")
            return []
        }
    }
    
    /// 删除预定记录
    func deleteReservation(_ reservation: Reservation) {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ReservationEntity> = ReservationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", reservation.id)
        
        if let entity = try? context.fetch(request).first {
            context.delete(entity)
            
            do {
                try context.save()
            } catch {
                print("删除预定记录失败: \(error)")
            }
        }
    }
}

