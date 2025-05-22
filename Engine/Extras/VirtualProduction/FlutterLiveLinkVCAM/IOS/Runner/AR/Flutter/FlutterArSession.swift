// Copyright Epic Games, Inc. All Rights Reserved.

import ARKit
import Foundation

/** A wrapped ARSession that communicates events to the Flutter AR API. */
class FlutterArSession: IdObject {
  /// The API used to send messages to Flutter.
  private let api: FlutterArSessionApi
  
  /// The underlying AR session.
  private var session: ARSession?
  
  /// The current state of the session's camera tracking.
  private var trackingState: ArTrackingState = ArTrackingState.unavailable
  
  init (api: FlutterArSessionApi) {
    self.api = api
    session = ARSession()
    
    super.init()
    
    session!.delegate = self
  }
  
  /// Run the AR session.
  func run() {
    // Create an ARKit tracking config for purely tracking device transform (we don't care about the computer vision features)
    let config = ARPositionalTrackingConfiguration()
    config.worldAlignment = .gravity
    config.planeDetection = []
    config.isLightEstimationEnabled = false
    config.providesAudioData = false
    
    session!.run(config)
  }
  
  /// Pause the AR session.
  func pause() {
    session!.pause()
  }
  
  override func dispose() {
    session?.pause()
    session?.delegate = nil
    session = nil
  }
  
  /**
   Update the tracking state based on the state of an AR camera.
   - Parameter newState: The new tracking state.
   */
  private func updateTrackingState(newState: ARCamera.TrackingState) {
    var newTrackingState: ArTrackingState
    
    switch (newState) {
    case .normal:
      newTrackingState = .normal
      break
      
    case .limited:
      newTrackingState = .limited
      break
      
    default:
      newTrackingState = .unavailable
      break
    }
    
    if (newTrackingState != trackingState) {
      trackingState = newTrackingState
      
      api.callFlutter { flutter in
        flutter.onTrackingStateChanged(sessionId: self.id, state: self.trackingState) {}
      }
    }
  }
}

extension FlutterArSession: ARSessionDelegate {
  func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    updateTrackingState(newState: camera.trackingState)
  }
  
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    updateTrackingState(newState: frame.camera.trackingState)
    
    if (self.trackingState != .normal) {
      // Tracking data is inaccurate when not in normal mode
      return
    }
    
    Swift.withUnsafeBytes(of: frame.camera.transform) { matrixBytes in
      assert(matrixBytes.baseAddress != nil)
      
      let data = Data(bytes: matrixBytes.baseAddress!, count: matrixBytes.count)
      let flutterFrame = ArFrame(cameraTransformData: FlutterStandardTypedData(bytes: data))
      
      api.callFlutter { flutter in
        flutter.onFrame(sessionId: self.id, frame: flutterFrame) {}
      }
    }
  }
}
