// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation
import Tentacle

/// Handles messages about Tentacle to and from the Flutter API.
class FlutterTentacleApi: FlutterPluginApi<TentacleFlutterApi> {
  /// The Bluetooth controller that scans for Tentacle devices.
  private var bluetooth: TentacleBluetoothController!
  
  /// Whether this should attempt to scan for Tentacle devices.
  private var bIsScanning: Bool = false
  
  init(binaryMessenger: FlutterBinaryMessenger) {
    super.init(flutter:TentacleFlutterApi(binaryMessenger: binaryMessenger))
    
    TentacleHostApiSetup.setUp(binaryMessenger: binaryMessenger, api: self)
    FlutterTentacleApi.instance = self
    
    bluetooth = TentacleBluetoothController()
    bluetooth.delegate = self
  }
  
  deinit {
    if (FlutterTentacleApi.instance === self) {
      FlutterTentacleApi.instance = nil
    }
  }
  
  /// The active singleton instance of this class.
  private(set) static var instance: FlutterTentacleApi?
  
  /// Convert a C string with the given length to a Swift string.
  private func stringFromCString<T>(cString: inout T, length: Int) -> String {
    return withUnsafePointer(to: cString) { startPointer in
      return startPointer.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: length)) { cStringPointer in
          return String(cString: cStringPointer)
      }
    }
  }
}

// MARK: Host API
extension FlutterTentacleApi: TentacleHostApi {
  func startScanning() throws {
    bIsScanning = true
    bluetooth.startScanning()
  }
  
  func stopScanning() throws {
    bIsScanning = false
    bluetooth.stopScanning()
  }
  
  func getCachedDeviceInfo() throws -> [TentacleDeviceInfo] {
    var devices: [TentacleDeviceInfo] = []
    let deviceCount: Int32 = Int32(Tentacle.TentacleDeviceCacheGetSize())
  
    for deviceIndex in stride(from: 0, to: deviceCount, by: 1) {
      let device: TentacleDevice = Tentacle.TentacleDeviceCacheGetDevice(deviceIndex)
      var advert: TentacleAdvertisement = device.advertisement
      
      devices.append(TentacleDeviceInfo(
        bIsInGreenMode: advert.greenMode,
        bIsCharging: advert.charging,
        bIsDropFrame: advert.dropFrame,
        batteryLevel: Int64(advert.battery),
        frameRate: Tentacle.TentacleAdvertisementGetFrameRate(&advert),
        lastSeenTimestamp: CACurrentMediaTime(),
        iconIndex: Int64(advert.icon),
        signalStrength: Int64(advert.rssi),
        productId: advert.productId.toFlutter(),
        identifier: stringFromCString(cString: &advert.identifier, length: advert.identifierLength),
        name: stringFromCString(cString: &advert.name, length: advert.nameLength)
      ))
    }
    
    return devices
  }
}

// MARK: Bluetooth Controller Delegate
extension FlutterTentacleApi : TentacleBluetoothControllerDelegate {
  func didUpdate(to state: TentacleBluetoothState) {
      if state == .poweredOn && bIsScanning {
          bluetooth.startScanning()
      }
  }
}
