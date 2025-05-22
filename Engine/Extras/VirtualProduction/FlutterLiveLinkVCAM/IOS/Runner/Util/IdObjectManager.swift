// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation

// MARK: BaseIdObjectManager
/// Generic protoccol for IdObjectManager, allowing the class to be referred to generically.
protocol BaseIdObjectManager {
  associatedtype IdObjectType
  
  /**
   Start tracking a new object instance.
   
   - Parameter newObject: The object to start tracking.
   - Returns: The object's ID for future lookup in this manager.
   */
  func register(newObject: IdObjectType) -> Int64
  
  /**
   Dispose of an object instance created in this manager.
   
   - Parameter id: The ID of the object.
   - Returns: The object that was disposed, if any.
   */
  func unregister(id: Int64) -> IdObjectType?
  
  /**
   Dispose of all object instances in this manager.
   */
  func disposeAll()
  
  /**
   Get an object managed by this manager.
   
   - Parameter id: The index of the object.
   - Returns: The object with that ID, if any.
   */
  func get(id: Int64) -> IdObjectType?
  
  /**
   Get an object managed by this manager and throw an exception if it doesn't exist.
   
   - Parameter id: The index of the object.
   - Returns: The object with that ID, if any.
   */
  func getChecked(id: Int64) -> IdObjectType
}

// MARK: IdObjectManager
/// Maintains a map of IDs to a corresponding IdObject, enabling lookup by their IDs.
class IdObjectManager<T: IdObject> {
  /// Name to display in debug messages.
  private let debugTypeName: String
  
  /// Map from index to a managed object.
  private var objectMap: Dictionary<Int64, T> = [:]
  
  /// The next index to use for the next created object.
  private var nextIndex: Int64 = 0
  
  init(debugTypeName: String) {
    self.debugTypeName = debugTypeName
  }
}

// MARK: BaseIdObjectManager Impl
extension IdObjectManager: BaseIdObjectManager {
  @discardableResult
  func register(newObject: T) -> Int64 {
    if (!newObject.onRegistered(id: nextIndex, manager: self)) {
      return IdObject.invalidId
    }
    
    objectMap[nextIndex] = newObject
    
    nextIndex += 1
    return nextIndex - 1
  }
  
  @discardableResult
  func unregister(id: Int64) -> T? {
    let removed = objectMap.removeValue(forKey: id)
    removed?.onUnregistered()
    
    return removed
  }
  
  func disposeAll() {
    while (!objectMap.isEmpty) {
      objectMap.values.first?.onUnregistered()
    }
  }
  
  func get(id: Int64) -> T? {
    return objectMap[id]
  }
  
  func getChecked(id: Int64) -> T {
    let foundObject = get(id: id)
    
    assert(foundObject != nil, "No \(debugTypeName) with ID \(id)")
    
    return foundObject!
  }
}
