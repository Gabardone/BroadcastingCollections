//
//  BroadcastingOrderedSetFilteringContentsManager.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


extension TransactionIdentifier {
    static let orderedSetFilterReevaluation = TransactionIdentifier(rawValue: "Ordere set filter contents manager multiple element reevaluation")

    static let orderedSetFilterReplacementProcessing = TransactionIdentifier(rawValue: "Ordere set filter contents manager replacement processing")
}


open class BroadcastingOrderedSetFilteringContentsManager<Element: Hashable & AnyObject>: BroadcastingOrderedSetSourcedOrderedSetContentsManager<Element, Element>, BroadcastingOrderedSetFullListener {

    //  This is all the API you need, although you'll probably want to override some of the further superclasses
    open func filters(_ element: Element) -> Bool {
        //  Default lets everything through, override this in subclasses.
        return true
    }

    //  MARK: - Utilities

    private func _filteredInsertionIndex(of element: Element, inFiltered range: CountableRange<Int>) -> Int {
        //  Figures out where we should insert the element in the given range so it stays in the same relative order as
        //  contentSource's contents.
        //  We take a range parameter so we can use it to help determine if an element should be moved.
        let sourceContents = contentsSource!.contents
        return (self as BroadcastingOrderedSetContentsManager<Element>).managedContents!.contents.index(of: element, inSortedRange: NSRange(range), options: .insertionIndex, usingComparator: { (obj1, obj2) -> ComparisonResult in
            let obj1SourceIndex = sourceContents.index(of: obj1)
            let obj2SourceIndex = sourceContents.index(of: obj2)
            if obj1SourceIndex < obj2SourceIndex {
                return .orderedAscending
            } else if obj2SourceIndex < obj1SourceIndex {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        })
    }


    private func _insert(sourceElements elements: [Element]) {
        //  The elements are supposed to have already been validated for filtering and are in the same order as they'll
        //  appear in the filtered sample. Figure out what indexes to insert to, since they'll be different.
        let managedContents = (self as BroadcastingOrderedSetContentsManager<Element>).managedContents!
        var filteredInsertionIndexes = IndexSet()
        let currentContentsRange = 0 ..< managedContents.contents.count
        elements.enumerated().forEach { (enumeration: (offset: Int, element: Element)) -> Void in
            filteredInsertionIndexes.insert(_filteredInsertionIndex(of: enumeration.element, inFiltered: currentContentsRange) + enumeration.offset)
        }

        managedContents.insert(NSOrderedSet(array: elements), at: filteredInsertionIndexes)
    }

    //  MARK: - BroadcastingOrderedSetSourcedOrderedSetContentsManager Overrides

    final public override func reevaluate(_ element: Element) {
        guard isUpdating, let managedContents = (self as BroadcastingOrderedSetContentsManager<Element>).managedContents else {
            //  It's a noop.
            return
        }

        //  Will perform parameter and state validation.
        super.reevaluate(element)

        let contentsManaged = managedContents.contents
        let shouldBeFiltered = filters(element)
        switch (shouldBeFiltered, contentsManaged.contains(element)) {
        case (true, false):
            //  It ought to be inserted.
            managedContents.insert(element, at: _filteredInsertionIndex(of: element, inFiltered: 0 ..< contentsManaged.count))

        case (false, true):
            //  It ought to be removed.
            managedContents.remove(element)

        default:
            break
        }
    }


    final public override func reevaluate(elementsAt indexes: IndexSet) {
        guard isUpdating, let managedContents = (self as BroadcastingOrderedSetContentsManager<Element>).managedContents else {
            //  It's a noop.
            return
        }

        //  Will blow up if parameter validation fails.
        super.reevaluate(elementsAt: indexes)

        let contentsManaged = managedContents.contents
        let sourceContents = contentsSource!.array   //  We've already validated in super that contentsSource is set.

        var insertionIndexes = IndexSet()
        var removalIndexes = IndexSet()
        indexes.forEach { (index) in
            let reevaluatedElement = sourceContents[index]
            let shouldBeFiltered = filters(reevaluatedElement)
            let currentIndex = contentsManaged.index(of: reevaluatedElement)
            switch (shouldBeFiltered, currentIndex != NSNotFound) {
            case (true, false):
                //  It ought to be inserted (storing contents source indexes, we'll figure out how they translate to
                //  managed contents indexes later).
                insertionIndexes.insert(index)

            case (false, true):
                //  It ought to be removed (we remove straight, storing managed contents indexes).
                removalIndexes.insert(currentIndex)

            default:
                break
            }
        }

        let doesRemoval = !removalIndexes.isEmpty
        let doesInsertion = !insertionIndexes.isEmpty

        switch (doesRemoval, doesInsertion) {
        case (true, true):
            managedContents.perform(transactionWithIdentifier: .orderedSetFilterReevaluation) { () -> (Void) in
                managedContents.remove(from: removalIndexes)
                _insert(sourceElements: sourceContents[insertionIndexes])
            }

        case (true, false):
            managedContents.remove(from: removalIndexes)

        case (false, true):
            _insert(sourceElements: sourceContents[insertionIndexes])

        case (false, false):
            break
        }
    }

    //  MARK: - BroadcastingOrderedSetContentsManager Overrides

    final public override func calculateContents() -> NSOrderedSet {
        //  Just filter the source contents.
        if let sourceContents = contentsSource?.contents {
            return NSOrderedSet(array: sourceContents.filter({ (element) -> Bool in
                return filters(element as! Element)
            }))
        } else {
            //  Return an empty one.
            return NSOrderedSet()
        }
    }

    //  MARK: - BroadcastingIndexedCollectionFullListener Implementation

    final public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willInsert elementsAtIndexes: IndexedElements<Element>) {
        //  No need to do anything here.
    }


