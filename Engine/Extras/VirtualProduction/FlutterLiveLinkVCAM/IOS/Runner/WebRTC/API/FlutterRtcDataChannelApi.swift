// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation
import WebRTC

/// Handles messages about FlutterRtcDataChannels to and from the Flutter API.
class FlutterRtcDataChannelApi: FlutterPluginApi<RtcDataChannelFlutterApi> {
  init(binaryMessenger: FlutterBinaryMessenger) {
    super.init(flutter: RtcDataChannelFlutterApi(binaryMessenger: binaryMessenger))
    
    RtcDataChannelHostApiSetup.setUp(binaryMessenger: binaryMessenger, api: self)
    FlutterRtcDataChannelApi.instance = self
  }
  
  deinit {
    if (FlutterRtcDataChannelApi.instance === self) {
      FlutterRtcDataChannelApi.instance = nil
    }
  }
  
  /// The active singleton instance of this class.
  private(set) static var instance: FlutterRtcDataChannelApi?
  
  /// Manager for indexed data channels shared with Flutter.
  let dataChannelManager = IdObjectManager<FlutterRtcDataChannel>(debugTypeName: "DataChannel")
  
  /// Convenience function to register a new WebRTC-provided data channel.
  func register(dataChannel: RTCDataChannel) -> FlutterRtcDataChannel {
    let flutterDataChannel = FlutterRtcDataChannel(
      api: self,
      channel: dataChannel
    )
    
    dataChannelManager.register(newObject: flutterDataChannel)
    
    return flutterDataChannel
  }
}


// MARK: Host API
extension FlutterRtcDataChannelApi: RtcDataChannelHostApi {
  func sendMessage(dataChannelId: Int64, buffer: RtcDataBuffer) throws {
    dataChannelManager
      .getChecked(id: dataChannelId)
      .sendMessage(buffer: buffer)
  }
}
