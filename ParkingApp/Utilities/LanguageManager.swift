//
//  LanguageManager.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI
import Combine

// MARK: - 通知名称扩展

extension Notification.Name {
    /// 语言变更通知名称
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - 语言管理器

/// 语言管理器
/// 管理应用的多语言支持，包括语言切换和 API 语言代码转换
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            // 发送语言变更通知
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    
    // MARK: - 应用语言枚举
    
    /// 应用语言枚举
    /// 定义应用支持的语言类型
    enum AppLanguage: String, CaseIterable {
        case system = "system"
        case english = "en"
        case simplifiedChinese = "zh-Hans"
        case traditionalChinese = "zh-Hant"
        
        // MARK: - 计算属性
        
        /// 显示名称
        /// 返回语言的显示名称
        var displayName: String {
            switch self {
            case .system:
                return NSLocalizedString("language_system", comment: "")
            case .english:
                return "English"
            case .simplifiedChinese:
                return "简体中文"
            case .traditionalChinese:
                return "繁體中文"
            }
        }
        
        /// API 语言代码
        /// 返回用于 API 请求的语言代码
        var apiLang: String {
            switch self {
            case .system:
                // 根据系统语言返回
                let preferredLanguage = Locale.preferredLanguages.first ?? "en"
                if preferredLanguage.contains("zh-Hans") || preferredLanguage.contains("zh_CN") {
                    return "zh_CN"
                } else if preferredLanguage.contains("zh") {
                    return "zh_TW"
                }
                return "en_US"
            case .english:
                return "en_US"
            case .simplifiedChinese:
                return "zh_CN"
            case .traditionalChinese:
                return "zh_TW"
            }
        }
    }
    
    // MARK: - 初始化方法
    
    /// 私有初始化方法
    /// 实现单例模式，从 UserDefaults 加载保存的语言设置
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .system
        }
    }
}

