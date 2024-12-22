//
//  ParkWidgetBundle.swift
//  ParkWidget
//
//  Created by David Martin Nevado on 16/12/24.
//

import WidgetKit
import SwiftUI

@main
struct ParkWidgetBundle: WidgetBundle {
    var body: some Widget {
        ParkWidget()
        ParkWidgetControl()
        ParkWidgetLiveActivity()
    }
}
