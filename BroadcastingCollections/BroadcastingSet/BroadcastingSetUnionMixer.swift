//
//  BroadcastingSetUnionMixer.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


final public class BroadcastingSetUnionMixer<Element: Hashable>: BroadcastingSetMixer<Element> {

    override public init() {
    }

    //  MARK: - BroadcastingSet Overrides

    override public func contains(element: Element) -> Bool {
        for broadcastingSet in contentsSources {
            if broadcastingSet.contains(element: element) {
                return true
            }
        }

        //  Looks like we haven't found it in any of them.
        return false
    }

    //  MARK: - BroadcastingSetMixer Overrides

    override public func calculatedContents(for sources: Set<BroadcastingSet<Element>>) -> Set<Element> {
        var result: Set<Element> = []
        sources.forEach { (contentsSource) in
            result.formUnion(contentsSource.contents)
        }

        return result
    }


    override public func appliedElements(for elements: Set<Element>, against contentsSources: Set<BroadcastingSet<Element>>) -> Set<Element> {
        return elements.filter { (element) -> Bool in
            for broadcastingSet in contentsSources {
                if broadcastingSet.contains(element: element) {
                    return false
                }
            }

            return true
        }
    }
}
