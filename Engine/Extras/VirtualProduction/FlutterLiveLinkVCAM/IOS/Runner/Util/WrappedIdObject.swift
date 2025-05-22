// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation

/// A thin wrapper for an object that allows it to be registered and looked up by its ID.
class WrappedIdObject<T>: IdObject {
  let inner: T
  
  init(inner: T) {
    self.inner = inner
  }
}
