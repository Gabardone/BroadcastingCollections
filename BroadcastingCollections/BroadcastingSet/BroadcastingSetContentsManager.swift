//
//  BroadcastingSetContentsManager.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


open class BroadcastingSetContentsManager<Element: Hashable>: BroadcastingCollectionContentsManager {

    //  MARK: - BroadcastingCollectionContentsManager Implementation

    public typealias ManagedCollectionTypes = SetTypesWrapper<Element>


    public weak var _managedContents: EditableBroadcastingSet<Element>?


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
    open func calculateContents() -> Set<Element> {
        //  Return an empty one by default.
        return Set<Element>()
    }


    deinit {
        //  Make sure we're not updating during deallocation.
        suspendUpdating(for: .deallocating)
    }
}
