//
//  ContentView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI
import FirebaseCore

// MARK: - 内容视图

/// 内容视图
/// 根据用户认证状态显示登录界面或主界面
struct ContentView: View {
    // MARK: - 环境对象
    
    /// 认证视图模型
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    // MARK: - 视图主体
    
    /// 视图主体
    /// 根据认证状态显示不同的界面
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

