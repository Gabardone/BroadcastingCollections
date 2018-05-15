//
//  BroadcastingCollectionListener.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/**
 A protocol for classes who subscribe to a BroadcastingCollection changes.

 The methods broadcast by a broadcast collection vary depending on the collection type so this protocol only declares
 the common types used.
 */
public protocol BroadcastingCollectionListener: class {

    /** The types of BroadcastingCollections that an implementer of this protocol can subscribe to.

    - Note: The CollectionTypesWrapper must match exactly. For cases where the types are compatible but not the same,
    use a façade republisher. */
    associatedtype ListenedCollectionTypes: CollectionTypesWrapper
}
