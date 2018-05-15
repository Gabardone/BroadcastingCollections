//
//  CollectionChange.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/** Describes a change made in a collection.
 All changes are described in their most basic terms as insertions or removals. However associated change data can be
 included on a change set, allowing for the expression of more sophisticated semantics for those who would want to deal
 with those.

 Additional semantics depend on the type of collection the changes are describing and their validation is left to
 extension methods to be called by the developer. They all, however, presume removal before insertion semantics.

 - Todo: Support for coalescing/splitting a sequence of changesets.
 - Todo: Support for merge/split.
 */
public enum CollectionChange<ChangeDescription> {

    /** Describes an insertion change.

     - Parameter inserted: The description of the insertion change.
     - Parameter associatedRemoval: An associated description of a removal change for optional additional semantic
     information. The associated removal is expected to have happened before the insertion this change describes.
     */
    case insertion(ChangeDescription, associatedRemoval: ChangeDescription?)

    /** Describes a removal change.

     - Parameter removed: The description of the insertion change.
     - Parameter associatedRemoval: An associated description of an insertion change for optional additional semantic
     information. The associated insertion is expected to happen right after the removal this change describes.
     */
    case removal(ChangeDescription, associatedInsertion: ChangeDescription?)
}
