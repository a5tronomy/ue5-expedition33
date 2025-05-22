// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation
#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#else
#error("Unsupported platform.")
#endif

/// Workaround for compilation errors originating from Pigeon error handling code.
extension FlutterError: Swift.Error {}
