//
//  LanguageSettingsView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI

/// 语言设置视图
struct LanguageSettingsView: View {
    @ObservedObject var languageManager = LanguageManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var refreshID = UUID()
    
    var body: some View {
        List {
            Section(header: Text(NSLocalizedString("select_language"))) {
                ForEach(LanguageManager.AppLanguage.allCases, id: \.self) { language in
                    Button(action: {
                        languageManager.currentLanguage = language
                        refreshID = UUID()
                    }) {
                        HStack {
                            Text(language.displayName)
                            Spacer()
                            if languageManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            
        }
        .navigationTitle(NSLocalizedString("language_settings"))
        .navigationBarTitleDisplayMode(.inline)
        .id(refreshID)
    }
}

