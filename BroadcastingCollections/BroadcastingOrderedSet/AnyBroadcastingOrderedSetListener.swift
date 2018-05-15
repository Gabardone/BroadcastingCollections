//
//  AnyBroadcastingOrderedSetListener.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


///  type erasing wrapper over BroadcastingOrderedSetListener. Needs to be a class as we'll be storing them in a NSMapTable.
public final class AnyBroadcastingOrderedSetListener<Element: Hashable & AnyObject>: BroadcastingOrderedSetListener {

    public typealias ListenedCollectionTypes = OrderedSetTypesWrapper<Element>

    public typealias ElementType = Element


    public init<Listener>(_ listener: Listener) where Listener : BroadcastingOrderedSetListener, OrderedSetTypesWrapper<Element> == Listener.ListenedCollectionTypes {
        //  Set up all the redirection callbacks. All unowned as we'll manage references externally.
        _broadcastingOrderedSetWillBeginTransactions = { [unowned listener] (broadcastingOrderedSet) in listener.broadcastingOrderedSetWillBeginTransactions(broadcastingOrderedSet) }
        _broadcastingOrderedSetDidEndTransactions = { [unowned listener] (broadcastingOrderedSet) in listener.broadcastingOrderedSetDidEndTransactions(broadcastingOrderedSet) }
        _broadcastingOrderedSetWillApplyChange = { [unowned listener] (broadcastingOrderedSet, change) in listener.broadcastingOrderedSet(broadcastingOrderedSet, willApply: change) }
        _broadcastingOrderedSetDidApplyChange = { [unowned listener] (broadcastingOrderedSet, change) in listener.broadcastingOrderedSet(broadcastingOrderedSet, didApply: change) }
    }


    private let _broadcastingOrderedSetWillBeginTransactions: (BroadcastingOrderedSet<Element>) -> Void

    public func broadcastingOrderedSetWillBeginTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>) {
        _broadcastingOrderedSetWillBeginTransactions(broadcastingOrderedSet)
    }


    private let _broadcastingOrderedSetDidEndTransactions: (BroadcastingOrderedSet<Element>) -> Void

    public func broadcastingOrderedSetDidEndTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>) {
        _broadcastingOrderedSetDidEndTransactions(broadcastingOrderedSet)
    }


    private let _broadcastingOrderedSetWillApplyChange: (BroadcastingOrderedSet<Element>, IndexedCollectionChange<Element>) -> Void

    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willApply change: IndexedCollectionChange<Element>) {
        _broadcastingOrderedSetWillApplyChange(broadcastingOrderedSet, change)
    }


    private let _broadcastingOrderedSetDidApplyChange: (BroadcastingOrderedSet<Element>, IndexedCollectionChange<Element>) -> Void

    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didApply change: IndexedCollectionChange<Element>) {
        _broadcastingOrderedSetDidApplyChange(broadcastingOrderedSet, change)
    }
}
