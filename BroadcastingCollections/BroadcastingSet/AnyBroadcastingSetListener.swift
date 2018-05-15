//
//  AnyBroadcastingSetListener.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


///  type erasing wrapper over BroadcastingDictionaryListener. Needs to be a class as we'll be storing them in a NSMapTable.
public final class AnyBroadcastingSetListener<Element: Hashable>: BroadcastingSetListener {

    public typealias ListenedCollectionTypes = SetTypesWrapper<Element>

    public typealias ListenedElement = Element


    public init<Listener>(_ listener: Listener) where Listener : BroadcastingSetListener, SetTypesWrapper<Element> == Listener.ListenedCollectionTypes {
        //  Set up all the redirection callbacks. All unowned as we'll manage references externally.
        _broadcastingSetWillBeginTransactions = { [unowned listener] (broadcastingSet) in listener.broadcastingSetWillBeginTransactions(broadcastingSet) }
        _broadcastingSetDidEndTransactions = { [unowned listener] (broadcastingSet) in listener.broadcastingSetDidEndTransactions(broadcastingSet) }
        _broadcastingSetWillApplyChange = { [unowned listener] (broadcastingSet, change) in listener.broadcastingSet(broadcastingSet, willApply: change) }
        _broadcastingSetDidApplyChange = { [unowned listener] (broadcastingSet, change) in listener.broadcastingSet(broadcastingSet, didApply: change) }
    }


    private let _broadcastingSetWillBeginTransactions: (BroadcastingSet<Element>) -> Void

    public func broadcastingSetWillBeginTransactions(_ broadcastingSet: BroadcastingSet<Element>) {
        _broadcastingSetWillBeginTransactions(broadcastingSet)
    }


    private let _broadcastingSetDidEndTransactions: (BroadcastingSet<Element>) -> Void

    public func broadcastingSetDidEndTransactions(_ broadcastingSet: BroadcastingSet<Element>) {
        _broadcastingSetDidEndTransactions(broadcastingSet)
    }


    private let _broadcastingSetWillApplyChange: (BroadcastingSet<Element>, SetChange<Element>) -> Void

    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<Element>, willApply change: SetChange<Element>) {
        _broadcastingSetWillApplyChange(broadcastingSet, change)
    }


    private let _broadcastingSetDidApplyChange: (BroadcastingSet<Element>, SetChange<Element>) -> Void

    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<Element>, didApply change: SetChange<Element>) {
        _broadcastingSetDidApplyChange(broadcastingSet, change)
    }
}
