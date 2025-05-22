// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation
import WebRTC

extension RtcSessionDescriptionType{
  /// Convert from a Flutter session description type to the native WebRTC equivalent.
  func toNative() -> RTCSdpType {
    switch (self) {
    case .answer: return .answer
    case .offer: return .offer
    case .pranswer: return .prAnswer
    case .rollback: return .rollback
    }
  }
}

extension RTCSdpType {
  /// Convert from the native WebRTC session description type to the Flutter equivalent.
  func toFlutter() -> RtcSessionDescriptionType {
    switch (self) {
    case .answer: return .answer
    case .offer: return .offer
    case .prAnswer: return .pranswer
    case .rollback: return .rollback
      
    @unknown default:
      fatalError("Unknown native session description type \(self)")
    }
  }
}

extension RTCPeerConnectionState {
  /// Convert from the native WebRTC connection state to the Flutter equivalent.
  func toFlutter() -> RtcPeerConnectionState {
    switch (self) {
    case .new: return .newConnection
    case .connecting: return .connecting
    case .connected: return .connected
    case .disconnected: return .disconnected
    case .failed: return .failed
    case .closed: return .closed
      
    @unknown default:
      fatalError("Unknown native peer connection state \(self)")
    }
  }
}

extension RTCDataChannelState {
  /// Convert from the native WebRTC data channel state to the Flutter equivalent.
  func toFlutter() -> RtcDataChannelState {
    switch (self) {
    case .connecting: return .connecting
    case .open: return .open
    case .closing: return .closing
    case .closed: return.closed
      
    @unknown default:
      fatalError("Unknown native data channel state state \(self)")
    }
  }
}
