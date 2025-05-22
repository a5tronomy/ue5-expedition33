// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation

/// An object associated with an ID which can be used to refer to it when communicating with Flutter.
class IdObject: NSObject {
  /// Index that indicates an IndexedObject that is not managed.
  static let invalidId: Int64 = -1
  
  /// The unique ID referring to this object within its manager.
  private(set) var id: Int64 = invalidId
  
  /// The manager that tracks this object.
  private var manager: (any BaseIdObjectManager)? = nil
  
  /// Whether this has been disposed of by its manager.
  private var bIsDisposed: Bool = false
  
  /**
   Called when this is registered to a manager and provided an ID.
   
   - Returns: false if this failed to initialize, else true
   */
  func onRegistered(id: Int64, manager: (any BaseIdObjectManager)) -> Bool {
    assert(self.manager == nil, "IndexedObject initialized more than once")
    
    self.id = id
    self.manager = manager
    
    if (!onIdReady()) {
      self.id = IdObject.invalidId
      self.manager = nil
      return false
    }
    
    return true
  }
  
  /**
   Called when this is unregistered from the manager.
   */
  func onUnregistered() {
    if (bIsDisposed) {
      return
    }
    
    dispose()
    bIsDisposed = true
  }
  
  /**
   Initialize any resources used by this object after this has registered with a manager.
   
   - Returns: false if this failed to initialize, else true
   */
  func onIdReady() -> Bool {
    return true
  }
  
  /**
   Dispose of any resources held by this object.
   */
  func dispose() {}
}
