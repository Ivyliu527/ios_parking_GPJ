//
//  LanguageManager.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI
import Combine

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

/// 语言管理器
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            // 发送语言变更通知
            NotificationCenter.default.post(name: .languageChanged, object: nil)
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
    }
}

