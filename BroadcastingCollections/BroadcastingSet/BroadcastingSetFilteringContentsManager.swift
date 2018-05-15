//
//  BroadcastingSetFilteringContentsManager.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


extension TransactionIdentifier {
    static let setFilterReevaluation = TransactionIdentifier(rawValue: "Set filter contents manager multiple element reevaluation")
}


/**
 Superclass for a contents manager that filters a set into another set.

 All the methods are final except filters(:), which establishes the criteria for whether an element in the source
 is filtered in the managed contents, and the inherited start/end updates for the contents manager and individual
 elements, overrides of which can be used to manage any other kind of notification or event that may require a
 reevaluation.
 */
open class BroadcastingSetFilteringContentsManager<Element: Hashable>: BroadcastingSetSourcedSetContentsManager<Element, Element> {

    /**
     The most basic building block for filtering contents managers. Establishes the criteria for which elements of the
     contents source make it into the managed contents.
     - Parameter element: The element to evaluate for filtering.
     - Returns: true if the element should be present in the managed contents, false otherwise.
     */
    open func filters(_ element: Element) -> Bool {
        //  Default, override this in subclasses.
        return true
    }

    //  MARK: - BroadcastingSetContentsManager Overrides

    final public override func calculateContents() -> Set<Element> {
        //  Just filter the source contents.
        if let sourceContents = contentsSource?.contents {
            return sourceContents.filter({ (element) -> Bool in
                return filters(element)
            })
        } else {
            //  Return an empty one.
            return []
        }
    }


    override open func reevaluate(_ element: Element) {
        guard isUpdating, let managedContents = (self as BroadcastingSetContentsManager<Element>).managedContents else {
            //  Noop
            return
        }


        switch (filters(element), managedContents.contents.contains(element)) {
        case (true, false):
            //  It ought to be inserted.
            managedContents.add(element)

        case (false, true):
            //  It ought to be removed.
            managedContents.remove(element)

        default:
            break
        }
    }


    override open func reevaluate(_ elements: Set<Element>) {
        guard isUpdating, let managedContents = (self as BroadcastingSetContentsManager<Element>).managedContents else {
            //  Noop
            return
        }

        //  Parameter validation. preconditionFailure if it's not good.
        super.reevaluate(elements)

        let contentsManaged = managedContents.contents

        let insertionObjects = elements.subtracting(contentsManaged).filter({ (element) -> Bool in
            return self.filters(element)
        })

        let removalObjects = elements.intersection(contentsManaged).filter({ (element) -> Bool in
            return !self.filters(element)
        })

        let doesRemoval = !removalObjects.isEmpty
        let doesInsertion = !insertionObjects.isEmpty

        switch (doesRemoval, doesInsertion) {
        case (true, true):
            managedContents.perform(transactionWithIdentifier: .setFilterReevaluation) { () -> (Void) in
                managedContents.remove(removalObjects)
                managedContents.add(insertionObjects)
            }

        case (true, false):
            managedContents.remove(removalObjects)

        case (false, true):
            managedContents.add(insertionObjects)

        case (false, false):
            break
        }
    }

    //  MARK: - BroadcastingSetListener Overrides.

    final public override func broadcastingSet(_ broadcastingSet: BroadcastingSet<Element>, willApply change: SetChange<Element>) {
        //  Validation and element update. Done even if not currently updating.
        super.broadcastingSet(broadcastingSet, willApply: change)
    }


    final public override func broadcastingSet(_ broadcastingSet: BroadcastingSet<Element>, didApply change: SetChange<Element>) {
        //  Validation and element update. Done even if not currently updating.
        super.broadcastingSet(broadcastingSet, didApply: change)

        guard isUpdating else {
            //  updates disabled, so let's not update.
            return
        }

        //  Update the managed contents.
        switch change {
        case .insertion(let insertedElements, _):
            (self as BroadcastingSetContentsManager<Element>).managedContents?.add(insertedElements.filter({ (element) -> Bool in
                return self.filters(element)
            }))

        case .removal(let removedElements, _):
            //  Remove 'em all and let the managedContents pick its own.
            (self as BroadcastingSetContentsManager<Element>).managedContents?.remove(removedElements)
        }
    }
}
