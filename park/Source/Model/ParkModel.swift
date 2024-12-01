//
// Created by David Martin on 13/2/24.
//

import Foundation
import SwiftData

@Model
final class ParkModel {
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var isSelected: Bool

    init(latitude: Double,
         longitude: Double,
         timestamp: Date,
         isSelected: Bool) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.isSelected = isSelected
    }
}
