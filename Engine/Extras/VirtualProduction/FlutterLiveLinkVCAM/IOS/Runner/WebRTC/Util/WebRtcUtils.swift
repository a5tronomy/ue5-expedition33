// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation
import WebRTC

class WebRtcUtils {
  /**
   * Given the string describing a WebRTC media track kind, return the corresponding enum value.
   *
   * - Parameter string: The string to parse.
   */
  static func parseTrackKind(string: String) -> RtcMediaStreamTrackKind {
    switch (string) {
    case "audio": return RtcMediaStreamTrackKind.audio
    case "video": return RtcMediaStreamTrackKind.video
    default:
      fatalError("Unknown media track kind \(string)")
    }
  }
}
