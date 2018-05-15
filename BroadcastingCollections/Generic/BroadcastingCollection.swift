//
//  BroadcastingCollection.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation

/**
 A base protocol for objects that own a collection and broadcast the changes being made to it.

 Works in tandem with the BroadcastingCollectionListener protocol, implemented by those wanting to subscribe to the
 collection's changes.

 These are almost always expected to be used by reference so it is declared as a class protocol.
 */
public protocol BroadcastingCollection: TransactionSupport {

    /// A wrapper for the types that are being broadcast, both collection type, element type within and other auxiliary types.
    associatedtype BroadcastCollectionTypes: CollectionTypesWrapper

    /**
     Typealias to the listener type eraser used to store listeners.

     Makes the API harder to declare and less likely to confuse the Swift type system.
     */
    typealias ListenerWrapper = BroadcastCollectionTypes.ListenerWrapperType


    /**
     The actual contents of the broadcasting collection. Many broadcasting collection types will only create this
     lazily so use only when you need to iterate or otherwise access the whole collection.
     */
    var contents: BroadcastCollectionTypes.CollectionType { get }

    /// Returns true if any listeners are registered. Useful to avoid extra work when no listeners are registered.
    var hasListeners: Bool { get }


    /**
     An array of all the listeners currently registered (in wrapper form). Use only when you need to iterate through
     all of them as they'll usually be created lazily.
     */
    var listeners: [ListenerWrapper] { get }

    
    /// Utility method to broadcast to the listeners.
    func makeListeners(perform: (ListenerWrapper) -> Void)


    /**
     Removes the given listener to the list of registered listeners of the calling broadcast collection.

     Listeners are held weakly, so it is not necessary to call this if the listener is going away on its own.

     - Note: The add method is not declared in the protocol as it requires different parameters depending on the
     broadcasting collection that can't be modeled with the current Swift language support.
     - Parameter listener: The listener to remove.
     */
    func remove<ListenerType>(listener: ListenerType) where ListenerType: BroadcastingCollectionListener, ListenerType.ListenedCollectionTypes == BroadcastCollectionTypes


    /// The actual storage of the listeners, exposed because Swift is weird like that.
    var _listenerTable: NSMapTable<AnyObject, ListenerWrapper> { get }
}


/// Default behaviors.
extension BroadcastingCollection  {

    public var hasListeners: Bool {
        return _listenerTable.count > 0
    }

    public var listeners: [ListenerWrapper] {
        //  Would be nice to have a more efficient way to do this.
        return _listenerTable.objectEnumerator()!.allObjects as! [ListenerWrapper]
    }

    public func makeListeners(perform: (ListenerWrapper) -> Void) {
        for listener in listeners {
            perform(listener)
        }
    }

    public func remove<ListenerType>(listener: ListenerType) where ListenerType: BroadcastingCollectionListener, ListenerType.ListenedCollectionTypes == BroadcastCollectionTypes {
        _listenerTable.removeObject(forKey: listener)
    }
}
