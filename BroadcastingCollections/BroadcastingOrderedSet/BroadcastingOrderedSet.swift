//
//  BroadcastingOrderedSet.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


public struct OrderedSetTypesWrapper<ElementType: Hashable & AnyObject>: CollectionTypesWrapper {

    public typealias Element = ElementType
    
    public typealias CollectionType = NSOrderedSet
    
    public typealias StorageType = NSMutableOrderedSet
    
    public typealias ChangeDescription = IndexedElements<Element>

    public typealias BroadcastingCollectionType = BroadcastingOrderedSet<Element>

    public typealias EditableBroadcastingCollectionType = EditableBroadcastingOrderedSet<Element>

    public typealias BroadcastingCollectionContentsManagerType = BroadcastingOrderedSetContentsManager<Element>

    public typealias ListenerWrapperType = AnyBroadcastingOrderedSetListener<Element>
}


/**
 The base class for broadcasting ordered sets.

 The class promises an full implementation of BroadcastingCollection for OrderedSet types. Both the contents and
 ongoingTransactions properties are left abstract for implementation by subclasses since depending on the use and need
 of the subclass they may maintain their own collection or only do so when needed.

 A set of APIs are offered for the basic ordered set operations we may need to use, to better avoid having to build up
 the whole set whenever that can be optimized away. Default implementations do so.

 Due to the lack of a native OrderedSet struct type in Swift, we are using NSOrderedSet for storage. That forces the
 contents to be compatible with objective-C collections as well as Hashable.
 */
public class BroadcastingOrderedSet<Element: Hashable & AnyObject>: BroadcastingCollection, BroadcastingSetRepresentable {

    //  MARK: OrderedSet API

    /**
     Returns an array façade for the contents. Beats typecasting if all we want to do is iterate over the elements.
     */
    public var array: [Element] {
        return contents.array as! [Element]
    }


    /**
     Returns a set façade for the contents.
     */
    public var set: Set<Element> {
        return contents.set as! Set<Element>
    }


    /**
     Individual element access.
     */
    public subscript(index: Int) -> Element {
        return contents[index] as! Element
    }

    //  MARK: BroadcastingCollection Implementation.

    public typealias BroadcastCollectionTypes = OrderedSetTypesWrapper<Element>


    /// Abstract default implementation blows up.
    public var contents: NSOrderedSet {
        preconditionFailure("Attempted to call abstract property \(#function)")
    }


    /**
     Adds a listener to our broadcasts.

     - Parameter listener: An object implementing BroadcastingSetListener for the same BroadcastingSet type as self. If
     the listener is already in the listener set the method does nothing.
     */
    public func add<ListenerType>(listener: ListenerType) where ListenerType.ListenedCollectionTypes == BroadcastCollectionTypes, ListenerType : BroadcastingOrderedSetListener {
        _listenerTable.setObject(AnyBroadcastingOrderedSetListener<Element>(listener), forKey: listener)
    }


    //  TODO: This shouldn't be needed, remove if possible as Swift compiler improves.
    /**
     Removes a listener from our broadcast list

     - Parameter listener: The listener to remove. If it's not present in the listener set the method does nothing.
     */
    public func remove<ListenerType>(listener: ListenerType) where ListenerType : BroadcastingCollectionListener, BroadcastingOrderedSet.BroadcastCollectionTypes == ListenerType.ListenedCollectionTypes {
        _listenerTable.removeObject(forKey: listener)
    }

    /// Seriously don't touch this guy.
    public var _listenerTable = NSMapTable<AnyObject, AnyBroadcastingOrderedSetListener<Element>>.weakToStrongObjects()

    //  MARK: TransactionSupport Implementation

    /// Abstract default implementation blows up.
    public var ongoingTransactions: CountedSet<TransactionInfo> {
        preconditionFailure("Attempted to call abstract property \(#function)")
    }

    //  MARK: BroadcastingSetRepresentable Implementation

    /// Creates one lazily.
    private(set) public lazy var broadcastingSetFaçade: BroadcastingSet<Element> = {
        return BroadcastingOrderedSetSetFaçade(for: self)
    }()
}
