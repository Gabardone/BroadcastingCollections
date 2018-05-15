//
//  BroadcastingSet.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


public struct SetTypesWrapper<Element: Hashable>: CollectionTypesWrapper {

    public typealias ElementType = Element
    
    public typealias CollectionType = Set<Element>
    
    public typealias StorageType = Set<Element>
    
    public typealias ChangeDescription = Set<Element>

    public typealias BroadcastingCollectionType = BroadcastingSet<Element>

    public typealias EditableBroadcastingCollectionType = EditableBroadcastingSet<Element>

    public typealias BroadcastingCollectionContentsManagerType = BroadcastingSetContentsManager<Element>

    public typealias ListenerWrapperType = AnyBroadcastingSetListener<Element>
}


public protocol BroadcastingSetRepresentable {

    associatedtype BroadcastElementType: Hashable

    var broadcastingSetFaçade: BroadcastingSet<BroadcastElementType> { get }
}


/**
 The base class for broadcasting sets.

 The class promises an full implementation of BroadcastingCollection for Set types. Both the contents and
 ongoingTransactions properties are left abstract for implementation by subclasses since depending on the use and need
 of the subclass they may maintain their own collection or only do so when needed.

 A set of APIs are offered for the basic set operations we may need to use, to better avoid having to build up the
 whole set whenever that can be optimized away. Default implementations do so.
 */
open class BroadcastingSet<Element: Hashable>: BroadcastingCollection, BroadcastingSetRepresentable {

    //  MARK: - Set API

    /**
     Calculates whether the caller's contents contain the given element.

     - Parameter element: The elemet we want to know whether it's contained in contents.
     - Returns: True if the element is one within contents.
     */
    open func contains(element: Element) -> Bool {
        return contents.contains(element)
    }

    //  MARK: - BroadcastingCollection Implementation.

    public typealias BroadcastCollectionTypes = SetTypesWrapper<Element>


    /// Abstract default implementation blows up.
    public var contents: Set<Element> {
        preconditionFailure("Attempted to call abstract property \(#function)")
    }


    /**
     Adds a listener to our broadcasts.

     - Parameter listener: An object implementing BroadcastingSetListener for the same BroadcastingSet type as self.
     */
    public func add<ListenerType>(listener: ListenerType) where ListenerType.ListenedCollectionTypes == BroadcastCollectionTypes, ListenerType : BroadcastingSetListener {
        _listenerTable.setObject(AnyBroadcastingSetListener<Element>(listener), forKey: listener)
    }


    //  TODO: This shouldn't be needed, remove if possible as Swift compiler updates.
    public func remove<ListenerType>(listener: ListenerType) where ListenerType : BroadcastingCollectionListener, BroadcastingSet.BroadcastCollectionTypes == ListenerType.ListenedCollectionTypes {
        _listenerTable.removeObject(forKey: listener)
    }

    /// Seriously don't touch this guy.
    public var _listenerTable = NSMapTable<AnyObject, AnyBroadcastingSetListener<Element>>.weakToStrongObjects()

    //  MARK: TransactionSupport Implementation

    /// Abstract default implementation blows up.
    public var ongoingTransactions: CountedSet<TransactionInfo> {
        preconditionFailure("Attempted to call abstract property \(#function)")
    }

    //  MARK: BroadcastingSetRepresentable Implementation

    final public var broadcastingSetFaçade: BroadcastingSet<Element> {
        //  We're good.
        return self
    }
}

//  MARK: - Hashable Implementation

/**
 BroadcastingSet implements hashable mostly so we can use them as sources for MultiBroadcastingSetSourcedContentsManager.
 */
extension BroadcastingSet: Hashable {
    public var hashValue: Int {
        //  Hash on the identity.
        return ObjectIdentifier(self).hashValue
    }


    public static func == (lhs: BroadcastingSet<Element>, rhs: BroadcastingSet<Element>) -> Bool {
        //  We can go by identity.
        return lhs === rhs
    }
}
