//
//  SetChange.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


public typealias SetChange<Element: Hashable> = CollectionChange<Set<Element>>

//  TODO: Compose/decompose, additional semantics (replacement).

extension Set {
    func changes(toBecome otherSet: Set) -> [SetChange<Element>] {
        let removals = self.subtracting(otherSet)
        let insertions = otherSet.subtracting(self)
        return [.removal(removals, associatedInsertion: insertions), .insertion(insertions, associatedRemoval: removals)]
    }
}
