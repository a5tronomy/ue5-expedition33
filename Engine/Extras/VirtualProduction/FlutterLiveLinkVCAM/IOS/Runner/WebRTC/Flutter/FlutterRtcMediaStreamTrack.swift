// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation
import WebRTC

/**
 * A wrapped WebRTC MediaStreamTrack which can be referred to in Flutter.
 * These tracks are generated and disposed of automatically by WebRTC, so this is just a thin wrapper adding an index.
 */
class FlutterRtcMediaStreamTrack: WrappedIdObject<RTCMediaStreamTrack> {}
