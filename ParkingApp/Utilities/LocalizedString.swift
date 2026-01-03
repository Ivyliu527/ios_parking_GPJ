//
//  LocalizedString.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation

// MARK: - 本地化字符串辅助函数

/// 本地化字符串辅助函数
/// 支持实时语言切换的本地化字符串获取函数
/// - Parameters:
///   - key: 本地化键
///   - comment: 注释（可选）
/// - Returns: 本地化后的字符串
func NSLocalizedString(_ key: String, comment: String = "") -> String {
    let languageManager = LanguageManager.shared
    let language = languageManager.currentLanguage
    
    // 获取对应的语言代码
    let languageCode: String
    switch language {
    case .system:
        // 使用系统语言
        return Foundation.NSLocalizedString(key, comment: comment)
    case .english:
        languageCode = "en"
    case .simplifiedChinese:
        languageCode = "zh-Hans"
    case .traditionalChinese:
        languageCode = "zh-Hant"
    }
    
    // 尝试从指定语言的 Bundle 中获取字符串
    guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
          let bundle = Bundle(path: path) else {
        // 如果找不到对应语言的 Bundle，使用系统默认
        return Foundation.NSLocalizedString(key, comment: comment)
    }
    
    return bundle.localizedString(forKey: key, value: nil, table: nil)
}

