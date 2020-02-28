//
//  EditableBroadcastingOrderedSet.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


extension TransactionIdentifier {
    static let editableBroadcastingOrderedSetComplexTransform = TransactionIdentifier(rawValue: "The editable broadcasting ordered set is undergoing a complex transform")

    static let editableBroadcastingOrderedSetSorting = TransactionIdentifier(rawValue: "The editable broadcasting ordered set is being sorted")
}


/**
 An editable broadcasting ordered set.

 The API contains:
 - Utilities for accessing its contents' array and set façades as well as a subscript.
 - Editing methods mostly in the style of NSOrderedSet (based on IndexSet for multiple element manipulation).

 The swift standard library still doesn't contain an equivalent for NSOrderedSet, which causes several impedance issues.
 Use the façade accessors and subscript when you don't need NSOrderedSet's facilities (i.e. for fast containment testing
 or element find) to avoid having to typecast all the things.
 */
public final class EditableBroadcastingOrderedSet<Element: Hashable & AnyObject> : BroadcastingOrderedSet<Element>, EditableBroadcastingCollection {

    /// Default intializer for an empty editable broadcasting set.
    public override init() {
    }

    //  MARK: - EditableBroadcastingCollection Implementation

    public var _contentsManager: BroadcastingOrderedSetContentsManager<Element>? = nil

    //  MARK: - EditableBroadcastingCollection Storage

    private let _mutableContents = NSMutableOrderedSet()

    //  MARK: - EditableBroadcastingCollection Implementation

    public func apply(change: IndexedCollectionChange<Element>) {
        switch change {
        case .insertion(let insertion, let associatedRemoval):
            if associatedRemoval != nil {
                if let (from, to) = change.singleMoveIndexes {
                    //  It's a move.
                    move(from: from, to: to)
                }
            } else {
                //  Vanilla insertion.
                insert(NSOrderedSet(array: insertion.elements), at: insertion.indexes)
            }

        case .removal(let removal, let associatedInsertion):
            //  We wait for the insertion if it's a move or replacement.
            if associatedInsertion == nil {
                //  Which means we're just left with barebones removals.
                remove(from: removal.indexes)
            }
        }
    }


    /**
     */
    public func transformContents(into newContents: NSOrderedSet) {
        _reallySet(contents: newContents,
                   removalIndexes: _removedIndexes(for: newContents),
                   replaceeIndexes: IndexSet(),
                   replacements: [],
                   insertionIndexes: _insertedIndexes(for: newContents))
    }

    //  MARK: - TransactionEditable Storage

    private var _ongoingTransactions = CountedSet<TransactionInfo>()

    public override var ongoingTransactions: CountedSet<TransactionInfo> {
        get {
            return _ongoingTransactions
        }

        set {
            _ongoingTransactions = newValue
        }
    }

    //  MARK: - BroadcastingOrderedSet Overrides

    public override var contents: NSOrderedSet {
        get {
            return _mutableContents
        }

        set {
            transformContents(into: newValue)
        }
    }


    public override var array: [Element] {
        //  Optimize away the copy.
        return _mutableContents.array as! [Element]
    }


    public override var set: Set<Element> {
        //  Optimize away the copy.
        return _mutableContents.set as! Set<Element>
    }


    public override subscript(index: Int) -> Element {
        get {
            return _mutableContents[index] as! Element
        }

        set {
            //  This is a bit more involved. The replace method does all the parameter validation.
            replace(from: index, with: newValue)
        }
    }
}


