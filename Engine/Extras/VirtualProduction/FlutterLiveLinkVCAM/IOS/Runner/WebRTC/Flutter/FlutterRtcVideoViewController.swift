// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation
import WebRTC

protocol FlutterRtcVideoViewControllerListener: AnyObject {
  /**
   Called when the active video track changes.
   
   - Parameter track: The new video track.
   */
  func videoViewController(didChangeVideoTrack track: RTCVideoTrack?)
}

/// Controller for a video view which communicates with Flutter.
class FlutterRtcVideoViewController: IdObject {
  /// The API used to send messages to Flutter.
  private let api: FlutterRtcVideoViewControllerApi
  
  /// The current video track to be displayed.
  private var _track: RTCVideoTrack?
  
  /// Listeners for changes to the changes in the controller's state.
  private var listeners: [FlutterRtcVideoViewControllerListener] = []
  
  /// The current video track to be displayed.
  var track: RTCVideoTrack? {
    get {
      return _track
    }
  }
  
  init(api: FlutterRtcVideoViewControllerApi) {
    self.api = api
  }
  
  override func dispose() {
    _track?.remove(self)
  }
  
  /**
   Set the Flutter track to be displayed.
   
   - Parameter newTrack: The new track to display.
   */
  func setTrack(newTrack: FlutterRtcMediaStreamTrack?) {
    var newVideoTrack: RTCVideoTrack?
    
    if (newTrack?.inner != nil) {
      newVideoTrack = newTrack!.inner as? RTCVideoTrack
      
      if (newVideoTrack == nil) {
        fatalError("Track \(newTrack!.id) is not a video track")
      }
    }
    
    _track = newVideoTrack!
    _track!.add(self)
    
    listeners.forEach { listener in
      listener.videoViewController(didChangeVideoTrack: _track)
    }
  }
  
  /// Listen for state changes to this controller.
  func addListener(listener: FlutterRtcVideoViewControllerListener) {
    listeners.append(listener)
  }
  
  /// Stop listening for state changes to this controller.
  func removeListener(listener: FlutterRtcVideoViewControllerListener) {
    guard let index: Int = listeners.firstIndex(where: { $0 === listener }) else {
      return
    }
    
    listeners.remove(at: index)
  }
}

extension FlutterRtcVideoViewController: RTCVideoRenderer {
  func setSize(_ size: CGSize) {
    api.callFlutter { flutter in
      flutter.onFrameSizeChanged(
        controllerId: self.id,
        width: Int64(size.width),
        height: Int64(size.height)
      ) {}
    }
  }
  
  func renderFrame(_ frame: RTCVideoFrame?) {}
}
