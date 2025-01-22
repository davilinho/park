//
// Created by David Martin on 6/6/24.
//

import SwiftUI
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isConnected: Bool = false

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?

    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: "com.park.bluetooth"])
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            DispatchQueue.main.async {
                FirebaseLog.instance.info("Bluetooth is not available.")
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.centralManager.stopScan()
        self.connectedPeripheral = peripheral
        self.centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.isConnected = true
        self.connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.isConnected = false
        self.connectedPeripheral = nil
        self.centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
}