/**
 Editability:
 - Do not manually call editing methods if a contentsManager is set and is not suspended.

 //  Wholesale replacement.
 //  The steps followed when replacing the whole contents (either by calling setContents: above or any of the more
 //  sophisticated methods offered below) are the following:
 //  - Determine which elements in old contents are not present in new contents.
 //  - Determine which elements in new contents are not present in old contents.
 //  - Determine which of incoming elements is a replacement for any of the outgoing (varies depending on method called).
 //  - Remove elements not present in new contents, and which have no replacements
 //  - Replace elements not present in new contents with their found replacements. At this point none of the elements in
 //  old contents that are not in new contents are present.
 //  - Resort remaining elements (both those elements that were in the intersection between old and new contents and the
 //  already replaced ones) so they are in the same order in contents as they'll be by the end.
 //  - Insert elements not present in original contents and which weren't replacements.
 //
 //  The contents property above is settable, but additional methods are offered to allow for replacement during a full
 //  contents transform.

 //  Use this method if the replacements are already known or they are easy to compute before starting the contents
 //  transform.
 //  replaceeIndexes must be within bounds of original contents.
 //  replacements must all be contained in the contents parameter and NOT contained in original contents. They need to be sorted by replaceeIndex.
 */
extension EditableBroadcastingOrderedSet {

    public func set(_ newContents: NSOrderedSet, replacing replaceeIndexes: IndexSet, with replacements: NSOrderedSet) {
        //  We start by performing a bunch of validation on the parameters.
        let replaceeCount = replaceeIndexes.count
        guard replaceeCount == replacements.count else {
            ErrorReporter.report("Attempted to replace %ld elements with %ld elements", replaceeCount, replacements.count)
            return
        }

        if replaceeCount == 0 {
            //  Just use the simple setter.
            self.contents = newContents
            return
        }

        //  Validate that none of the replacees are in newContents.
        guard replaceeIndexes.firstIndex(where: { (index) -> Bool in
            return newContents.contains(_mutableContents[index])
        }) == nil else {
            ErrorReporter.report("Replacee element actually present in new contents")
            return
        }

        //  Validate that all replacements are in newContents
        guard !replacements.contains(where: { (element) -> Bool in
            return !newContents.contains(element)
        }) else {
            ErrorReporter.report("Replacement element is not present in new contents for transform")
            return
        }

        //  Validate that no replacements are in current contents.
        guard !replacements.contains(where: { (element) -> Bool in
            return _mutableContents.contains(element)
        }) else {
            ErrorReporter.report("Replacement element is present in current contents for transform")
            return
        }

        //  Calculate removal indexes (those that are not in the incoming contents minus those that are being replaced).
        let removalIndexes = _removedIndexes(for: newContents).subtracting(replaceeIndexes)

        //  Calculate insertion indexes (those not present in current contents minus those that are replacements).
        let insertionIndexes = _insertedIndexes(for: newContents).subtracting(IndexSet(replacements.map({ (element) -> Int in
            return newContents.index(of: element)
        })))

        //  Call the one that does all the heavy lifting.
        _reallySet(contents: newContents, removalIndexes: removalIndexes, replaceeIndexes: replaceeIndexes, replacements: replacements, insertionIndexes: insertionIndexes)
    }


    //  Use this method if whether an element is a replacement can be calculated quickly on the fly. The setter will take
    //  care of most of the heavy work of determining which elements from old contents are not present in new contents etc.
    //  replacementTest determines if any element from a given index set pointing to the new contents is a replacement to the
    //  given element (which will be one of the old contents that isn't present in the new contents). The method will first
    //  determine which elements are not in common between old and new contents and will enumerate calling
    //  the block with the outgoing elements passing in the indexes of new incoming elements that haven't been assigned
    //  already as the replacement of a prior outgoing element.
    //  The test block takes an element about to be removed and a NSIndexSet pointing to all the potential replacements in
    //  the sent contents ordered set, those being any elements that will be inserted and which haven't been already
    //  determined to be replacements of previously tested outgoing elements). Since the caller already knows what's in the
    //  new contents the block could ignore the index set if it already knows what the replacements are for greater
    //  efficiency in determining if an element is a replacement than O(n-squared) if the criteria permits it.
    public func set(_ newContents: NSOrderedSet, with replacementTest: (Element, IndexSet) -> Element?) {
        //  We start by calculating removal/insertion normally.
        var removalIndexes = _removedIndexes(for: newContents)

        var insertionIndexes = _insertedIndexes(for: newContents)

        //  And now we build up the replacee indexes/replacements using the test.
        //  We test removed indexes against inserted ones for replacements only.
        var replaceeIndexes = IndexSet()
        let replacements = NSMutableOrderedSet()
        _mutableContents.enumerateObjects(at: removalIndexes, options: []) { (element, index, stop) in
            if let replacementElement = replacementTest(element as! Element, insertionIndexes) {
                replaceeIndexes.insert(index)
                replacements.add(replacementElement)
                removalIndexes.remove(index)
                insertionIndexes.remove(newContents.index(of: replacementElement))
            }
        }

        _reallySet(contents: newContents, removalIndexes: removalIndexes, replaceeIndexes: replaceeIndexes, replacements: replacements, insertionIndexes: insertionIndexes)
    }


