//
//  NetworkMonitor.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import Network
import Combine

// MARK: - 网络状态监控器

/// 网络状态监控器
/// 实时监控网络连接状态和连接类型（WiFi、蜂窝网络等）
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // MARK: - 连接类型枚举
    
    /// 连接类型枚举
    /// 定义不同的网络连接类型
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    // MARK: - 初始化方法
    
    /// 私有初始化方法
    /// 实现单例模式，初始化时开始监控网络状态
    private init() {
        startMonitoring()
    }
    
    // MARK: - 网络监控
    
    /// 开始监控网络状态
    /// 启动网络路径监控，监听网络状态变化
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .ethernet
                } else {
                    self?.connectionType = .unknown
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
