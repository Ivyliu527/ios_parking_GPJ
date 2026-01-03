//
//  Extensions.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI

// MARK: - View 扩展

extension View {
    /// 隐藏键盘
    /// 关闭当前显示的键盘
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Date 扩展

extension Date {
    /// 添加小时
    /// 在当前日期基础上添加指定的小时数
    /// - Parameter hours: 要添加的小时数
    /// - Returns: 新的日期对象
    func addingHours(_ hours: Double) -> Date {
        return self.addingTimeInterval(hours * 3600)
    }
}

