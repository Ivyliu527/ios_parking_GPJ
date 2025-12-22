# Parking App - iOS Application

A comprehensive parking management iOS application built with SwiftUI.

## Features

### ✅ Completed Features

1. **User Authentication**
   - User login and registration
   - User profile management
   - Session persistence

2. **Parking Spot Management**
   - View available parking spots
   - Filter by floor, availability, and features
   - Search functionality
   - Real-time availability status

3. **Map View**
   - Interactive map showing all parking spots
   - Color-coded markers (green for available, red for occupied)
   - Tap to view spot details

4. **Reservation System**
   - Reserve parking spots
   - Select reservation duration (0.5 to 24 hours)
   - Real-time cost calculation
   - Active reservation tracking

5. **Payment Integration**
   - Secure payment processing
   - Credit card input with validation
   - Payment confirmation

6. **Reservation History**
   - View all past and active reservations
   - Cancel active reservations
   - View reservation details and costs

7. **Navigation**
   - Navigate to reserved parking spot
   - Integration with Apple Maps
   - Route calculation and directions

8. **Timer Functionality**
   - Real-time countdown for active reservations
   - Automatic cost calculation
   - End reservation functionality

## Project Structure

```
ParkingApp/
├── ParkingApp/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── ParkingSpot.swift
│   │   └── Reservation.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── LoginView.swift
│   │   ├── MainTabView.swift
│   │   ├── ParkingMapView.swift
│   │   ├── ParkingListView.swift
│   │   ├── ReservationView.swift
│   │   ├── ReservationHistoryView.swift
│   │   ├── PaymentView.swift
│   │   ├── ProfileView.swift
│   │   └── NavigationToSpotView.swift
│   ├── ViewModels/
│   │   ├── AuthenticationViewModel.swift
│   │   ├── ParkingViewModel.swift
│   │   └── ReservationViewModel.swift
│   ├── Services/
│   │   └── ParkingService.swift
│   ├── Utilities/
│   │   └── Extensions.swift
│   ├── ParkingAppApp.swift
│   └── Info.plist
└── README.md
```

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## Setup Instructions

1. Open the project in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run the project

## Usage

1. **Register/Login**: Create an account or login with existing credentials
2. **Browse Spots**: View available parking spots on map or list
3. **Reserve**: Select a spot and choose reservation duration
4. **Pay**: Complete payment for your reservation
5. **Navigate**: Use the navigation feature to find your spot
6. **Manage**: View and manage your reservations in the History tab

## Data Storage

The app currently uses UserDefaults for local data persistence. For production, consider implementing:
- Core Data or SQLite for local database
- Backend API integration for server-side data management

## Future Enhancements

- Push notifications for reservation reminders
- QR code scanning for spot verification
- Integration with payment gateways (Stripe, PayPal)
- Real-time spot availability updates
- Multiple parking lot support
- User reviews and ratings

## License

This project is created for educational purposes.

