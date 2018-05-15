//
//  CountedSet.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/**
 Small CountedSet struct.

 Contains the bare minimum API we need for BroadcastingCollection purposes.
 */
public struct CountedSet<ElementType: Hashable> {

    typealias Element = ElementType

    private var storage: [Element: Int] = [:]


    /**
     Returns an element.
     */
    var any: Element? {
        return storage.keys.first
    }


    /**
     True if the counted set contains anything at all.
     */
    var isEmpty: Bool {
        return storage.isEmpty
    }


    /**
     Returns whether the counted set contains the given element.
     - Parameter member: Member to check
     - Returns: true if the element is contained in the counted set (count > 0), false otherwise.
     */
    func contains(_ member: Element) -> Bool {
        return storage[member] != nil
    }


    /**
     Increases the count for a given element in the counted set. Will insert if the count was 0.
     - Parameter newMember: The element to insert in the counted set.
     - Returns: The count of the given element in the counted set after insertion.
     */
    @discardableResult mutating func insert(_ newMember: Element) -> Int {
        let newCount: Int
        if let currentCount = storage[newMember] {
            newCount = currentCount + 1
        } else {
            newCount = 1
        }
        storage[newMember] = newCount
        return newCount
    }


    /**
     Decreases the count of the given element by one. Will remove if the count was 1.

     If the element was not present in the counted set already will not do anything.
     */
    @discardableResult mutating func remove(_ member: Element) -> Int {
        let currentCount = storage[member] ?? 0
        switch currentCount {
        case 0:
            break

        case 1:
            storage.removeValue(forKey: member)

        default:
            storage[member] = currentCount - 1
        }

        return max(0, currentCount - 1)
    }
}
