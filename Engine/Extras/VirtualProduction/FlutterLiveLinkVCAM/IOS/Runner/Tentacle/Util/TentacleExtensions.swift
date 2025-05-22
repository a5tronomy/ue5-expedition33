// Copyright Epic Games, Inc. All Rights Reserved.

import Tentacle

extension Tentacle.TentacleProductId {
  /// Convert from a native Tentacle product ID to the Flutter equivalent.
  func toFlutter() -> TentacleProductId {
    switch (self) {
    case TentacleProductIdSyncE: return .syncE
    case TentacleProductIdTrackE: return .trackE
    default: return .generic
    }
  }
}
