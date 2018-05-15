//
//  BroadcastingOrderedSetContentsManager.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


open class BroadcastingOrderedSetContentsManager<Element: Hashable & AnyObject>: BroadcastingCollectionContentsManager {

    //  MARK: - BroadcastingCollectionContentsManager Implementation

    public typealias ManagedCollectionTypes = OrderedSetTypesWrapper<Element>


    public weak var _managedContents: EditableBroadcastingOrderedSet<Element>? = nil


    //  Initialize suspended due to no managed contents being set.
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
    open func calculateContents() -> NSOrderedSet {
        //  Return an empty one by default.
        return NSOrderedSet()
    }


    deinit {
        //  Make sure we're not updating during deallocation.
        suspendUpdating(for: .deallocating)
    }


    public init() {
    }
}
