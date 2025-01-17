//
//  ContentViewModel.swift
//  park
//
//  Created by David Martin Nevado on 15/1/25.
//

@preconcurrency import MapKit
import SwiftUI

enum ParkStatusType {
    case loading
    case parkSelected
    case notParkSelected
}

@Observable
class ContentViewModel {
    // Flags
    var status: ParkStatusType = .loading
    var isLoading: Bool = true
    var isParkSelected: Bool = false
    var isParkAlertShow: Bool = false
    var isShowDirections: Bool = false

    // Route
    var route: MKRoute?
    var travelTime: String?

    func getTravelTime() {
        guard let route else { return }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute]
        self.travelTime = formatter.string(from: route.expectedTravelTime)
    }
    
    @MainActor
    func getDirections(_ source: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking

        Task {
            let result = try? await MKDirections(request: request).calculate()
            self.route = result?.routes.first
            self.getTravelTime()
        }
    }
}
