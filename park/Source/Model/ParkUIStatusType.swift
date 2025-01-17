//
//  ParkUIStatusType.swift
//  park
//
//  Created by David Martin Nevado on 17/1/25.
//

import Foundation

enum ParkUIStatusType {
    case alertShowing
    case directionsShowing
    case shareActionShowing
    case loading
    case none

    var isAlertShowing: Bool {
        get {
            self == .alertShowing
        }
        set {
            self = newValue ? .alertShowing : .none
        }
    }
    
    var isDirectionsShowing: Bool {
        self == .directionsShowing
    }
    
    var isShareActionShowing: Bool {
        self == .shareActionShowing
    }
    
    var isLoading: Bool {
        self == .loading
    }
    
    var isNone: Bool {
        self == .none
    }
}
