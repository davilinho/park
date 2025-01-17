//
//  ParkViewModel.swift
//  park
//
//  Created by David Martin Nevado on 15/1/25.
//

@preconcurrency import MapKit
import SwiftUI

@Observable
class ParkViewModel {
    var locationManager = LocationManager()

    // Flags
    var status: ParkStatusType = .notParked
    var uiStatus: ParkUIStatusType = .loading
    var isAlertShowing: Bool {
        get {
            self.uiStatus == .alertShowing
        }
        set {
            self.uiStatus = newValue ? .alertShowing : .none
        }
    }
    var isLoading: Bool = true
    var isShowDirections: Bool = false

    // Route
    var route: MKRoute?
    var travelTime: String?
    var selectedPosition: CLLocationCoordinate2D = .init()
    
    func set(status: ParkStatusType) {
        self.status = status
    }
    
    func set(uiStatus: ParkUIStatusType) {
        self.uiStatus = uiStatus
    }

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
    
    @MainActor
    func sharePark(location: ParkModel?) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        guard let location else { return }
        let mapsIntentUrl = "https://www.google.com/maps/dir/?api=1&destination=\(location.latitude),\(location.longitude)&travelmode=walking"
        let activityViewController = UIActivityViewController(activityItems: ["El coche está aparcado aquí: \(mapsIntentUrl)"], applicationActivities: nil)
        rootViewController.present(activityViewController, animated: true, completion: nil)
    }
}
