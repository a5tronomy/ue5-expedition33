// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation
import WebRTC

/// A wrapped WebRTC data channel which communicates with Flutter.
class FlutterRtcDataChannel : IdObject {
  /// The API used to send messages to Flutter.
  private let api: FlutterRtcDataChannelApi
  
  /// The underlying WebRTC data channel.
  private let channel: RTCDataChannel
  
  init (api: FlutterRtcDataChannelApi, channel: RTCDataChannel) {
    self.api = api
    self.channel = channel
    
    super.init()
    
    channel.delegate = self
  }
  
  /// Send a message on the data channel.
  func sendMessage(buffer: RtcDataBuffer) {
    channel.sendData(RTCDataBuffer(data: buffer.data.data, isBinary: buffer.bIsBinary))
  }
}

// MARK: Data Channel
extension FlutterRtcDataChannel: RTCDataChannelDelegate {
  func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
    api.callFlutter { flutter in
      flutter.onStateChanged(
        dataChannelId: self.id,
        state: self.channel.readyState.toFlutter()
      ) {}
    }
    
    if (self.channel.readyState == .closed) {
      api.dataChannelManager.unregister(id: id)
    }
  }
  
  func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
    api.callFlutter { flutter in
      flutter.onMessage(
        dataChannelId: self.id,
        buffer: RtcDataBuffer(
          data: FlutterStandardTypedData(bytes: buffer.data),
          bIsBinary: buffer.isBinary
        )
      ) {}
    }
  }
}
