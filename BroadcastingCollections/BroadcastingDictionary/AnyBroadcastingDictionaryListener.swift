//
//  AnyBroadcastingDictionaryListener.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation

///  type erasing wrapper over BroadcastingDictionaryListener. Needs to be a class as they'll be stored in a NSMapTable.
public final class AnyBroadcastingDictionaryListener<Key: Hashable, Value: Equatable>: BroadcastingDictionaryListener {

    public typealias KeyType = Key

    public typealias ValueType = Value


    public required init<Listener: BroadcastingDictionaryListener>(_ listener: Listener) where Listener.ListenedKeyType == Key, Listener.ListenedValueType == Value {
        //  Set up all the redirection callbacks. All unowned as we'll manage references externally.
        _broadcastingDictionaryWillBeginTransactions = { [unowned listener] (broadcastingDictionary) in listener.broadcastingDictionaryWillBeginTransactions(broadcastingDictionary) }
        _broadcastingDictionaryDidEndTransactions = { [unowned listener] (broadcastingDictionary) in listener.broadcastingDictionaryDidEndTransactions(broadcastingDictionary) }
        _broadcastingDictionaryWillApplyChange = { [unowned listener] (broadcastingDictionary, change) in listener.broadcastingDictionary(broadcastingDictionary, willApply: change) }
        _broadcastingDictionaryDidApplyChange = { [unowned listener] (broadcastingDictionary, change) in listener.broadcastingDictionary(broadcastingDictionary, didApply: change) }
    }


    private let _broadcastingDictionaryWillBeginTransactions: (BroadcastingDictionary<Key, Value>) -> Void

    public func broadcastingDictionaryWillBeginTransactions(_ broadcaster: BroadcastingDictionary<Key, Value>) {
        _broadcastingDictionaryWillBeginTransactions(broadcaster)
    }


    private let _broadcastingDictionaryDidEndTransactions: (BroadcastingDictionary<Key, Value>) -> Void

    public func broadcastingDictionaryDidEndTransactions(_ broadcaster: BroadcastingDictionary<Key, Value>) {
        _broadcastingDictionaryDidEndTransactions(broadcaster)
    }


    private let _broadcastingDictionaryWillApplyChange: (BroadcastingDictionary<Key, Value>, DictionaryChange<Key, Value>) -> Void

    public func broadcastingDictionary(_ broadcastingDictionary: BroadcastingDictionary<Key, Value>, willApply change: DictionaryChange<Key, Value>) {
        _broadcastingDictionaryWillApplyChange(broadcastingDictionary, change)
    }


    private let _broadcastingDictionaryDidApplyChange: (BroadcastingDictionary<Key, Value>, DictionaryChange<Key, Value>) -> Void

    public func broadcastingDictionary(_ broadcastingDictionary: BroadcastingDictionary<Key, Value>, didApply change: DictionaryChange<Key, Value>) {
        _broadcastingDictionaryDidApplyChange(broadcastingDictionary, change)
    }
}
