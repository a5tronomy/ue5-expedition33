// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation
import WebRTC

/// Handles messages about FlutterRtcPeerConnections to and from the Flutter API.
class FlutterRtcPeerConnectionApi: FlutterPluginApi<RtcPeerConnectionFlutterApi> {
  init(binaryMessenger: FlutterBinaryMessenger) {
    super.init(flutter: RtcPeerConnectionFlutterApi(binaryMessenger: binaryMessenger))
    
    RtcPeerConnectionHostApiSetup.setUp(binaryMessenger: binaryMessenger, api: self)
    FlutterRtcPeerConnectionApi.instance = self
    
    self.audioQueue.async { [weak self] in
        guard let self = self else {
            return
        }
        
        self.rtcAudioSession.lockForConfiguration()
        do {
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.ambient)
            try self.rtcAudioSession.setMode(AVAudioSession.Mode.default)
        } catch let error {
            debugPrint("Error setting AVAudioSession category: \(error)")
        }
        self.rtcAudioSession.unlockForConfiguration()
    }
  }
  
  deinit {
    if (FlutterRtcPeerConnectionApi.instance === self) {
      FlutterRtcPeerConnectionApi.instance = nil
    }
  }
  
  /// The active singleton instance of this class.
  private(set) static var instance: FlutterRtcPeerConnectionApi?
  
  /// Manager for indexed peer connections shared with Flutter.
  private let peerConnectionManager = IdObjectManager<FlutterRtcPeerConnection>(debugTypeName: "PeerConnection")
  
  /// Manager for indexed media stream tracks shared with Flutter.
  let mediaStreamTrackManager = IdObjectManager<FlutterRtcMediaStreamTrack>(debugTypeName: "MediaStreamTrack")
  
  /// Video decoder used for incoming video streams. Not actually used, but necessary to create an RTCPeerConnectionFactory.
  private let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
  
  /// Video decoder used for incoming video streams.
  private let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
  
  /// Dispatch queue used for async audio system calls.
  private let audioQueue = DispatchQueue(label: "audio")
  
  /// The audio session used to handle WebRTC audio data.
  private let rtcAudioSession =  RTCAudioSession.sharedInstance()
  
  /// Factory used to create PeerConnections as requested by the client.
  private var _peerConnectionFactory: RTCPeerConnectionFactory?
  private var peerConnectionFactory: RTCPeerConnectionFactory {
    get {
      if (_peerConnectionFactory == nil) {
        _peerConnectionFactory = makePeerConnectionFactory()
      }
      
      return _peerConnectionFactory!
    }
    
    set {
      _peerConnectionFactory = newValue
    }
  }
  
  /// Field trials passed from Flutter to be used when creating connections.
  private var fieldTrials: Dictionary<String, String>? = [:]
  
  /// Clean up any allocated resources.
  func disposeAll() {
    peerConnectionManager.disposeAll()
    mediaStreamTrackManager.disposeAll()
    _peerConnectionFactory = nil
  }
  
  /// Make a new factory for producing peer connections with the current configuration.
  private func makePeerConnectionFactory() -> RTCPeerConnectionFactory {
    RTCInitFieldTrialDictionary(fieldTrials)
    
    return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
  }
}

// MARK: Host API
extension FlutterRtcPeerConnectionApi: RtcPeerConnectionHostApi {
  func setFieldTrials(fieldTrials: [String: String]?) throws {
    self.fieldTrials = fieldTrials
    
    // Dispose of existing factory since the settings were changed.
    // This will be lazily recreated.
    _peerConnectionFactory = nil
  }
  
  func create() throws -> Int64 {
    let config = RTCConfiguration()
    config.sdpSemantics = .unifiedPlan
    config.continualGatheringPolicy = .gatherContinually
    
    return peerConnectionManager.register(newObject: FlutterRtcPeerConnection(
      api: self,
      peerConnectionFactory: peerConnectionFactory,
      config: config
    ))
  }
  
  func dispose(connectionId: Int64) throws {
    peerConnectionManager.unregister(id: connectionId)?.onUnregistered()
  }
  
  func setRemoteDescription(connectionId: Int64, description: RtcSessionDescription, completion: @escaping (Result<Void, Error>) -> Void) {
    peerConnectionManager
      .getChecked(id: connectionId)
      .setRemoteDescription(
        description: description,
        completion: completion
      )
  }
  
  func setLocalDescription(connectionId: Int64, description: RtcSessionDescription, completion: @escaping (Result<Void, Error>) -> Void) {
    peerConnectionManager
      .getChecked(id: connectionId)
      .setLocalDescription(
        description: description,
        completion: completion
      )
  }
  
  func addRemoteCandidate(connectionId: Int64, candidate: RtcIceCandidate, completion: @escaping (Result<Void, Error>) -> Void) {
    peerConnectionManager
      .getChecked(id: connectionId)
      .addRemoteCandidate(candidate: candidate, completion: completion)
  }

  func createAnswer(connectionId: Int64, completion: @escaping (Result<RtcSessionDescription, Error>) -> Void) {
    peerConnectionManager
      .getChecked(id: connectionId)
      .createAnswer(completion: completion)
  }
  
  func getStats(connectionId: Int64, typeFilter: [String]?, completion: @escaping (Result<RtcStatsReport, Error>) -> Void) {
    peerConnectionManager
      .getChecked(id: connectionId)
      .getStats(typeFilter: typeFilter, completion: completion)
  }
}
