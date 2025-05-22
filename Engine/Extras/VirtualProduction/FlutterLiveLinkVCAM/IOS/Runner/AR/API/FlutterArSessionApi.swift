// Copyright Epic Games, Inc. All Rights Reserved.

import ARKit
import Foundation

/// Handles messages about FlutterArSessions to and from the Flutter API.
class FlutterArSessionApi: FlutterPluginApi<ArSessionFlutterApi> {
  init(binaryMessenger: FlutterBinaryMessenger) {
    super.init(flutter: ArSessionFlutterApi(binaryMessenger: binaryMessenger))
    
    ArSessionHostApiSetup.setUp(binaryMessenger: binaryMessenger, api: self)
    FlutterArSessionApi.instance = self
  }
  
  deinit {
    if (FlutterArSessionApi.instance === self) {
      FlutterArSessionApi.instance = nil
    }
  }
  
  /// The active singleton instance of this class.
  private(set) static var instance: FlutterArSessionApi?
  
  /// Manager for indexed AR sessions shared with Flutter.
  private let sessionManager = IdObjectManager<FlutterArSession>(debugTypeName: "ARSession")
}


// MARK: Host API
extension FlutterArSessionApi: ArSessionHostApi {
  func initialize(completion: @escaping (Result<ArAvailability, Error>) -> Void) {
    completion(Result.success(ARPositionalTrackingConfiguration.isSupported ? ArAvailability.available : ArAvailability.notSupported))
  }
  
  func create(completion: @escaping (Result<Int64, Error>) -> Void) {
    let id: Int64 = sessionManager.register(newObject: FlutterArSession(
      api: self
    ))
    
    completion(Result.success(id))
  }
  
  func dispose(sessionId: Int64) throws {
    sessionManager.unregister(id: sessionId)
  }
  
  func run(sessionId: Int64) throws {
    sessionManager.getChecked(id: sessionId).run()
  }
  
  func pause(sessionId: Int64) throws {
    sessionManager.getChecked(id: sessionId).pause()
  }
  
}
