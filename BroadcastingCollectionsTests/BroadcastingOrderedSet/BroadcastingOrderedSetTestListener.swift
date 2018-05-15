//
//  BroadcastingOrderedSetTestListener.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import Foundation


class BroadcastingOrderedSetTestListener: BroadcastingCollectionTestListener<OrderedSetTypesWrapper<BroadcastingCollectionTestContent>>, BroadcastingOrderedSetFullListener {

    //  MARK: - BroadcastingOrderedSetListener Implementation.

    public func broadcastingOrderedSetWillBeginTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<BroadcastingCollectionTestContent>) {
        listenerLog += "Broadcasting ordered set \(string(for: broadcastingOrderedSet)) WILL BEGIN TRANSACTIONS\n"
    }


    public func broadcastingOrderedSetDidEndTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<BroadcastingCollectionTestContent>) {
        listenerLog += "Broadcasting ordered set \(string(for: broadcastingOrderedSet)) DID END TRANSACTIONS\n"
    }

    //  MARK: - BroadcastingOrderedSetFullListener Implementation.

    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<BroadcastingCollectionTestContent>, willInsert elementsAtIndexes: IndexedElements<BroadcastingCollectionTestContent>) {
        listenerLog += "Broadcasting ordered set \(string(for: broadcastingOrderedSet)) WILL INSERT Elements:\n\(elementsAtIndexes.elements)\nAt indexes: \(elementsAtIndexes.indexes.detailedDescription)" + "\n"
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<BroadcastingCollectionTestContent>, didInsert elementsAtIndexes: IndexedElements<BroadcastingCollectionTestContent>) {
        listenerLog += "Broadcasting ordered set \(string(for: broadcastingOrderedSet)) DID INSERT Elements:\n\(elementsAtIndexes.elements)\nAt indexes: \(elementsAtIndexes.indexes.detailedDescription)" + "\n"
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willRemove elementsFromIndexes: IndexedElements<ListenedElement>) {
        listenerLog += "Broadcasting ordered set \(string(for: broadcastingOrderedSet)) WILL REMOVE Elements:\n\(elementsFromIndexes.elements) from indexes: \(elementsFromIndexes.indexes.detailedDescription)\n"
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didRemove elementsFromIndexes: IndexedElements<ListenedElement>) {
        listenerLog += "Broadcasting ordered set \(string(for: broadcastingOrderedSet)) DID REMOVE Elements:\n\(elementsFromIndexes.elements) from indexes: \(elementsFromIndexes.indexes.detailedDescription)\n"
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<BroadcastingCollectionTestContent>, willMove element: BroadcastingCollectionTestContent, from fromIndex: Int, to toIndex: Int) {
        listenerLog += "Broadcasting ordered set \(string(for: broadcastingOrderedSet)) WILL MOVE Element \(element) from index: \(fromIndex) to: \(toIndex)\n"
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<BroadcastingCollectionTestContent>, didMove element: BroadcastingCollectionTestContent, from fromIndex: Int, to toIndex: Int) {
        listenerLog += "Broadcasting ordered set \(string(for: broadcastingOrderedSet)) DID MOVE Element \(element) from index: \(fromIndex) to: \(toIndex)\n"
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<BroadcastingCollectionTestContent>, willReplace replacees: IndexedElements<BroadcastingCollectionTestContent>, with replacements: IndexedElements<BroadcastingCollectionTestContent>) {
        listenerLog += "Broadcasting ordered set \(string(for: broadcastingOrderedSet)) WILL REPLACE Elements \(replacees.elements) at indexes: \(replacees.indexes.detailedDescription)\nWith Elements:\n\(replacements.elements) at indexes: \(replacements.indexes.detailedDescription)\n"
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<BroadcastingCollectionTestContent>, didReplace replacees: IndexedElements<BroadcastingCollectionTestContent>, with replacements: IndexedElements<BroadcastingCollectionTestContent>) {
        listenerLog += "Broadcasting ordered set \(string(for: broadcastingOrderedSet)) DID REPLACE Elements \(replacees.elements) at indexes: \(replacees.indexes.detailedDescription)\nWith Elements:\n\(replacements.elements) at indexes: \(replacements.indexes.detailedDescription)\n"
    }
}
