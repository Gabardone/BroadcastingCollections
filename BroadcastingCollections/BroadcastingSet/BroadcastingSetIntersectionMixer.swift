//
//  BroadcastingSetIntersectionMixer.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


final public class BroadcastingSetIntersectionMixer<Element: Hashable>: BroadcastingSetMixer<Element> {

    override public init() {
    }

    //  MARK: - BroadcastingSet Overrides

    public override func contains(element: Element) -> Bool {
        for broadcastingSet in contentsSources {
            if !broadcastingSet.contains(element: element) {
                return false
            }
        }

        //  Looks like we found it in all of them.
        return true
    }

    //  MARK: - BroadcastingCollectionContentsManager Overrides

    override public func calculatedContents(for sources: Set<BroadcastingSet<Element>>) -> Set<Element> {
        //  TODO: Grab the first one.
        if var result = sources.first?.contents {
            var iterator = sources.makeIterator()
            while let nextSet = iterator.next()?.contents {
                result.formIntersection(nextSet)
            }

            return result
        } else {
            //  We got no contents whatsoever.
            return Set()
        }
    }


    override public func appliedElements(for elements: Set<Element>, against contentsSources: Set<BroadcastingSet<Element>>) -> Set<Element> {
        return elements.filter { (element) -> Bool in
            for broadcastingSet in contentsSources {
                if !broadcastingSet.contains(element: element) {
                    return false
                }
            }

            return true
        }
    }
}
