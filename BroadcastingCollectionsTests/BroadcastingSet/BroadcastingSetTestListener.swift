//
//  BroadcastingSetTestListener.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import Foundation



class BroadcastingSetTestListener: BroadcastingCollectionTestListener<SetTypesWrapper<BroadcastingCollectionTestContent>>, BroadcastingSetFullListener {

    typealias ListenedElement = BroadcastingCollectionTestContent


    //  We sort the elements before display to guarantee that they write down always in the same order.
    private func sort(_ elements: Set<BroadcastingCollectionTestContent>) -> [BroadcastingCollectionTestContent] {
        return elements.sorted(by: { (leftContent, rightContent) -> Bool in
            return leftContent.number < rightContent.number
        })
    }

    //  MARK: - BroadcastingSetListener Implementation.

    func broadcastingSetWillBeginTransactions(_ broadcastingSet: BroadcastingSet<BroadcastingCollectionTestContent>) {
        listenerLog += "Broadcasting set \(string(for: broadcastingSet)) WILL BEGIN TRANSACTIONS\n"
    }

    //  MARK: - BroadcastingSetFullListener Implementation.

    func broadcastingSetDidEndTransactions(_ broadcastingSet: BroadcastingSet<BroadcastingCollectionTestContent>) {
        listenerLog += "Broadcasting set \(string(for: broadcastingSet)) DID END TRANSACTIONS\n"
    }


    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<BroadcastingCollectionTestContent>, willAdd elements: Set<BroadcastingCollectionTestContent>) {
        listenerLog += "Broadcasting set \(string(for: broadcastingSet)) WILL ADD Elements:\n\(sort(elements))\n"
    }


    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<BroadcastingCollectionTestContent>, didAdd elements: Set<BroadcastingCollectionTestContent>) {
        listenerLog += "Broadcasting set \(string(for: broadcastingSet)) DID ADD Elements:\n\(sort(elements))\n"
    }


    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<BroadcastingCollectionTestContent>, willRemove elements: Set<BroadcastingCollectionTestContent>) {
        listenerLog += "Broadcasting set \(string(for: broadcastingSet)) WILL REMOVE Elements:\n\(sort(elements))\n"
    }


    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<BroadcastingCollectionTestContent>, didRemove elements: Set<BroadcastingCollectionTestContent>) {
        listenerLog += "Broadcasting set \(string(for: broadcastingSet)) DID REMOVE Elements:\n\(sort(elements))\n"
    }
}
