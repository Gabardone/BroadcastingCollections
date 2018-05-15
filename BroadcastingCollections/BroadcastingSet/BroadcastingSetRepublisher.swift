//
//  BroadcastingSetRepublisher.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/**
 Lightweight superclass for broadcasting set objects that republish another one they subscribe to.

 The main reason to use these is to guarantee ordering in listener execution. The order in which listeners have
 changes broadcast is undefined, by using a republisher we can guarantee that whatever additional processing the
 republisher needs to make happen will do so before and after its own listeners get changes broadcast as needed.

 Allows for a different broadcast and listened type, which allows for a contravariant republisher (the republished
 values being a superclass of the listened ones).
 */
public class BroadcastingSetRepublisher<Element: Hashable, ListenedElementType: Hashable>: BroadcastingSet<Element>, BroadcastingSetListener {

    override public init() {
    }


    public var republishedBroadcastingSet: BroadcastingSet<ListenedElement>? {
        willSet {
            if republishedBroadcastingSet !== newValue, let oldValue = republishedBroadcastingSet {
                oldValue.remove(listener: self)
            }
        }

        didSet {
            if republishedBroadcastingSet !== oldValue, let newValue = republishedBroadcastingSet {
                newValue.add(listener: self)
            }
        }
    }

    //  - MARK: BroadcastingSet Overrides

    override public var contents: Set<Element> {
        return republishedBroadcastingSet?.contents as? Set<Element> ?? Set()
    }


    //  - MARK: TransactionSupport Overrides

    override public var ongoingTransactions: CountedSet<TransactionInfo> {
        return republishedBroadcastingSet?.ongoingTransactions ?? CountedSet<TransactionInfo>()
    }

    //  - MARK: BroadcastingSetListener Implementation

    public typealias ListenedElement = ListenedElementType


    public typealias ListenedCollectionTypes = SetTypesWrapper<ListenedElement>


    public func broadcastingSetWillBeginTransactions(_ broadcastingSet: BroadcastingSet<ListenedElement>) {
        guard broadcastingSet === republishedBroadcastingSet else {
            //  Not complaining in case we want to subclass into listening more than republishedBroadcastingSet.
            return
        }

        //  Re-broadcast.
        makeListeners { (listener) in
            listener.broadcastingSetWillBeginTransactions(self)
        }
    }


    public func broadcastingSetDidEndTransactions(_ broadcastingSet: BroadcastingSet<ListenedElement>) {
        guard broadcastingSet === republishedBroadcastingSet else {
            //  Not complaining in case we want to subclass into listening more than republishedBroadcastingSet.
            return
        }

        //  Re-broadcast.
        makeListeners { (listener) in
            listener.broadcastingSetDidEndTransactions(self)
        }
    }


    private func _broadcastChange(for listenedChange: SetChange<ListenedElement>) -> SetChange<Element> {
        switch listenedChange {
        case .insertion(let inserted, associatedRemoval: let associatedRemoval):
            return SetChange.insertion(inserted as! Set<Element>, associatedRemoval: associatedRemoval as! Set<Element>?)
        case .removal(let removed, associatedInsertion: let associatedInsertion):
            return SetChange.removal(removed as! Set<Element>, associatedInsertion: associatedInsertion as! Set<Element>?)
        }
    }


    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, willApply change: SetChange<ListenedElement>) {
        guard broadcastingSet === republishedBroadcastingSet else {
            //  Not complaining in case we want to subclass into listening more than republishedBroadcastingSet.
            return
        }

        let republishedChange = _broadcastChange(for: change)
        makeListeners { (listener: AnyBroadcastingSetListener<Element>) in
            listener.broadcastingSet(self, willApply: republishedChange)
        }
    }


    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, didApply change: SetChange<ListenedElement>) {
        guard broadcastingSet === republishedBroadcastingSet else {
            //  Not complaining in case we want to subclass into listening more than republishedBroadcastingSet.
            return
        }

        let republishedChange = _broadcastChange(for: change)
        makeListeners { (listener: AnyBroadcastingSetListener<Element>) in
            listener.broadcastingSet(self, didApply: republishedChange)
        }
    }
}
