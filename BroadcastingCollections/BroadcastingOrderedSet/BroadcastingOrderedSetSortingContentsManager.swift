//
//  BroadcastingOrderedSetSortingContentsManager.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


extension TransactionIdentifier {
    static let orderedSetReplaceAndSort = TransactionIdentifier(rawValue: "Ordere set sorting contents manager will replace and resort")
}


/**
 Contents manager that sorts its broadcasting ordered set contents source.

 This base class leaves both the sorting criteria and the start/end update methods as open for inheritance. The latter
 ones are left so with the idea that often the logic to figure out when to reevaluate elements is specific to the type
 of contents being managed and is best dealt with in the start/end updates bottlenecks, both general and for elements.

 WARNING: For the time being, sorting is meant to be strict (no two elements will compare equal in sorting). Behavior
 if that is not the case is currently untested and undefined.
 */

open class BroadcastingOrderedSetSortingContentsManager<Element: Hashable & AnyObject>: BroadcastingOrderedSetSourcedOrderedSetContentsManager<Element, Element>, BroadcastingOrderedSetFullListener {

    /**
     Utility that returns a block that can be used to sort other collections with the same criteria used by this
     contents manager. Default implementation uses a weak reference to self for safety.
     */
    open var sortingComparator: (Element, Element) -> Bool {
        //  Default to a simple block that calls our comparator method. Uses [weak self] since we don't know what
        //  the caller will do with it.
        return { [weak self] (left, right) -> Bool in self?.areInIncreasingOrder(left, right) ?? false }
    }


    ///  The sorting criteria used. Override this
    open func areInIncreasingOrder(_ left: Element, _ right: Element) -> Bool {
        //  This would make things not really sorted. Override.
        return false
    }

    //  MARK: - BroadcastingOrderedSetSourcedOrderedSetContentsManager Overrides

    /**
     Reevaluates the sorting position of a single element. Call when there is reason to believe this specific element
     has changed in such a way that its sorting may be different than before.

     The method will do nothing if managed contents updating is currently disabled.
     - Precondition: element is contained in contentsSource.contents. The remaining elements in managedContents
     - Parameter element: The element whose ordering needs to be reevaluated.
     */
    final public override func reevaluate(_ element: Element) {
        guard isUpdating, let managedContents = (self as BroadcastingOrderedSetContentsManager<Element>).managedContents else {
            //  It's a noop.
            return
        }

        //  Will perform parameter and state validation.
        super.reevaluate(element)

        //  For a single element, we're assuming everything else is sorted and we move to the new correct position, if different.
        let currentIndex = managedContents.contents.index(of: element)

        guard currentIndex != NSNotFound else {
            preconditionFailure("Evaluating element not in managedContents")
        }

        //  Look first back. Try moving it as little as possible.
        let contentsManaged = managedContents.array
        var destinationIndex = contentsManaged.insertionIndex(for: element, in: contentsManaged.startIndex ..< currentIndex, arraySortedUsing: sortingComparator)
        if destinationIndex == currentIndex {
            //  We ain't moving back, let's see if we move forwards.
            destinationIndex = contentsManaged.insertionIndex(for: element, in: currentIndex + 1 ..< contentsManaged.endIndex, arraySortedUsing: sortingComparator) - 1
        }

        //  Call the move, worst that happens is nothing.
        managedContents.move(from: currentIndex, to: destinationIndex)
    }


    final public override func reevaluate(elementsAt indexes: IndexSet) {
        guard isUpdating, let managedContents = (self as BroadcastingOrderedSetContentsManager<Element>).managedContents, let contentsSource = self.contentsSource else {
            //  It's a noop.
            return
        }

        switch indexes.count {
        case 0:
            //  Nothing to do here.
            break

        case 1:
            //  Let's use the one element version as it's a lot less work.
            reevaluate(contentsSource.array[indexes[indexes.startIndex]])

        default:
            //  We don't have any real guarantees that we'll do any better than resorting the whole thing. So we do that.
            //  NOTE: We may want to revisit that assumption later. Even if we minimize the amount of moves with the
            //  current implementation, we would still end up spending too much time/memory for large collections
            //  setting things up and verifying. At least for reevaluations much smaller than the whole collection it
            //  may make sense to presume all non-reevaluated items as the longest sorted subsequence, although
            //  EditableBroadcastingOrderedSet._reallySort(with:by:) would need to be modified to guarantee that no spurious moves
            //  happen (it right now presumes everything outside the longest sorted subsequence HAS to be moved around.
            managedContents.sort(by: sortingComparator)
        }
    }

