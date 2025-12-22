//
//  PaymentView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI

struct PaymentView: View {
    let reservation: Reservation
    @EnvironmentObject var reservationViewModel: ReservationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var cardNumber = ""
    @State private var cardHolderName = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var isProcessing = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Payment Summary")) {
                    HStack {
                        Text("Total Amount")
                        Spacer()
                        Text("$\(String(format: "%.2f", reservation.totalCost))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("Card Information")) {
                    TextField("Card Number", text: $cardNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: cardNumber) { newValue in
                            cardNumber = formatCardNumber(newValue)
                        }
                    
                    TextField("Card Holder Name", text: $cardHolderName)
                        .autocapitalization(.words)
                    
                    HStack {
                        TextField("MM/YY", text: $expiryDate)
                            .keyboardType(.numberPad)
                            .onChange(of: expiryDate) { newValue in
                                expiryDate = formatExpiryDate(newValue)
                            }
                        
                        SecureField("CVV", text: $cvv)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .onChange(of: cvv) { newValue in
                                if newValue.count > 3 {
                                    cvv = String(newValue.prefix(3))
                                }
                            }
                    }
                }
                
                Section {
                    Button(action: processPayment) {
                        if isProcessing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Pay $\(String(format: "%.2f", reservation.totalCost))")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing || !isFormValid)
                }
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
            }
            .alert("Payment Successful", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your reservation has been confirmed!")
            }
        }
    }
    
    private var isFormValid: Bool {
        cardNumber.count >= 16 &&
        !cardHolderName.isEmpty &&
        expiryDate.count == 5 &&
        cvv.count == 3
    }
    
    private func formatCardNumber(_ number: String) -> String {
        let cleaned = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let limited = String(cleaned.prefix(16))
        let grouped = limited.chunked(into: 4)
        return grouped.joined(separator: " ")
    }
    
    private func formatExpiryDate(_ date: String) -> String {
        let cleaned = date.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let limited = String(cleaned.prefix(4))
        if limited.count >= 2 {
            let month = String(limited.prefix(2))
            let year = limited.count > 2 ? String(limited.suffix(2)) : ""
            return year.isEmpty ? month : "\(month)/\(year)"
        }
        return limited
    }
    
    private func processPayment() {
        isProcessing = true
        
        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Update reservation payment status
            if let index = reservationViewModel.reservations.firstIndex(where: { $0.id == reservation.id }) {
                reservationViewModel.reservations[index].paymentStatus = .paid
                reservationViewModel.saveReservations()
            }
            
            isProcessing = false
            showSuccess = true
        }
    }
}

extension String {
    func chunked(into size: Int) -> [String] {
        var chunks: [String] = []
        var index = startIndex
        
        while index < endIndex {
            let end = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[index..<end]))
            index = end
        }
        
        return chunks
    }
}

