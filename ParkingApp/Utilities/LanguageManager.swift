//
//  LanguageManager.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI
import Combine

/// 语言管理器
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            // 更新 Bundle 的语言设置
            setLanguage(currentLanguage)
        }
    }
    
    enum AppLanguage: String, CaseIterable {
        case system = "system"
        case english = "en"
        case simplifiedChinese = "zh-Hans"
        case traditionalChinese = "zh-Hant"
        
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
    
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .system
        }
        setLanguage(currentLanguage)
    }
    
    private func setLanguage(_ language: AppLanguage) {
        // 注意：iOS 应用的语言切换需要重启应用才能完全生效
        // 这里我们保存设置，应用重启后会应用
        if language != .system {
            UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }
}

