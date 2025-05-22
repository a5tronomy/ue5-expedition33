// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation
import WebRTC

/** A wrapped PeerConnection that communicates events to the Flutter WebRTC API. */
class FlutterRtcPeerConnection : IdObject {
  /// The API used to send messages to Flutter.
  private let api: FlutterRtcPeerConnectionApi
  
  /// The factory used to create a new peer connection.
  private let peerConnectionFactory: RTCPeerConnectionFactory
  
  /// The RTC configuration to use for this connection.
  private let config: RTCConfiguration
  
  /// The underlying WebRTC peer connection.
  private var connection: RTCPeerConnection?
  
  /// IDs of stream tracks belonging to this connection.
  private var trackIds: Array<Int64> = []
  
  init (api: FlutterRtcPeerConnectionApi, peerConnectionFactory: RTCPeerConnectionFactory, config: RTCConfiguration) {
    self.api = api
    self.peerConnectionFactory = peerConnectionFactory
    self.config = config
  }
  
  /**
   * Set the description of the remote peer.
   * - Parameter description: The session description.
   */
  func setRemoteDescription(description: RtcSessionDescription, completion: @escaping (Result<Void, Error>) -> Void) {
    assert(connection != nil)
    
    connection!.setRemoteDescription(RTCSessionDescription(
      type: description.type.toNative(),
      sdp: description.sdp
    ))
    { error in
      let result: Result = (error == nil) ? Result.success(()) : Result.failure(error!)
      completion(result)
    }
  }
  
  /**
   * Set the description of the local peer.
   * - Parameter description: The session description.
   */
  func setLocalDescription(description: RtcSessionDescription, completion: @escaping (Result<Void, Error>) -> Void) {
    assert(connection != nil)
    
    connection!.setLocalDescription(RTCSessionDescription(
      type: description.type.toNative(),
      sdp: description.sdp
    ))
    { error in
      let result: Result = (error == nil) ? Result.success(()) : Result.failure(error!)
      completion(result)
    }
  }
  
  /**
   * Add an ICE candidate for connecting to the remote peer.
   * - Parameter candidate: The candidate to add.
   */
  func addRemoteCandidate(candidate: RtcIceCandidate, completion: @escaping (Result<Void, Error>) -> Void) {
    assert(connection != nil)
    
    connection!.add(RTCIceCandidate(
      sdp: candidate.candidate,
      sdpMLineIndex: Int32(candidate.sdpMLineIndex),
      sdpMid: candidate.sdpMid
    ))
    { error in
      let result: Result = (error == nil) ? Result.success(()) : Result.failure(error!)
      completion(result)
    }
  }
  
  /**
   * Create an answer to an offered WebRTC session.
   */
  func createAnswer(completion: @escaping (Result<RtcSessionDescription, Error>) -> Void) {
    assert(connection != nil)
    
    let constraints = RTCMediaConstraints(
      mandatoryConstraints: [
        kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
        kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue
      ],
      optionalConstraints: nil
    )
    
    connection!.answer(for: constraints) {
      description, error in
      
      if (error != nil) {
        completion(Result.failure(error!))
        return
      }
      
      assert(description != nil)
      
      completion(Result.success(
        RtcSessionDescription(
          type: description!.type.toFlutter(),
          sdp: description!.sdp
        )
      ))
    }
  }
  
  /**
   * Gather a WebRTC stats report for this connection.
   */
  func getStats(typeFilter: [String]?, completion: @escaping (Result<RtcStatsReport, Error>) -> Void) {
    assert(connection != nil)
    
    connection!.statistics(completionHandler: { nativeReport in
      var statsMap = Dictionary<String?, RtcStats?>()
      
      for (statsKey, stats) in nativeReport.statistics {
        // Skip types that don't pass the filter
        if (typeFilter != nil && !typeFilter!.contains(stats.type)) {
          continue
        }
        
        statsMap[statsKey] = RtcStats(
          timestampUs: stats.timestamp_us,
          type: stats.type,
          id: stats.id,
          values: stats.values
        )
      }
      
      let report = RtcStatsReport(timestampUs: nativeReport.timestamp_us, stats: statsMap)
      completion(Result.success(report))
    })
  }
  
  // MARK: IdObject
  override func onIdReady() -> Bool {
    let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
    
    guard let newConnection = peerConnectionFactory.peerConnection(
      with: config,
      constraints: constraints,
      delegate: self
    ) else {
      return false
    }
    
    connection = newConnection
    
    return true
  }
  
  override func dispose() {
    for trackId in trackIds {
      api.mediaStreamTrackManager.unregister(id: trackId)
    }
    
    connection?.close()
    connection = nil
  }
  // /IndexedObject
}

// MARK: Peer Connection
extension FlutterRtcPeerConnection: RTCPeerConnectionDelegate {
  func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
    let data = RtcIceCandidate(
      candidate: candidate.sdp,
      sdpMid: candidate.sdpMid ?? "",
      sdpMLineIndex: Int64.init(candidate.sdpMLineIndex)
    )
    
    api.callFlutter { flutter in
      flutter.onIceCandidate(connectionId: self.id, candidate: data) {}
    }
  }
  
  func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
    api.callFlutter { flutter in
      flutter.onStateChanged(connectionId: self.id, state: newState.toFlutter()) {}
    }
  }
  
  func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {
    let track: RTCMediaStreamTrack? = transceiver.receiver.track
    if (track == nil) {
      return
    }
    
    let trackId: Int64 = api.mediaStreamTrackManager.register(newObject: FlutterRtcMediaStreamTrack(inner: track!))
    
    api.callFlutter { flutter in
      flutter.onTrack(
        connectionId: self.id,
        event: RtcTrackEvent(
          trackId: trackId,
          kind: WebRtcUtils.parseTrackKind(string: track!.kind)
        )
      ) {}
    }
  }
  
  func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
    let dataChannel: FlutterRtcDataChannel = FlutterRtcDataChannelApi.instance!.register(dataChannel: dataChannel)
    
    api.callFlutter { flutter in
      flutter.onDataChannel(connectionId: self.id, dataChannelId: dataChannel.id) {}
    }
  }
  
  func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
  func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
  func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
  func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
  func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
  func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
  func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
}