    fileprivate func _removedIndexes(for incomingContents: NSOrderedSet) -> IndexSet {
        return _mutableContents.indexes(options: [], ofObjectsPassingTest: { (element: Any, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return !incomingContents.contains(element)
        })
    }


    fileprivate func _insertedIndexes(for incomingContents: NSOrderedSet) -> IndexSet {
        return incomingContents.indexes(options: [], ofObjectsPassingTest: { (element: Any, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return !_mutableContents.contains(element)
        })
    }


    fileprivate func _reallySet(contents newContents: NSOrderedSet, removalIndexes: IndexSet, replaceeIndexes: IndexSet, replacements: NSOrderedSet, insertionIndexes: IndexSet) {
        let startingCount = _mutableContents.count
        guard startingCount != 0 else {
            //  We're just setting the contents altogether.
            insert(newContents, at: insertionIndexes)
            return
        }

        guard newContents.count != 0 else {
            //  We're just emptying up the joint.
            remove(from: removalIndexes)
            return
        }

        //  We got a more complex case here, need to figure out if we're doing more tha one (i.e. complex) operation.
        let removalCount = removalIndexes.count
        let insertionCount = insertionIndexes.count
        let replacementCount = replaceeIndexes.count
        var moveCount = 0

        var initialLongestSortedSubsequenceIndexes: IndexSet?
        let intersectionCount = startingCount - removalCount
        if intersectionCount > 1 {
            //  There's at least two elements in the intersection between old and new (including replacements). they may
            //  not be in the right order.
            var intersectionIndexes = IndexSet(integersIn: 0 ..< startingCount)
            intersectionIndexes.subtract(removalIndexes)

            //  Comparator will depend on whether there's replacement going on or not.
            let longestSortedSubsequenceComparator: (Element, Element) -> Bool
            if replacementCount > 0 {
                //  We need to compare against the replacements. And for that we need to be able to find them quickly.
                //  Just storing destination replacement index for replacee index.
                var replacementDictionary = Dictionary<Int, Int>(minimumCapacity: replacementCount)
                for (indexPosition, replaceeIndex) in replaceeIndexes.enumerated() {
                    replacementDictionary[replaceeIndex] = newContents.index(of: replacements[indexPosition])
                }

                //  use a more complex comparator that will compare against the replacement index.
                longestSortedSubsequenceComparator = { (obj1: Element, obj2: Element) -> Bool in
                    var obj1Index = self._mutableContents.index(of: obj1)
                    obj1Index = replacementDictionary[obj1Index] ?? newContents.index(of: obj1)

                    var obj2Index = self._mutableContents.index(of: obj2)
                    obj2Index = replacementDictionary[obj2Index] ?? newContents.index(of: obj2)

                    return obj1Index < obj2Index
                }
            } else {
                longestSortedSubsequenceComparator = newContents.elementIndexComparator
            }

            initialLongestSortedSubsequenceIndexes = (_mutableContents.array as! [Element]).indexesOfLongestSortedSubsequence(from: intersectionIndexes, sortedBy: longestSortedSubsequenceComparator)
            moveCount = intersectionCount - initialLongestSortedSubsequenceIndexes!.count
        }

        //  If we got more than one operation (remove/replace/each move/insert) then we got a complex op. We'll alert listeners before and after all the changes.
        let complexChanges = ((removalCount > 0 ? 1 : 0) + (replacementCount > 0 ? 1 : 0) + moveCount + (insertionCount > 0 ? 1 : 0)) > 1
        if complexChanges {
            beginTransaction(withInfo: TransactionInfo(identifier: .editableBroadcastingOrderedSetComplexTransform, originator: self))
        }

        //  Now we're done figuring out what we're doing, we do it.
        //  Start by removing everything we won't see again.
        remove(from: removalIndexes)

        //  Now replace any replacements we may have found. Use the internal method to avoid spurious validation.
        if replacementCount > 0 {
            _reallyReplaceElements(from: replaceeIndexes.adjustedIndexSet(for: removalIndexes), with: replacements.array as! [Element])
        }

        //  Let's see if we have to move things around...
        if moveCount > 0, let adjustedLongestSortedSubsequenceIndexes = initialLongestSortedSubsequenceIndexes?.adjustedIndexSet(for: removalIndexes) {
            _reallySort(with: adjustedLongestSortedSubsequenceIndexes, by: newContents.elementIndexComparator)
        }

        //  Finally insert all the stuff that needs inserting. Use internal method as validations should be unnecessary.
        if insertionIndexes.count > 0 {
            _reallyInsert(elements: newContents.objects(at: insertionIndexes) as! [Element], at: insertionIndexes)
        }
        insert(NSOrderedSet(array: newContents.objects(at: insertionIndexes)), at: insertionIndexes)
        
        if complexChanges {
            endTransaction(withInfo: TransactionInfo(identifier: .editableBroadcastingOrderedSetComplexTransform, originator: self))
        }
    }


    //  Insertion.
    /*  If element is already in contents at a different index, an exception will be thrown.
     If index > [contents count] an out of bounds exception will be thrown.
     */
    public func insert(_ element: Element, at index: Int) {
        if _mutableContents.count > 0 {
            //  Verify that we're not trying to insert an already contained element at a different index (undefined behavior).
            let currentIndex = _mutableContents.index(of: element)
            guard currentIndex == NSNotFound else {
                if currentIndex != index {
                    //  We're ****ed.
                    ErrorReporter.report("Attempted to insert element already in the ordered set: %@", element)
                }

                //  Either we've blown up or it was a noop.
                return
            }
        }

        _reallyInsert(elements: [element], at: IndexSet(integer: index))
    }


    /*  If any of the elements is already in contents at a different index an exception will be thrown.
     Insertion happens semantically in order. If at any point in the process the next index to insert is beyond bounds
     an exception will be thrown.
     */
    public func insert(_ elements: NSOrderedSet, at indexes: IndexSet) {
        //  Verify that the arguments are correct.
        let insertionCount = indexes.count
        guard insertionCount == elements.count else {
            ErrorReporter.report("Attempted to insert %ld elements at %ld indexes", elements.count, insertionCount)
            return
        }

        switch indexes.count {
        case 0:
            return

        case 1:
            insert(elements[0] as! Element, at: indexes.first!)

        default:
            if _mutableContents.count > 0 {
                //  We test for insertion of existing elements as the storage won't necessarily complain if there's overlap.
                let intersectionSet = elements.set.intersection(_mutableContents.set)
                let intersectionCount = intersectionSet.count
                guard intersectionCount == 0 else {
                    //  Uh Oh, we're trying to insert element/s that are already there. Unless this is a noop (all elements
                    //  are being inserted in the same place where they already are) we'll need to throw.
                    if intersectionCount != elements.count || indexes.enumerated().contains(where: { (enumeration: (offset: Int, index: Int)) -> Bool in
                        return _mutableContents.index(of: elements[enumeration.offset]) != enumeration.index
                    }) {
                        ErrorReporter.report("Attempted to insert elements already in the ordered set %@", elements)
                    }

                    //  Either we've blown up or it was a noop.
                    return
                }
            }

            //  We're good to go.
            _reallyInsert(elements: elements.array as! [Element], at: indexes)
        }
    }


    private func _reallyInsert(elements: [Element], at indexes: IndexSet) {
        //  This is the one that does the stuff with no validation whatsoever.
        let listeners = self.listeners
        let changeSet = IndexedCollectionChange<Element>.insertion(IndexedElements(indexes: indexes, elements: elements), associatedRemoval: nil)
        listeners.forEach( { (listener) in
            listener.broadcastingOrderedSet(self, willApply: changeSet)
        })

        _mutableContents.insert(elements, at: indexes)

        listeners.forEach( { (listener) in
            listener.broadcastingOrderedSet(self, didApply: changeSet)
        })
    }


    //  Set Addition: These ones don't care much for indexes, just make sure that the elements end up in contents.
    /*  Adds the element at the end of the contents, or does nothing if it's already in there.
     */
    public func add(_ element: Element) {
        //  Just insert it at the end if it isn't already included.
        if !_mutableContents.contains(element) {
            //  Go straight to _really as we've already done validation.
            _reallyInsert(elements: [element], at: IndexSet(integer: _mutableContents.count))
        }
    }


    /*  Adds whichever elements in the set are not already in contents to the end of the contents.
     */
    public func add(_ elements: Set<Element>) {
        switch elements.count {
        case 0:
            //  It's a noop.
            break

        case 1:
            //  Use the one element version.
            add(elements.first!)

        default:
            //  Triage the element.
            let triagedElements = elements.subtracting(_mutableContents.set as! Set<Element>)
            let triagedElementCount = triagedElements.count
            switch triagedElementCount {
            case 0:
                //  It's a noop.
                break

            case 1:
                add(triagedElements.first!)

            default:
                let currentCount = _mutableContents.count
                insert(NSOrderedSet(set: triagedElements), at: IndexSet(integersIn: currentCount ..< currentCount + triagedElementCount))
            }
        }
    }


    //  Removal.
    /*  If index > [contents count] an out of bounds exception will be thrown.
     */
    public func remove(from index: Int) {
        //  Just call the multiple one.
        remove(from: IndexSet(integer: index))
    }


    /*  If element is not already in contents the call is a noop.
     */
    public func remove(_ element: Element) {
        //  Unfortunately NSOrderedSet isn't properly swiftified.
        let elementIndex = _mutableContents.index(of: element)
        if elementIndex != NSNotFound {
            remove(from: IndexSet(integer: elementIndex))
        }
    }


    /*  If any of the indexes are > [contents count] an out of bounds exception will be thrown.
     */
    public func remove(from indexes: IndexSet) {
        guard !indexes.isEmpty else {
            return
        }

        //  Grab the removed elements.
        let listeners = self.listeners
        let changeSet = IndexedCollectionChange<Element>.removal(IndexedElements(indexes: indexes, elements: _mutableContents.objects(at: indexes) as! [Element]), associatedInsertion: nil)
        listeners.forEach({ (listener) in
            //  Tell the listeners.
            listener.broadcastingOrderedSet(self, willApply: changeSet)
        })

        //  The actual removal.
        _mutableContents.removeObjects(at: indexes)

        listeners.forEach({ (listener) in
            //  Tell the listeners.
            listener.broadcastingOrderedSet(self, didApply: changeSet)
        })
    }


    /*  The method will not fail if any in elements are not in contents.
     */
    public func remove(_ elements: Set<Element>) {
        let removedIndexes = IndexSet(elements.compactMap { (element: Element) -> Int? in
            let lameCocoaResult = _mutableContents.index(of: element)
            return lameCocoaResult != NSNotFound ? lameCocoaResult : nil
        })

        return remove(from: removedIndexes)
    }


    //  Moving elements around. More than one at a time is... complicated.
    /*  Both indexes must be within bounds.
     */
    public func move(from fromIndex: Int, to toIndex: Int) {
        guard fromIndex != toIndex else {
            //  It's a noop.
            return
        }

        //  Let's calculate the change set (a bit overwrought due to associated interdependency.
        let movedElement = _mutableContents[fromIndex] as! Element
        let removalChangeDescription = IndexedElements(indexes: IndexSet(integer: fromIndex), elements: [movedElement])
        let insertionChangeDescription = IndexedElements(indexes: IndexSet(integer: toIndex), elements: [movedElement])
        let removalChange = IndexedCollectionChange<Element>.removal(removalChangeDescription, associatedInsertion: insertionChangeDescription)
        let insertionChange = IndexedCollectionChange<Element>.insertion(insertionChangeDescription, associatedRemoval: removalChangeDescription)

        let listeners = self.listeners
        for listener in listeners {
            listener.broadcastingOrderedSet(self, willApply: removalChange)
            listener.broadcastingOrderedSet(self, willApply: insertionChange)
        }

        _mutableContents.moveObjects(at: IndexSet(integer: fromIndex), to: toIndex)

        for listener in listeners {
            listener.broadcastingOrderedSet(self, didApply: removalChange)
            listener.broadcastingOrderedSet(self, didApply: insertionChange)
        }
    }


    public func sort(by comparator: (Element, Element) -> Bool) {
        //  Figure out the longest sorted subsequence, that will tell us how many moves are needed which will also let
        //  us know if we're doing a complex operation.
        let longestSortedSubsequence = (contents.array as! [Element]).indexesOfLongestSortedSubsequence(sortedBy: comparator)
        let contentsCount = contents.count

        let complexOperation = longestSortedSubsequence.count < contentsCount - 1
        if complexOperation {
            beginTransaction(withInfo: TransactionInfo(identifier: .editableBroadcastingOrderedSetSorting, originator: self))
        }

        _reallySort(with: longestSortedSubsequence, by: comparator)

        if complexOperation {
            endTransaction(withInfo: TransactionInfo(identifier: .editableBroadcastingOrderedSetSorting, originator: self))
        }
    }


    //  Utility for resorting our currently held collection into a target one when we already got the
    //  longestSortedSubsequence. TargetContents should have the same contents as _mutableContents just in a different order.
    internal func _reallySort(with longestSortedSubsequenceIndexes: IndexSet, by comparator: (Element, Element) -> Bool) {
        //  Get the actual longestSortedSubsequence elements. We'll build it up until it has all the elements.
        var longestSortedSubsequence = longestSortedSubsequenceIndexes.map({ (index) -> Element in
            return _mutableContents[index] as! Element
        })

        //  Get those elements that aren't in the longest sorted subsequence yet. We'll iterate to add them to the subsequence until we're done.
        let contentsCount = _mutableContents.count
        let unsortedElementIndexes = IndexSet(integersIn: 0 ..< contentsCount).subtracting(longestSortedSubsequenceIndexes)
        let unsortedElements = _mutableContents.objects(at: unsortedElementIndexes) as! [Element]

        unsortedElements.forEach({ (nextUnsortedElement: Element) in
            let longestSortedSubsequenceCount = longestSortedSubsequence.count

            //  Find where to insert it in the already sorted elements.
            let longestSortedSubsequenceInsertionIndex = longestSortedSubsequence.insertionIndex(for: nextUnsortedElement, arraySortedUsing: comparator)

            //  Calculate the actual move to make.
            let fromIndex = _mutableContents.index(of: nextUnsortedElement)
            var toIndex = longestSortedSubsequenceInsertionIndex < longestSortedSubsequenceCount ? _mutableContents.index(of: longestSortedSubsequence[longestSortedSubsequenceInsertionIndex]) : contentsCount
            if (fromIndex < toIndex) {
                toIndex -= 1
            }

            //  Insert into LSS.
            longestSortedSubsequence.insert(nextUnsortedElement, at: longestSortedSubsequenceInsertionIndex)

            //  Perform the actual move.
            move(from: fromIndex, to: toIndex)
        })
    }


    //  Replacement.
    /*  Index must be within bounds.
     If element is already in contents at a different index an exception will be thrown.
     */
    public func replace(from index: Int, with element: Element){
        //  We need to verify that we're not replacing with an element already in contents elsewhere as that is undefined.
        let currentIndex = _mutableContents.index(of: element)
        guard currentIndex == NSNotFound else {
            if currentIndex != index {
                ErrorReporter.report("Attempted to replace element at index %d with element already in the ordered set at index: %d", index, currentIndex)
            }

            //  Either we've blown up or it was a noop.
            return
        }

        _reallyReplaceElements(from: IndexSet(integer: index), with: [element])
    }


    /*  If element is not in contents an exception will be thrown.
     If replacement is in contents already at a different index and exception will be thrown.
     */
    public func replace(_ element: Element, with replacement: Element) {
        let elementIndex = _mutableContents.index(of: element)
        guard elementIndex != NSNotFound else {
            ErrorReporter.report("Attempted to replace element that is not in contents: %@", element)
            return
        }

        replace(from: elementIndex, with: replacement)
    }


    /*  All indexes must be within bounds.
     [indexes count] must be equal to [replacements count]
     If any element in replacements is already in contents at a different index (even if it's a different index within
     the indexes parameter) an exception will be thrown.
     */
    public func replace(from indexes: IndexSet, with replacements: NSOrderedSet) {
        let replacementCount = indexes.count
        guard replacementCount == replacements.count else {
            ErrorReporter.report("Attempted to replace %ld elements with %ld elements", replacementCount, replacements.count)
            return
        }

        //  Run through validation. Will abort if invalid and filter out same element replacements.
        let validatedReplacement = _validateReplacement(of: indexes, with: replacements)

        if !validatedReplacement.validatedIndexes.isEmpty {
            //  If we got here we're good!
            _reallyReplaceElements(from: validatedReplacement.validatedIndexes, with: validatedReplacement.validatedElements)
        }
    }


    /*  If any element in elements is not in contents an exception will be thrown.
     [elements count] must be equal to [replacements count];
     If any element in replacements is already in contents and is not the same as its corresponding elements entry an
     exception will be thrown.
     */
    public func replace(_ elements: NSOrderedSet, with replacements: NSOrderedSet) {
        let replacementCount = replacements.count
        guard replacementCount == elements.count else {
            ErrorReporter.report("Attempted to replace %ld elements with %ld elements", replacementCount, elements.count)
            return
        }

        switch replacementCount {
        case 0:
            //  It's a noop
            break

        case 1:
            //  Use the one-element version which has much simpler validation.
            replace(elements[0] as! Element, with: replacements[0] as! Element)


        default:
            //  We need to find the indexes to replace. While at it we'll make sure that all replacees are actually in contents.
            var replaceeIndexes = IndexSet()
            for element in elements {
                let contentsIndex = _mutableContents.index(of: element)
                guard contentsIndex != NSNotFound else {
                    //  (no param on the log because Can't send element to the string...)
                    ErrorReporter.report("Attempted to replace an element that isn't in the contents")
                    return
                }

                replaceeIndexes.insert(contentsIndex)
            }

            //  Now make sure we sort the replacements to correspond with the replacees.
            let sortedNewElements = NSOrderedSet(array: replaceeIndexes.map({ (index) -> Element in
                return replacements[elements.index(of: _mutableContents[index])] as! Element
            }))

            //  Validate indexes/elements.
            let validatedReplacements = _validateReplacement(of: replaceeIndexes, with: sortedNewElements)

            if !validatedReplacements.validatedIndexes.isEmpty {
                //  Good to go. Further initialization to happen in indexSet based replacement.
                _reallyReplaceElements(from: validatedReplacements.validatedIndexes, with: validatedReplacements.validatedElements)
            }
        }
    }


    func _validateReplacement(of indexes: IndexSet, with elements: NSOrderedSet) -> (validatedIndexes: IndexSet, validatedElements: [Element]) {
        //  We don't really return as either everything is ok or we blow up.
        if indexes.count <= _mutableContents.count {
            //  We need to verify that the replacement being proposed is possible and is a vanilla replacement (we won't
            //  be dealing with a replacement that would involve actually moving elements around).
            //  We'll be returning those elements whose replacement is a nop and allowing those.
            let nopIndexesAndElemenet = indexes.enumerated().filter({ (offset, index) -> Bool in
                let element = elements[offset]
                let foundIndex = _mutableContents.index(of: element)
                if foundIndex != NSNotFound {
                    if foundIndex != index {
                        //  Uh, oh, we don't allow this.
                        ErrorReporter.report("Attempted to replace an element %@ already in the ordered set at index %@ a different index %@", element, foundIndex, index)
                    }

                    return true //  Won't actually be called if an error happened above.
                } else {
                    //  We're good, don't include in the nop array.
                    return false
                }
            })

            //  Build up the actual replacement index set and element array if needed.
            if !nopIndexesAndElemenet.isEmpty {
                var result: (validatedIndexes: IndexSet, validatedElements: [Element]) = (IndexSet(), [])

                //  Take out the indexes that aren't doing a thing from the input parameter.
                let nopIndexes = IndexSet(nopIndexesAndElemenet.map({ (_, index) -> Int in
                    return index
                }))
                result.validatedIndexes = indexes.subtracting(nopIndexes)

                //  Take out the elements that are not really a replacement from the elements parameter.
                let validatedElementIndexes = IndexSet(integersIn: 0 ..< elements.count).subtracting(IndexSet(nopIndexesAndElemenet.map({ (offset, _) -> Int in
                    return offset
                })))
                result.validatedElements = elements.array[validatedElementIndexes] as! [Element]

                return result
            } else {
                //  We can safely return the given parameters
                return (indexes, elements.array as! [Element])
            }
        } else {
            //  Uh, we're trying to replace more things than we have?
            ErrorReporter.report("Attempted to replace more elements %@ than already in the ordered set: %@", indexes.count, _mutableContents.count)
            return (indexes, elements.array as! [Element])  //  Won't actually return this.
        }
    }


    private func _reallyReplaceElements(from indexes: IndexSet, with replacements: [Element]) {
        //  This is the one that does the stuff with no validation whatsoever.

        //  Let's calculate the change set (a bit overwrought due to associated interdependency.
        let replacees = _mutableContents.objects(at: indexes) as! [Element]
        let removalChangeDescription = IndexedElements(indexes: indexes, elements: replacees)
        let insertionChangeDescription = IndexedElements(indexes: indexes, elements: replacements)

        guard removalChangeDescription.elements != insertionChangeDescription.elements else {
            //  This is actually a nop. Let's leave.
            return
        }

        let removalChange = IndexedCollectionChange<Element>.removal(removalChangeDescription, associatedInsertion: insertionChangeDescription)
        let insertionChange = IndexedCollectionChange<Element>.insertion(insertionChangeDescription, associatedRemoval: removalChangeDescription)

        let listeners = self.listeners
        listeners.forEach { (listener) in
            listener.broadcastingOrderedSet(self, willApply: removalChange)
            listener.broadcastingOrderedSet(self, willApply: insertionChange)
        }

        _mutableContents.replaceObjects(at: indexes, with: replacements)

        listeners.forEach { (listener) in
            listener.broadcastingOrderedSet(self, didApply: removalChange)
            listener.broadcastingOrderedSet(self, didApply: insertionChange)
        }
    }
}


//  MARK: - TransactionEditable Implementation

extension EditableBroadcastingOrderedSet {

    public func setupTransactionEnvironment() {
        makeListeners { (listener) in
            listener.broadcastingOrderedSetWillBeginTransactions(self)
        }
    }

    public func tearDownTransactionEnvironment() {
        makeListeners { (listener) in
            listener.broadcastingOrderedSetDidEndTransactions(self)
        }
    }
}


private extension NSOrderedSet {
    /*
     Get one of these to compare against the index of two elements that are already in the ordered set.
 */
    var elementIndexComparator: (Any, Any) -> Bool {
        return { (obj1: Any, obj2: Any) -> Bool in
            return self.index(of: obj1) < self.index(of: obj2)
        }
    }
}


private extension IndexSet {
    func adjustedIndexSet(for removedIndexes: IndexSet) -> IndexSet {
        if removedIndexes.count > 0 {
            var result = IndexSet()
            var removedIndex = removedIndexes.first
            var removedCount = 0
            for index in self {
                while removedIndex != nil && removedIndex! < index {
                    removedIndex = removedIndexes.integerGreaterThan(removedIndex!)
                    removedCount += 1
                }

                result.insert(index - removedCount)
            }

            return result
        } else {
            return self
        }
    }
}
