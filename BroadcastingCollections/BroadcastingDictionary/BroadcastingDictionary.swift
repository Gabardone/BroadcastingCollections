//
//  BroadcastingDictionary.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


public struct DictionaryTypesWrapper<Key: Hashable, Value: Equatable>: CollectionTypesWrapper {

    public typealias ElementType = (Key, Value)

    public typealias CollectionType = Dictionary<Key, Value>

    public typealias StorageType = Dictionary<Key, Value>

    public typealias ChangeDescription = Dictionary<Key, Value>

    public typealias BroadcastingCollectionType = BroadcastingDictionary<Key, Value>

    public typealias EditableBroadcastingCollectionType = EditableBroadcastingDictionary<Key, Value>

    public typealias BroadcastingCollectionContentsManagerType = BroadcastingDictionaryContentsManager<Key, Value>

    public typealias ListenerWrapperType = AnyBroadcastingDictionaryListener<Key, Value>
}


public class BroadcastingDictionary<Key: Hashable, Value: Equatable>: BroadcastingCollection {

    //  MARK: BroadcastingCollection Implementation

    public typealias BroadcastCollectionTypes = DictionaryTypesWrapper<Key, Value>

    public var contents: Dictionary<Key, Value> {
        preconditionFailure("Attempted to call abstract property \(#function)")
    }

    public func add<ListenerType>(listener: ListenerType) where ListenerType : BroadcastingDictionaryListener, BroadcastCollectionTypes == DictionaryTypesWrapper<Key, Value>, ListenerType.ListenedKeyType == Key, ListenerType.ListenedValueType == Value {
        _listenerTable.setObject(AnyBroadcastingDictionaryListener<Key, Value>(listener), forKey: listener)
    }


    public func remove<ListenerType>(listener: ListenerType) where ListenerType : BroadcastingCollectionListener, BroadcastingDictionary.BroadcastCollectionTypes == ListenerType.ListenedCollectionTypes {
        _listenerTable.removeObject(forKey: listener)
    }

    /// Seriously don't touch this guy.
    public var _listenerTable = NSMapTable<AnyObject, AnyBroadcastingDictionaryListener<Key, Value>>.weakToStrongObjects()

    //  MARK: TransactionSupport Implementation

    //  MARK: TransactionSupport Implementation

    /// Abstract default implementation returns an empty counted set.
    public var ongoingTransactions: CountedSet<TransactionInfo> {
        return CountedSet()
    }
}
