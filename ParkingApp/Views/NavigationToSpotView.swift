//
//  NavigationToSpotView.swift
//  ParkingApp
//
//  Created on 2025
//

import SwiftUI
import MapKit
import CoreLocation

struct NavigationToSpotView: View {
    let spot: ParkingSpot
    @Environment(\.dismiss) var dismiss
    @State private var userLocation: CLLocation?
    @State private var route: MKRoute?
    @State private var showingDirections = false
    
    var body: some View {
        NavigationView {
            VStack {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: spot.location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: [spot]) { spot in
                    MapAnnotation(coordinate: spot.location.coordinate) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title)
                            Text(spot.number)
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(4)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                }
                .frame(height: 300)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Destination")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("Spot \(spot.number)")
                                .font(.headline)
                            Text("Floor \(spot.floor)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            openInMaps()
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Open in Maps")
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    if let route = route {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Route Information")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                Text("Estimated Time: \(formatTime(route.expectedTravelTime))")
                            }
                            
                            HStack {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                    .foregroundColor(.blue)
                                Text("Distance: \(formatDistance(route.distance))")
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Navigate to Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                calculateRoute()
            }
        }
    }
    
    private func calculateRoute() {
        let request = MKDirections.Request()
        let destination = MKPlacemark(coordinate: spot.location.coordinate)
        request.destination = MKMapItem(placemark: destination)
        request.source = MKMapItem.forCurrentLocation()
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first {
                self.route = route
            }
        }
    }
    
    private func openInMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: spot.location.coordinate))
        mapItem.name = "Parking Spot \(spot.number)"
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        return "\(minutes) min"
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.2f km", distance / 1000)
        }
    }
}

