//
//  ReservationViewModel.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI
import Combine

class ReservationViewModel: ObservableObject {
    @Published var reservations: [Reservation] = []
    @Published var activeReservation: Reservation?
    @Published var isLoading = false
    
    private let parkingService = ParkingService.shared
    private let networkService = NetworkService.shared
    private let networkMonitor = NetworkMonitor.shared
    private let coreDataService = CoreDataService.shared
    private var currentUserId: String?
    
    init() {
        // 监听用户登录状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidLogin),
            name: NSNotification.Name("UserDidLogin"),
            object: nil
        )
        
        // 如果已有用户登录，加载数据
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUserId = user.id
            loadReservations()
        }
    }
    
    @objc private func userDidLogin(_ notification: Notification) {
        if let userId = notification.userInfo?["userId"] as? String {
            currentUserId = userId
            loadReservations()
        }
    }
    
    func loadReservations() {
        guard let userId = currentUserId else { return }
        
        // 从 Core Data 加载
        reservations = coreDataService.loadReservations(userId: userId)
        activeReservation = reservations.first { $0.status == .active }
        
        // 如果有网络，尝试同步服务器数据
        if networkMonitor.isConnected {
            Task {
                await syncReservationsFromServer(userId: userId)
            }
        }
    }
    
    private func syncReservationsFromServer(userId: String) async {
        do {
            let serverReservations = try await networkService.fetchReservations(userId: userId)
            await MainActor.run {
                // 合并服务器和本地数据
                var mergedReservations: [Reservation] = []
                var serverReservationIds = Set(serverReservations.map { $0.id })
                
                // 添加服务器数据
                mergedReservations.append(contentsOf: serverReservations)
                
                // 添加本地有但服务器没有的数据（未同步的本地数据）
                for localReservation in self.reservations {
                    if !serverReservationIds.contains(localReservation.id) {
                        mergedReservations.append(localReservation)
                    }
                }
                
                // 更新到 Core Data
                self.reservations = mergedReservations
                self.coreDataService.saveReservations(mergedReservations)
                
                // 更新活动预定
                self.activeReservation = mergedReservations.first { $0.status == .active }
            }
        } catch {
            print("从服务器同步预定记录失败: \(error)")
        }
    }
    
    func saveReservations() {
        guard let userId = currentUserId else { return }
        
        // 保存到 Core Data
        coreDataService.saveReservations(reservations)
        
        // 如果有网络，同步到服务器
        if networkMonitor.isConnected {
            Task {
                do {
                    try await networkService.syncReservations(userId: userId, reservations: reservations)
                } catch {
                    print("同步预定记录到服务器失败: \(error)")
                }
            }
        }
    }
    
    func createReservation(spotId: String, userId: String, duration: TimeInterval) -> Reservation? {
        guard parkingService.reserveSpot(spotId) else {
            return nil
        }
        
        currentUserId = userId
        
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(duration)
        let spot = parkingService.getSpotById(spotId)
        let pricePerHour = spot?.pricePerHour ?? 0.0
        let totalCost = pricePerHour * (duration / 3600.0)
        
        let reservation = Reservation(
            userId: userId,
            parkingSpotId: spotId,
            startTime: startTime,
            endTime: endTime,
            status: .active,
            totalCost: totalCost,
            paymentStatus: .pending
        )
        
        reservations.append(reservation)
        activeReservation = reservation
        
        // 保存到 Core Data
        coreDataService.saveReservation(reservation)
        
        // 如果有网络，同步到服务器
        if networkMonitor.isConnected {
            Task {
                do {
                    try await networkService.syncReservations(userId: userId, reservations: reservations)
                } catch {
                    print("同步预定记录到服务器失败: \(error)")
                }
            }
        }
        
        return reservation
    }
    
    func cancelReservation(_ reservation: Reservation) {
        if let index = reservations.firstIndex(where: { $0.id == reservation.id }) {
            reservations[index].status = .cancelled
            parkingService.releaseSpot(reservation.parkingSpotId)
            if activeReservation?.id == reservation.id {
                activeReservation = nil
            }
            
            // 更新 Core Data
            coreDataService.saveReservation(reservations[index])
            
            // 如果有网络，同步到服务器
            if networkMonitor.isConnected, let userId = currentUserId {
                Task {
                    do {
                        try await networkService.syncReservations(userId: userId, reservations: reservations)
                    } catch {
                        print("同步预定记录到服务器失败: \(error)")
                    }
                }
            }
        }
    }
    
    func completeReservation(_ reservation: Reservation) {
        if let index = reservations.firstIndex(where: { $0.id == reservation.id }) {
            reservations[index].status = .completed
            reservations[index].endTime = Date()
            parkingService.releaseSpot(reservation.parkingSpotId)
            if activeReservation?.id == reservation.id {
                activeReservation = nil
            }
            
            // 更新 Core Data
            coreDataService.saveReservation(reservations[index])
            
            // 如果有网络，同步到服务器
            if networkMonitor.isConnected, let userId = currentUserId {
                Task {
                    do {
                        try await networkService.syncReservations(userId: userId, reservations: reservations)
                    } catch {
                        print("同步预定记录到服务器失败: \(error)")
                    }
                }
            }
        }
    }
    
    func getReservationsForUser(_ userId: String) -> [Reservation] {
        return reservations.filter { $0.userId == userId }
    }
    
    func calculateRemainingTime(_ reservation: Reservation) -> TimeInterval? {
        guard let endTime = reservation.endTime else { return nil }
        let remaining = endTime.timeIntervalSinceNow
        return remaining > 0 ? remaining : 0
    }
}

