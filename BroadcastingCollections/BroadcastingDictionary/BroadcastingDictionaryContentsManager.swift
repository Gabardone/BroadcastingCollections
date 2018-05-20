//
//  BroadcastingDictionaryContentsManager.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó on 5/19/18.
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


open class BroadcastingDictionaryContentsManager<Key: Hashable, Value: Equatable>: BroadcastingCollectionContentsManager {

    //  MARK: - BroadcastingCollectionContentsManager Implementation

    public typealias ManagedCollectionTypes = DictionaryTypesWrapper<Key, Value>


    public weak var _managedContents: EditableBroadcastingDictionary<Key, Value>?


    ///  Initialized suspended as no managed contents are set.
    public var suspensionReasons: CountedSet<BroadcastingCollectionContentsManagerSuspensionReason> = {
        var result = CountedSet<BroadcastingCollectionContentsManagerSuspensionReason>()
        result.insert(.nilManagedContents)
        return result
    }()


    /// Default behavior. Always call super unless some odd optimization is going on.
    open func startUpdating() {
        basicStartUpdating()
    }


    /// Default behavior. Always call super unless some odd optimization is going on.
    open func stopUpdating() {
        basicStopUpdating()
    }


    /**
     Default behavior returns an empty set. Override.
     */
    open func calculateContents() -> Dictionary<Key, Value> {
        //  Return an empty one by default.
        return [:]
    }


    deinit {
        //  Make sure we're not updating during deallocation.
        suspendUpdating(for: .deallocating)
    }
}
