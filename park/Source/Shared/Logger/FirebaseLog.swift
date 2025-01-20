//
//  FirebaseLog.swift
//  park
//
//  Created by David Martin Nevado on 19/1/25.
//

import FirebaseCrashlytics

class FirebaseLog: CoreLog {
    @MainActor static let instance: FirebaseLog = FirebaseLog()

    private init() {
        super.init(identifier: "com.dmn.tech.park", category: "ads")
    }

    override func error(_ message: StaticString, _ args: any CVarArg...) {
        super.error(message, args)
        Crashlytics.crashlytics().setCustomValue(message, forKey: "ads_error")
    }
}