    //  MARK: - BroadcastingCollectionContentsManager Overrides

    final public override func calculateContents() -> NSOrderedSet {
        //  Just filter the source contents.
        if let sourceContents = contentsSource?.array {
            //  Return a sorted version of the source contents.
            return NSOrderedSet(array: sourceContents.sorted(by: sortingComparator))
        } else {
            //  Return an empty one.
            return NSOrderedSet()
        }
    }

    //  MARK: - BroadcastingOrderedSetFullListener Implementation

    final public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willInsert elementsAtIndexes: IndexedElements<Element>) {
        //  No need to do anything here.
    }


    final public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didInsert elementsAtIndexes: IndexedElements<Element>) {
        //  We enter this method with parameters and state already validated. broadcastingOrderedSet === contentsSource and we're updating.

        guard let managedContents = (self as BroadcastingOrderedSetContentsManager<Element>).managedContents else {
            preconditionFailure("Calling listener methods on sorting contents manager with no managed contents set")
        }

        let contentsManaged = managedContents.array
        if elementsAtIndexes.elements.count > 1 {
            //  Get the new items in the same order the'll be in managed contents.
            let sortedInsertion = broadcastingOrderedSet.array[elementsAtIndexes.indexes].sorted(by: sortingComparator)

            //  Now figure out what indexes they go in.
            let sortedInsertionIndexes = IndexSet(sortedInsertion.enumerated().map({ (enumeration: (offset: Int, element: Element)) -> Int in
                return contentsManaged.insertionIndex(for: enumeration.element, arraySortedUsing: self.sortingComparator) + enumeration.offset
            }))

            managedContents.insert(NSOrderedSet(array: sortedInsertion), at: sortedInsertionIndexes)
        } else {
            //  Let's optimize the simpler case.
            let insertedElement = elementsAtIndexes.elements[0]
            let insertedElementIndex = contentsManaged.insertionIndex(for: insertedElement, arraySortedUsing: sortingComparator)

            managedContents.insert(insertedElement, at: insertedElementIndex)
        }
    }


    final public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willRemove elementsFromIndexes: IndexedElements<Element>) {
        //  No need to do anything here.
    }


    final public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didRemove elementsFromIndexes: IndexedElements<Element>) {
        //  We enter this method with parameters and state already validated. broadcastingOrderedSet === contentsSource and we're updating.

        //  Remove them all and let the set method pick its own own.
        (self as BroadcastingOrderedSetContentsManager<Element>).managedContents?.remove(Set(elementsFromIndexes.elements))
    }


    final public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willMove element: Element, from fromIndex: Int, to toIndex: Int) {
        //  No need to do anything here. We're keeping our own sorting.
    }


    final public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didMove element: Element, from fromIndex: Int, to toIndex: Int) {
        //  No need to do anything here. We're keeping our own sorting.
    }


    final public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willReplace replacees: IndexedElements<Element>, with replacements: IndexedElements<Element>) {
        //  No need to do anything here.
    }


    final public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didReplace replacees: IndexedElements<Element>, with replacements: IndexedElements<Element>) {
        //  We enter this method with parameters and state already validated. broadcastingOrderedSet === contentsSource and we're updating.

        //  Replacement is tricky. We're going to replace the same elements in a likely different order and then resort.
        let managedContents = (self as BroadcastingOrderedSetContentsManager<Element>).managedContents!
        let contentsManaged = managedContents.contents
        let replacementCount = replacees.elements.count
        if replacementCount > 1 {
            //  Before we do the replacement we need to figure out if we'll need to resort later.
            //  Based on a similar algorithm used in EditableBroadcastingOrderedSet's transform to calculate moves needed.
            //  First let's get an dictionary that relates elements to their replacements.
            var replacementDictionary = Dictionary<Element, Element>(minimumCapacity: replacementCount)
            replacees.indexes.enumerated().forEach({ (__val:(Int, Int)) in let (offset, _) = __val;
                replacementDictionary[replacees.elements[offset]] = replacements.elements[offset]
            })

            //  Now figure out the longestSortedSubsequence based on replacements
            let longestSortedSubsequenceAfterReplacement = managedContents.array.indexesOfLongestSortedSubsequence(sortedBy: { (leftElement, rightElement) -> Bool in
                let actualLeft = replacementDictionary[leftElement] ?? leftElement
                let actualRight = replacementDictionary[rightElement] ?? rightElement

                return sortingComparator(actualLeft, actualRight)
            })

            //  With the longest sorted subsequence we know if moves are required.
            let replaceAndMove = longestSortedSubsequenceAfterReplacement.count < contentsManaged.count

            //  Now that we know if we'll replace and move, we need to replace the elements wherever they are in managed
            //  contents.
            let sortedReplacementIndexes = IndexSet(replacees.elements.map({ (element) -> Int in
                return contentsManaged.index(of: element)
            }))

            //  And get the replacements in the right order.
            let sortedReplacementElements = NSOrderedSet(array: sortedReplacementIndexes.map({ (index) -> Element in
                return replacementDictionary[managedContents[index]]!
            }))

            if replaceAndMove {
                managedContents.beginTransaction(withInfo: TransactionInfo(identifier: .orderedSetReplaceAndSort, originator: broadcastingOrderedSet))
            }

            //  Perform the actual replacement.
            managedContents.replace(from: sortedReplacementIndexes, with: sortedReplacementElements)

            if replaceAndMove {
                //  We know we gotta do this.
                managedContents._reallySort(with: longestSortedSubsequenceAfterReplacement, by: sortingComparator)

                managedContents.endTransaction(withInfo: TransactionInfo(identifier: .orderedSetReplaceAndSort, originator: broadcastingOrderedSet))
            }
        } else {
            //  We can take a simpler approach that doesn't require a full collection transform.
            let replacementElement = replacements.elements[0]
            let replaceeIndex = contentsManaged.index(of: replacees.elements[0])

            //  We can check for the replacement index straight as the replacee is still there and still in the right order.
            let replacementIndex = managedContents.array.insertionIndex(for: replacementElement, arraySortedUsing: sortingComparator)

            //  We have to move if the replacement index is in practice different than the replacee's.
            let replaceAndMove = replacementIndex < replaceeIndex || replacementIndex > replaceeIndex + 1

            if replaceAndMove {
                managedContents.beginTransaction(withInfo: TransactionInfo(identifier: .orderedSetReplaceAndSort, originator: broadcastingOrderedSet))
            }

            managedContents.replace(from: replaceeIndex, with: replacementElement)

            if replaceAndMove {
                managedContents.move(from: replaceeIndex, to: replacementIndex < replaceeIndex ? replacementIndex : replacementIndex - 1)

                managedContents.endTransaction(withInfo: TransactionInfo(identifier: .orderedSetReplaceAndSort, originator: broadcastingOrderedSet))
            }
        }
    }

    //  MARK: - BroadcastingOrderedSetListener Overrides

    final public override func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willApply change: CollectionChange<IndexedElements<Element>>) {
        validateContentsSource(forSource: broadcastingOrderedSet, called: #function)

        process(broadcastingOrderedSet: broadcastingOrderedSet, willApply: change)

        switch change {
        case .removal(let changeDescription, _):
            //  Stop updating for the stuff that is leaving.
            for element in changeDescription.elements {
                stopUpdating(element)
            }
        default:
            break
        }
    }


    final public override func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didApply change: CollectionChange<IndexedElements<Element>>) {
        validateContentsSource(forSource: broadcastingOrderedSet, called: #function)

        switch change {
        case .insertion(let changeDescription, _):
            //  Stop updating for the stuff that is leaving.
            for element in changeDescription.elements {
                startUpdating(element)
            }
        default:
            break
        }

        process(broadcastingOrderedSet: broadcastingOrderedSet, didApply: change)
    }
}
