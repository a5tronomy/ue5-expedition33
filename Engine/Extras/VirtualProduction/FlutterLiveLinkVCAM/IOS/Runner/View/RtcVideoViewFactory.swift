// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation
import WebRTC

/// A factory that creates [RtcVideoView]s with the given creation parameters.
class RtcVideoViewFactory: NSObject {
  private var messenger: FlutterBinaryMessenger
  
  init (messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }
  
}

extension RtcVideoViewFactory: FlutterPlatformViewFactory {
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    let creationParams = (args as? Dictionary<String, Any?>) ?? [:]
    
    return RtcVideoView(frame: frame, viewId: viewId, creationParams: creationParams, messenger: messenger)
  }
  
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}
