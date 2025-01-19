//
//  ParkStatusType.swift
//  park
//
//  Created by David Martin Nevado on 17/1/25.
//

import Foundation

enum ParkStatusType {
    case parked
    case notParked

    var isParked: Bool {
        self == .parked
    }
    
    var iusNotParked: Bool {
        self == .notParked
    }
}
