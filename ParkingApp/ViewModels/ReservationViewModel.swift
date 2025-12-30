//
//  ReservationViewModel.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

class ReservationViewModel: ObservableObject {
    @Published var reservations: [Reservation] = []
    @Published var activeReservation: Reservation?
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private let parkingService = ParkingService.shared
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
        
        // 监听 Firebase Auth 状态
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let userId = user?.uid {
                self?.currentUserId = userId
                self?.loadReservations()
            } else {
                self?.currentUserId = nil
                self?.reservations = []
                self?.activeReservation = nil
            }
        }
        
        // 如果已有用户登录，加载数据
        if let userId = Auth.auth().currentUser?.uid {
            currentUserId = userId
            loadReservations()
        } else if let userData = UserDefaults.standard.data(forKey: "currentUser"),
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
        
        // 从 Core Data 加载（离线支持）
        reservations = coreDataService.loadReservations(userId: userId)
        activeReservation = reservations.first { $0.status == .active }
        
        // 从 Firestore 加载（如果有网络）
        Task {
            await syncReservationsFromFirestore(userId: userId)
        }
    }
    
    private func syncReservationsFromFirestore(userId: String) async {
        do {
            let snapshot = try await db.collection("reservations")
                .whereField("userId", isEqualTo: userId)
                .order(by: "startTime", descending: true)
                .getDocuments()
            
            var firestoreReservations: [Reservation] = []
            
            for document in snapshot.documents {
                if let reservation = reservation(from: document.data(), id: document.documentID) {
                    firestoreReservations.append(reservation)
                }
            }
            
            await MainActor.run {
                // 合并 Firestore 和本地 Core Data 数据
                var mergedReservations: [Reservation] = []
                var firestoreReservationIds = Set(firestoreReservations.map { $0.id })
                
                // 添加 Firestore 数据
                mergedReservations.append(contentsOf: firestoreReservations)
                
                // 添加本地有但 Firestore 没有的数据（未同步的本地数据）
                for localReservation in self.reservations {
                    if !firestoreReservationIds.contains(localReservation.id) {
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
            print("从 Firestore 同步预定记录失败: \(error)")
            // 如果同步失败，继续使用本地 Core Data 数据
        }
    }
    
    /// 将 Firestore 文档数据转换为 Reservation
    private func reservation(from data: [String: Any], id: String) -> Reservation? {
        guard let userId = data["userId"] as? String,
              let parkingSpotId = data["parkingSpotId"] as? String,
              let statusString = data["status"] as? String,
              let status = Reservation.ReservationStatus(rawValue: statusString),
              let totalCost = data["totalCost"] as? Double,
              let paymentStatusString = data["paymentStatus"] as? String,
              let paymentStatus = Reservation.PaymentStatus(rawValue: paymentStatusString) else {
            return nil
        }
        
        var startTime = Date()
        if let startTimeTimestamp = data["startTime"] as? Timestamp {
            startTime = startTimeTimestamp.dateValue()
        } else if let startTimeDouble = data["startTime"] as? Double {
            startTime = Date(timeIntervalSince1970: startTimeDouble / 1000)
        }
        
        var endTime: Date?
        if let endTimeTimestamp = data["endTime"] as? Timestamp {
            endTime = endTimeTimestamp.dateValue()
        } else if let endTimeDouble = data["endTime"] as? Double {
            endTime = Date(timeIntervalSince1970: endTimeDouble / 1000)
        }
        
        return Reservation(
            id: id,
            userId: userId,
            parkingSpotId: parkingSpotId,
            startTime: startTime,
            endTime: endTime,
            status: status,
            totalCost: totalCost,
            paymentStatus: paymentStatus
        )
    }
    
    /// 将 Reservation 转换为 Firestore 文档数据
    private func firestoreData(from reservation: Reservation) -> [String: Any] {
        var data: [String: Any] = [
            "userId": reservation.userId,
            "parkingSpotId": reservation.parkingSpotId,
            "startTime": Timestamp(date: reservation.startTime),
            "status": reservation.status.rawValue,
            "totalCost": reservation.totalCost,
            "paymentStatus": reservation.paymentStatus.rawValue
        ]
        
        if let endTime = reservation.endTime {
            data["endTime"] = Timestamp(date: endTime)
        }
        
        return data
    }
    
    func saveReservations() {
        guard let userId = currentUserId else { return }
        
        // 保存到 Core Data
        coreDataService.saveReservations(reservations)
        
        // 同步到 Firestore
        Task {
            await syncReservationsToFirestore(userId: userId)
        }
    }
    
    private func syncReservationsToFirestore(userId: String) async {
        let batch = db.batch()
        
        for reservation in reservations {
            let reservationRef = db.collection("reservations").document(reservation.id)
            let data = firestoreData(from: reservation)
            batch.setData(data, forDocument: reservationRef, merge: true)
        }
        
        do {
            try await batch.commit()
        } catch {
            print("同步预定记录到 Firestore 失败: \(error)")
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
        
        // 同步到 Firestore
        Task {
            do {
                let reservationRef = db.collection("reservations").document(reservation.id)
                let data = firestoreData(from: reservation)
                try await reservationRef.setData(data, merge: true)
            } catch {
                print("同步预定记录到 Firestore 失败: \(error)")
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
            
            // 同步到 Firestore
            if let userId = currentUserId {
                Task {
                    do {
                        let reservationRef = db.collection("reservations").document(reservations[index].id)
                        let data = firestoreData(from: reservations[index])
                        try await reservationRef.setData(data, merge: true)
                    } catch {
                        print("同步预定记录到 Firestore 失败: \(error)")
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
            
            // 同步到 Firestore
            if let userId = currentUserId {
                Task {
                    do {
                        let reservationRef = db.collection("reservations").document(reservations[index].id)
                        let data = firestoreData(from: reservations[index])
                        try await reservationRef.setData(data, merge: true)
                    } catch {
                        print("同步预定记录到 Firestore 失败: \(error)")
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

