// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation

/// Handles messages about [FlutterRtcPeerConnection]s to and from the Flutter API.
class FlutterRtcVideoViewControllerApi: FlutterPluginApi<RtcVideoViewControllerFlutterApi> {
  init(binaryMessenger: FlutterBinaryMessenger) {
    super.init(flutter: RtcVideoViewControllerFlutterApi(binaryMessenger: binaryMessenger))
    
    RtcVideoViewControllerHostApiSetup.setUp(binaryMessenger: binaryMessenger, api: self)
    FlutterRtcVideoViewControllerApi.instance = self
  }
  
  deinit {
    if (FlutterRtcPeerConnectionApi.instance === self) {
      FlutterRtcVideoViewControllerApi.instance = nil
    }
  }
  
  /// Manager for indexed video view controllers shared with Flutter.
  let videoViewControllerManager = IdObjectManager<FlutterRtcVideoViewController>(debugTypeName: "VideoViewController")
  
  /// The active singleton instance of this class.
  private(set) static var instance: FlutterRtcVideoViewControllerApi?
}

// MARK: Host API
extension FlutterRtcVideoViewControllerApi: RtcVideoViewControllerHostApi {
  func create() throws -> Int64 {
    return videoViewControllerManager.register(
      newObject: FlutterRtcVideoViewController(api: self)
    )
  }
  
  func setTrack(controllerId: Int64, trackId: Int64) throws {
    let track: FlutterRtcMediaStreamTrack?
    
    if (trackId == IdObject.invalidId) {
      track = nil
    } else {
      track = FlutterRtcPeerConnectionApi.instance?.mediaStreamTrackManager.getChecked(id: trackId)
    }
    
    videoViewControllerManager
      .getChecked(id: controllerId)
      .setTrack(newTrack: track)
  }
  
  func dispose(controllerId: Int64) throws {
    videoViewControllerManager.unregister(id: controllerId)
  }
}
