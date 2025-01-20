//
//  CoreLog.swift
//  park
//
//  Created by David Martin Nevado on 19/1/25.
//

import Foundation
import os.log

class CoreLog {
    let internalLog: OSLog?

    init(identifier: String = "", category: String = "") {
        if !identifier.isEmpty, !category.isEmpty {
            self.internalLog = OSLog(subsystem: identifier, category: category)
        } else {
            self.internalLog = nil
        }
    }

    private func log(_ message: StaticString, _ type: OSLogType, _ args: CVarArg...) {
        os_log(message, log: self.internalLog ?? .default, type: type, args)
    }

    func info(_ message: StaticString, _ args: CVarArg...) {
        self.log(message, .info, args)
    }

    func debug(_ message: StaticString, _ args: CVarArg...) {
        self.log(message, .debug, args)
    }

    func error(_ message: StaticString, _ args: CVarArg...) {
        self.log(message, .error, args)
    }

    func fault(_ message: StaticString, _ args: CVarArg...) {
        self.log(message, .fault, args)
    }
}
