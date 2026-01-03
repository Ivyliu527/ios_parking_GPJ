//
//  LocationManager.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

// MARK: - 位置管理器

/// 位置管理器
/// 封装 CLLocationManager，提供位置服务和授权状态管理
/// 支持位置获取、地理编码和反向地理编码功能
class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentAddress: String?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // MARK: - 初始化方法
    
    /// 初始化方法
    /// 设置位置管理器的代理和精度
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - 位置授权管理
    
    /// 请求使用中的定位授权
    /// 请求应用在使用时访问位置的权限
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - 位置更新控制
    
    /// 开始更新位置
    /// 开始持续获取用户位置信息
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    /// 停止更新位置
    /// 停止获取用户位置信息，节省电量
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    /// 请求授权并开始定位（便捷方法）
    /// 自动处理授权请求和位置更新
    func request() {
        if authorizationStatus == .notDetermined {
            requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate 代理方法

extension LocationManager: CLLocationManagerDelegate {
    /// 授权状态变化回调
    /// 当位置授权状态改变时调用
    /// - Parameter manager: 位置管理器实例
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            // 如果授权成功，自动开始定位
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.startUpdatingLocation()
            }
        }
    }
    
    /// 位置更新回调
    /// 当获取到新的位置信息时调用
    /// - Parameters:
    ///   - manager: 位置管理器实例
    ///   - locations: 位置数组
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
            self.reverseGeocode(location: location)
        }
    }
    
    // MARK: - 地理编码功能
    
    /// 反向地理编码
    /// 将坐标转换为地址字符串
    /// - Parameter location: 位置坐标
    private func reverseGeocode(location: CLLocation) {
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("反向地理编码失败: \(error.localizedDescription)")
                    self?.currentAddress = nil
                    return
                }
                
                if let placemark = placemarks?.first {
                    var addressComponents: [String] = []
                    
                    // 街道地址
                    if let thoroughfare = placemark.thoroughfare {
                        addressComponents.append(thoroughfare)
                    }
                    
                    // 子街道
                    if let subThoroughfare = placemark.subThoroughfare {
                        addressComponents.append(subThoroughfare)
                    }
                    
                    // 区域/行政区
                    if let locality = placemark.locality {
                        addressComponents.append(locality)
                    }
                    
                    // 如果还没有地址，使用名称
                    if addressComponents.isEmpty, let name = placemark.name {
                        addressComponents.append(name)
                    }
                    
                    // 如果还是没有，使用地区和国家
                    if addressComponents.isEmpty {
                        if let administrativeArea = placemark.administrativeArea {
                            addressComponents.append(administrativeArea)
                        }
                        if let country = placemark.country {
                            addressComponents.append(country)
                        }
                    }
                    
                    self?.currentAddress = addressComponents.isEmpty ? nil : addressComponents.joined(separator: " ")
                } else {
                    self?.currentAddress = nil
                }
            }
        }
    }
    
    /// 位置获取失败回调
    /// 当位置获取失败时调用
    /// - Parameters:
    ///   - manager: 位置管理器实例
    ///   - error: 错误信息
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager error: \(error.localizedDescription)")
    }
    
    /// 正向地理编码
    /// 将地址字符串转换为坐标位置
    /// - Parameters:
    ///   - address: 地址字符串
    ///   - completion: 完成回调，返回地点标记数组
    func geocodeAddress(_ address: String, completion: @escaping ([CLPlacemark]?) -> Void) {
        geocoder.cancelGeocode()
        geocoder.geocodeAddressString(address) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("地理编码失败: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                completion(placemarks)
            }
        }
    }
}

