//
//  Extensions.swift
//  ParkingApp
//
//  Created on 2025
//

import Foundation
import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension Date {
    func addingHours(_ hours: Double) -> Date {
        return self.addingTimeInterval(hours * 3600)
    }
}