    final public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didInsert elementsAtIndexes: IndexedElements<Element>) {
        //  We enter this method with parameters and state already validated. broadcastingOrderedSet === contentsSource and we're updating.

        //  Figure out which ones are filtered in.
        let sourceContents = broadcastingOrderedSet.array
        let elementsToInsert = elementsAtIndexes.indexes.compactMap { (index) -> Element? in
            let element = sourceContents[index]
            return filters(element) ? element : nil
        }

        if !elementsToInsert.isEmpty {
            //  Insert them into filtered.
            _insert(sourceElements: elementsToInsert)
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
        //  No need to do anything here.
    }


    final public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didMove element: Element, from fromIndex: Int, to toIndex: Int) {
        //  We enter this method with parameters and state already validated. broadcastingOrderedSet === contentsSource and we're updating.

        let managedContents = (self as BroadcastingOrderedSetContentsManager<Element>).managedContents!
        let contentsManaged = managedContents.contents
        let movedElement = broadcastingOrderedSet.array[toIndex]
        let filteredFromIndex = contentsManaged.index(of: movedElement)
        if filteredFromIndex != NSNotFound {
            let filteredToIndex: Int
            let toGreaterThanFrom = toIndex > fromIndex
            switch (toGreaterThanFrom, filteredFromIndex) {
            case (false, 0):
                //  Going down but starting at zero, no need to calculate.
                filteredToIndex = 0

            case (false, _):
                //  Going down, figure out where.
                filteredToIndex = _filteredInsertionIndex(of: movedElement, inFiltered: 0 ..< filteredFromIndex)

            case (true, contentsManaged.count - 1):
                //  Going up but starting at the end, no need to calculate.
                filteredToIndex = contentsManaged.count - 1

            case (true, _):
                //  Going up, figure out where (need to substract one as elements are moved around).
                filteredToIndex = _filteredInsertionIndex(of: movedElement, inFiltered: filteredFromIndex + 1 ..< contentsManaged.count) - 1
            }

            if filteredFromIndex != filteredToIndex {
                //  Finally, update managedContents
                managedContents.move(from: filteredFromIndex, to: filteredToIndex)
            }
        }
    }


    final public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willReplace replacees: IndexedElements<Element>, with replacements: IndexedElements<Element>) {
        //  No need to do anything here.
    }


    final public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didReplace replacees: IndexedElements<Element>, with replacements: IndexedElements<Element>) {
        //  We enter this method with parameters and state already validated. broadcastingOrderedSet === contentsSource and we're updating.

        let managedContents = (self as BroadcastingOrderedSetContentsManager<Element>).managedContents!
        var contentsManaged = managedContents.contents

        //  We iterate through all the elements and determine which of the following cases applies:
        //  - replacee was filtered, replacement is not filtered (we remove from managed contents)
        //  - replacee filtered, replacement is also filtered (we replace on managed contents)
        //  - replacee not filtered, replacement filtered (we insert on managed contents)
        var removedFilteredIndexes = IndexSet()
        var replacedElements: [Element] = []
        let replaceeElements = NSMutableOrderedSet()
        var insertedFilteredElements: [Element] = []

        replacees.indexes.enumerated().forEach { (enumeration: (offset: Int, index: Int)) in
            let replacedElement = replacees.elements[enumeration.offset]
            let replacementElement = replacements.elements[enumeration.offset]

            let replacedFilteredIndex = contentsManaged.index(of: replacedElement)
            let replacementIsFiltered = filters(replacementElement)

            switch (replacedFilteredIndex, replacementIsFiltered) {
            case (NSNotFound, true):
                //  Insertion.
                insertedFilteredElements.append(replacementElement)

            case (_, true):
                //  Replacement
                replacedElements.append(replacedElement)
                replaceeElements.add(replacementElement)

            case (NSNotFound, false):
                //  It was out and remains out. Let's do nothing.
                break

            case (_, false):
                //  removal
                removedFilteredIndexes.insert(replacedFilteredIndex)
            }
        }

        //  Now figure out what operations we're going to be doing. If it's more than one we'll sandwich in a complex change.
        let doesRemoval = !removedFilteredIndexes.isEmpty
        let doesReplacement = replaceeElements.count > 0
        let doesInsertion = !insertedFilteredElements.isEmpty
        let doesComplexChanges = ((doesRemoval ? 1 : 0) + (doesReplacement ? 1 : 0) + (doesInsertion ? 1 : 0)) > 1

        if doesComplexChanges {
            managedContents.beginTransaction(withInfo: TransactionInfo(identifier: .orderedSetFilterReplacementProcessing, originator: managedContents))
        }

        if doesRemoval {
            managedContents.remove(from: removedFilteredIndexes)
            contentsManaged = managedContents.contents    //  Things have changed after the removal.
        }

        if doesReplacement {
            //  Need to calculate the indexes for replacement.
            let filteredReplacementIndexes = IndexSet(replacedElements.map({ (element) -> Int in
                return contentsManaged.index(of: element)
            }))
            managedContents.replace(from: filteredReplacementIndexes, with: replaceeElements)
        }

        if doesInsertion {
            _insert(sourceElements: insertedFilteredElements)
        }

        if doesComplexChanges {
            managedContents.endTransaction(withInfo: TransactionInfo(identifier: .orderedSetFilterReplacementProcessing, originator: managedContents))
        }
    }

    //  MARK: - BroadcastingOrderedSetListener Overrides

    final public override func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willApply change: CollectionChange<IndexedElements<Element>>) {
        //  Validates parameters, ensures we stop caring about outgoing elements.
        super.broadcastingOrderedSet(broadcastingOrderedSet, willApply: change)

        process(broadcastingOrderedSet: broadcastingOrderedSet, willApply: change)
    }


    final public override func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didApply change: CollectionChange<IndexedElements<Element>>) {
        //  Validates parameters, ensures we start caring about incoming elements.
        super.broadcastingOrderedSet(broadcastingOrderedSet, didApply: change)

        process(broadcastingOrderedSet: broadcastingOrderedSet, didApply: change)
    }
}
