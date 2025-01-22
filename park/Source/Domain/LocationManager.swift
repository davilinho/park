//
// Created by David Martin on 14/2/24.
//

import CoreLocation
import CoreLocationUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.requestWhenInUseAuthorization()
        self.manager.delegate = self
    }

    func requestLocation() {
        self.manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations.first?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            FirebaseLog.instance.error("Location manager: didFailWithError %@", error.localizedDescription)
        }
    }

    func areCoordinatesAtLeastMetersApart(firstLocationCoordinate: CLLocationCoordinate2D, secondLocationCoordinate: CLLocationCoordinate2D,
                                          distanceApart: Double) -> Bool {
        let firstLocation = CLLocation(latitude: firstLocationCoordinate.latitude, longitude: firstLocationCoordinate.longitude)
        let secondLocation = CLLocation(latitude: secondLocationCoordinate.latitude, longitude: secondLocationCoordinate.longitude)
        let distance = firstLocation.distance(from: secondLocation)
        return distance >= distanceApart
    }
}
