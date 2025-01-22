//
//  ParkViewModel.swift
//  park
//
//  Created by David Martin Nevado on 15/1/25.
//

@preconcurrency import MapKit
import SwiftUI

@MainActor
@Observable
class ParkViewModel {
    var locationManager = LocationManager()
    var bluetoothManager = BluetoothManager()

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

    // Ads
    private var adsTimer: Timer? = nil

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

// MARK: - Ads Controller

extension ParkViewModel {
    private enum Constants {
        static let adsInterval: TimeInterval = 15 //seconds
    }

    func startAdTimer() {
        guard !self.uiStatus.isAdsShowing else { return }
        self.set(uiStatus: .adsShowing)

        self.adsTimer = Timer.scheduledTimer(withTimeInterval: Constants.adsInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.showInterstitialAd()
                self.stopTimer()
                self.set(uiStatus: .none)
            }
        }
    }

    func stopTimer() {
        self.adsTimer?.invalidate()
        self.adsTimer = nil
    }

    private func showInterstitialAd() {
        @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

        if let rootViewController = delegate.rootViewController {
            delegate.interstitial.showInterstitialAd(from: rootViewController)
        }
    }
}
