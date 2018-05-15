//
//  IndexedCollectionChange.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/// Basic protocol to allow for extending functionality for indexed collection changes.
public protocol IndexedElementsProtocol {
    associatedtype ElementType

    var indexes: IndexSet { get set }

    //  TODO: Use collection type too, once OrderedSet is a thing (makes far easier to verify correctness of OrderedSet changes).
    var elements: [ElementType] { get set }


    init(indexes: IndexSet, elements: [ElementType])
}


/// Actual implementation of IndexedElements
public struct IndexedElements<Element>: IndexedElementsProtocol {

    public var indexes: IndexSet

    public var elements: [Element]

    public init(indexes: IndexSet, elements: [Element]) {
        self.indexes = indexes
        self.elements = elements
    }

}


/// Use this typealias for simpler declaration of indexed collection change types.
public typealias IndexedCollectionChange<Element> = CollectionChange<IndexedElements<Element>>


//  These should be an extension of IndexedCollectionChange but extensions for partially resolved template types are
//  apparently not a thing as of Swift 4.1
extension CollectionChange where ChangeDescription: IndexedElementsProtocol, ChangeDescription.ElementType: Equatable {

    /** Returns the from and to indexes for a single element move as a tuple if this change set is for a single element
     move, nil otherwise.
     */
    var singleMoveIndexes: (from: Int, to: Int)? {
        switch self {
        case .insertion(let insertion, let associatedRemoval):
            if let removal = associatedRemoval, insertion.elements.count == 1 {
                if insertion.indexes != removal.indexes && insertion.elements == removal.elements {
                    return (removal.indexes[removal.indexes.startIndex], insertion.indexes[insertion.indexes.startIndex])
                }
            }

        case .removal(let removal, let associatedInsertion):
            if let insertion = associatedInsertion, removal.elements.count == 1 {
                if insertion.indexes != removal.indexes && insertion.elements == removal.elements {
                    return (removal.indexes[removal.indexes.startIndex], insertion.indexes[insertion.indexes.startIndex])
                }
            }
            break
        }
        return nil
    }


    /// Returns true if this changeset describes a single element move (either at the beginning or end).
    var isMove: Bool {
        switch self {
        case .insertion(let insertion, let associatedRemoval):
            if let removal = associatedRemoval {
                //  We only support single element moves otherwise we'd need to compare the sets of elements rather than the arrays.
                //  TODO: Compare sets of elements rather than the element arrays themselves?
                return insertion.indexes != removal.indexes && insertion.elements == removal.elements
            }

        case .removal(let removal, let associatedInsertion):
            if let insertion = associatedInsertion {
                //  We only support single element moves otherwise we'd need to compare the sets of elements rather than the arrays.
                //  TODO: Compare sets of elements rather than the element arrays themselves?
                return insertion.indexes != removal.indexes && insertion.elements == removal.elements
            }
        }

        //  Fallthrough means we ain't a move.
        return false
    }


    /** Returns true if this changeset describes the replacement of a number of elements in the collection with the
     same number of elements at the same indexes.
     */
    var isReplacement: Bool {
        switch self {
        case .insertion(let insertion, let associatedRemoval):
            if let removal = associatedRemoval {
                //  TODO: Test that none of the elements in insertion.elements are in removed.elements
                return insertion.indexes == removal.indexes && insertion.elements != removal.elements
            }

        case .removal(let removal, let associatedInsertion):
            if let insertion = associatedInsertion {
                //  TODO: Test that none of the elements in insertion.elements are in removed.elements
                return removal.indexes == insertion.indexes && removal.elements != insertion.elements
            }
        }

        //  Fallthrough means we ain't a replacement.
        return false
    }
}
