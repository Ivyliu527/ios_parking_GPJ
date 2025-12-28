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

/// 封装 CLLocationManager，提供位置服务和授权状态管理
class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentAddress: String?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    /// 请求使用中的定位授权
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// 开始更新位置
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    /// 停止更新位置
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    /// 请求授权并开始定位（便捷方法）
    func request() {
        if authorizationStatus == .notDetermined {
            requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            // 如果授权成功，自动开始定位
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
            self.reverseGeocode(location: location)
        }
    }
    
    /// 反向地理编码：将坐标转换为地址
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
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager error: \(error.localizedDescription)")
    }
    
    /// 正向地理编码：将地址转换为坐标
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

