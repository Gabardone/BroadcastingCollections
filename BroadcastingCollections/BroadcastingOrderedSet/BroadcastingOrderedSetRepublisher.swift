//
//  BroadcastingOrderedSetRepublisher.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/**
 Lightweight superclass for broadcasting ordered set objects that republish another one they subscribe to.

 The main reason to use these is to guarantee ordering in listener execution. The order in which listeners have
 changes broadcast is undefined, by using a republisher we can guarantee that whatever additional processing the
 republisher needs to make happen will do so before and after its own listeners get changes broadcast as needed.

 Allows for a different broadcast and listened type, which allows for a contravariant republisher (the republished
 values being a superclass of the listened ones).
 */
public class BroadcastingOrderedSetRepublisher<Element: Hashable & AnyObject, ListenedElementType: Hashable & AnyObject>: BroadcastingOrderedSet<Element>, BroadcastingOrderedSetListener {

    override public init() {
    }


    public var republishedBroadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>? {
        willSet {
            if republishedBroadcastingOrderedSet !== newValue, let oldValue = republishedBroadcastingOrderedSet {
                oldValue.remove(listener: self)
            }
        }

        didSet {
            if republishedBroadcastingOrderedSet !== oldValue, let newValue = republishedBroadcastingOrderedSet {
                newValue.add(listener: self)
            }
        }
    }

    //  - MARK: BroadcastingOrderedSet Overrides

    override public var contents: NSOrderedSet {
        return republishedBroadcastingOrderedSet?.contents ?? NSOrderedSet()
    }


    //  - MARK: TransactionSupport Overrides

    override public var ongoingTransactions: CountedSet<TransactionInfo> {
        return republishedBroadcastingOrderedSet?.ongoingTransactions ?? CountedSet<TransactionInfo>()
    }

    //  - MARK: BroadcastingOrderedSetListener Implementation

    public typealias ListenedElement = ListenedElementType


    public typealias ListenedCollectionTypes = OrderedSetTypesWrapper<ListenedElement>


    public func broadcastingOrderedSetWillBeginTransactions(_ broadcastingSet: BroadcastingOrderedSet<ListenedElement>) {
        guard broadcastingSet === republishedBroadcastingOrderedSet else {
            //  Not complaining in case we want to subclass into listening more than republishedBroadcastingOrderedSet.
            return
        }

        //  Re-broadcast.
        makeListeners { (listener) in
            listener.broadcastingOrderedSetWillBeginTransactions(self)
        }
    }


    public func broadcastingOrderedSetDidEndTransactions(_ broadcastingSet: BroadcastingOrderedSet<ListenedElement>) {
        guard broadcastingSet === republishedBroadcastingOrderedSet else {
            //  Not complaining in case we want to subclass into listening more than republishedBroadcastingOrderedSet.
            return
        }

        //  Re-broadcast.
        makeListeners { (listener) in
            listener.broadcastingOrderedSetDidEndTransactions(self)
        }
    }


    private func _broadcastChange(for listenedChange: IndexedCollectionChange<ListenedElement>) -> IndexedCollectionChange<Element> {
        switch listenedChange {
        case .insertion(let inserted, associatedRemoval: let associatedRemoval):
            return IndexedCollectionChange<Element>.insertion(IndexedElements(indexes: inserted.indexes, elements: inserted.elements as! [Element]),
                                                              associatedRemoval: associatedRemoval != nil ? IndexedElements(indexes: associatedRemoval!.indexes, elements: associatedRemoval!.elements as! [Element]) : nil)
        case .removal(let removed, associatedInsertion: let associatedInsertion):
            return IndexedCollectionChange<Element>.removal(IndexedElements(indexes: removed.indexes, elements: removed.elements as! [Element]),
                                                            associatedInsertion: associatedInsertion != nil ? IndexedElements(indexes: associatedInsertion!.indexes, elements: associatedInsertion!.elements as! [Element]) : nil)
        }
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willApply change: IndexedCollectionChange<ListenedElement>) {
        guard broadcastingOrderedSet === republishedBroadcastingOrderedSet else {
            //  Not complaining in case we want to subclass into listening more than republishedBroadcastingOrderedSet.
            return
        }

        let republishedChange = _broadcastChange(for: change)
        makeListeners { (listener: AnyBroadcastingOrderedSetListener<Element>) in
            listener.broadcastingOrderedSet(self, willApply: republishedChange)
        }
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didApply change: IndexedCollectionChange<ListenedElement>) {
        guard broadcastingOrderedSet === republishedBroadcastingOrderedSet else {
            //  Not complaining in case we want to subclass into listening more than republishedBroadcastingOrderedSet.
            return
        }

        let republishedChange = _broadcastChange(for: change)
        makeListeners { (listener: AnyBroadcastingOrderedSetListener<Element>) in
            listener.broadcastingOrderedSet(self, didApply: republishedChange)
        }
    }
}
