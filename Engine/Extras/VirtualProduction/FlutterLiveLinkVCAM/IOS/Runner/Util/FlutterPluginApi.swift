// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation

/// Base class for all APIs that communicate to and from a Flutter plugin.
class FlutterPluginApi<T>: NSObject {
  /// The API used to send messages to Flutter.
  private let flutter: T
  
  init (flutter: T) {
    self.flutter = flutter
  }
  
  /// Call a function on the Flutter API.
  /// This will run on the main thread as required for any calls from platform to Flutter.
  func callFlutter(call: @escaping (T) -> Void) {
    DispatchQueue.main.async {
      call(self.flutter)
    }
  }
}
