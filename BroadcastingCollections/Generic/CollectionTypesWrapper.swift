//
//  CollectionTypesWrapper.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/** Use types implementing this protocol as wrappers for all the types needed to configure a BroadcastingCollection and
 its associated listeners.
 */
//  This is a bit of a hack to avoid having to pass 3 or 4 template parameters everywhere all the time, until
//  such a time as OrderedSet is a thing (at that point we can just set all of our classes with a swift library
//  collection type and extract most of the remaining needed types from it).
//  TODO: Streamline as soon as OrderedSet gets added to the swift library.
public protocol CollectionTypesWrapper {
    
    /**
     The type of element stored by the collection in a BroadcastingCollection.
     - Todo: This is only needed due to type-less NSOrderedSet. Remove as soon as Swift's OrderedSet is ready.
     */
    associatedtype ElementType

    /// The type of collection exposed by a BroadcastingCollection.
    associatedtype CollectionType: Sequence

    /**
     The type used for storage purposes on BroadcastingCollections.
     - Todo: Remove as soon as there's a Swift OrderedSet type.
     */
    associatedtype StorageType: Sequence

    /// The type used to broadcast changes to the exposed CollectionType
    associatedtype ChangeDescription

    /// Base type for broadcasting collections that use this type wrapper.
    associatedtype BroadcastingCollectionType: BroadcastingCollection

    /// Type used as a barebones, editable broadcasting collection. We need to refer to it directly on occasion.
    associatedtype EditableBroadcastingCollectionType: EditableBroadcastingCollection

    /// Type used as contents manager for editable broadcasting collections.
    associatedtype BroadcastingCollectionContentsManagerType: BroadcastingCollectionContentsManager

    /**
     Type used as a type-erasing wrapper for the collection's listeners.

     Currently requiring it's a class type as we store them in a NSMapTable.
     */
    associatedtype ListenerWrapperType: AnyObject
}
