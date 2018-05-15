//
//  BroadcastingOrderedSetSortingContentsManagerTests.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


private class NumberSortContentsManager: BroadcastingOrderedSetSortingContentsManager<BroadcastingCollectionTestContent> {

    override final func areInIncreasingOrder(_ left: BroadcastingCollectionTestContent, _ right: BroadcastingCollectionTestContent) -> Bool {
        return left.number < right.number
    }
}


private class NameSortContentsManager: BroadcastingOrderedSetSortingContentsManager<BroadcastingCollectionTestContent> {

    override final func areInIncreasingOrder(_ left: BroadcastingCollectionTestContent, _ right: BroadcastingCollectionTestContent) -> Bool {
        return left.string < right.string
    }
}


class BroadcastingOrderedSetSortingContentsManagerTests: BroadcastingOrderedSetSourcedContentsManagerTestCase {

    fileprivate var nameSorter = NameSortContentsManager()  //  This guy doesn't really change, we can just leave it around without worrying about setup/tearDown

    override func setUp() {
        super.setUp()

        nameSorter.contentsSource = broadcastingOrderedSetSource
        editableBroadcastingOrderedSet.contentsManager = nameSorter

        //  Clear out the listener log.
        testListener.listenerLog = ""
    }


    override func tearDown() {
        editableBroadcastingOrderedSet.contentsManager = nil
        nameSorter.contentsSource = nil

        super.tearDown()
    }


    func testReevaluateElementsDidNotChange() {
        //  Just verify that telling it to reevalualte all elements with no actual changes causes no cascading effects.
        nameSorter.reevaluate(elementsAt: IndexSet(integersIn: 0 ..< sampleContent.count))

        XCTAssertEqual(testListener.listenerLog, "")
    }


    private func setupNumberSorting() -> NumberSortContentsManager {
        //  Use this for the reevaluate tests are we're going to be playing with numbers.
        //  This will be the second filter.
        let numberFilter = NumberSortContentsManager()

        //  Now set up the new filter.
        numberFilter.contentsSource = broadcastingOrderedSetSource
        editableBroadcastingOrderedSet.contentsManager = numberFilter

        //  Clear the listener log.
        testListener.listenerLog = ""

        return numberFilter
    }


    func testReevaluateOneElementDidNotChangeSorting() {
        let numberSorter = setupNumberSorting()

        //  We change one element and reevaluate it, but sorting should stay the same.
        let sourceContents = broadcastingOrderedSetSource.array
        sourceContents[0].number = -1

        numberSorter.reevaluate(sourceContents[0])

        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testReevaluateOneElementDidChangeSorting() {
        let numberSorter = setupNumberSorting()

        //  We change one element so it's sort order should change (sending it to the end) and reevaluate it.
        let sourceContents = broadcastingOrderedSetSource.array
        let changedElement = sourceContents[6]
        sourceContents[6].number = 20

        numberSorter.reevaluate(sourceContents[6])

        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willMove: changedElement, from: 6, to: sourceContents.count - 1)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didMove: changedElement, from: 6, to: sourceContents.count - 1)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReevaluateSeveralElementsWithNoSortingChanges() {
        let numberSorter = setupNumberSorting()

        //  We change several elements but none of them change their sorting as they all end up sorted the same respective to each other.
        let sourceContents = broadcastingOrderedSetSource.array
        let alteredRange = sourceContents.count / 3 ..< sourceContents.count
        for index in alteredRange {
            sourceContents[index].number += 1
        }

        numberSorter.reevaluate(elementsAt: IndexSet(integersIn: alteredRange))

        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testReevaluateSeveralElementsWithAllSortingChanges() {
        let numberSorter = setupNumberSorting()

        //  We change several elements so they all change their sorting order.
        let sourceContents = broadcastingOrderedSetSource.array
        let alteredRange = sourceContents.count / 3 ..< (sourceContents.count / 3) * 2
        let alteredElements = sourceContents[alteredRange]
        for index in alteredRange {
            let sourceContentsElement = sourceContents[index];
            sourceContentsElement.number = alteredRange.upperBound - index + alteredRange.lowerBound
        }

        numberSorter.reevaluate(elementsAt: IndexSet(integersIn: alteredRange))

        sampleListener.broadcastingOrderedSetWillBeginTransactions(broadcastingOrderedSet)
        //  We know that the transform algorithm resorts from the lower indexes up so it will push up all the resorted items for our test case.
        let startIndex = alteredRange.lowerBound
        for index in alteredRange {
            let destinationIndex = alteredRange.upperBound - index + alteredRange.lowerBound - 1  //  -1 due to numbers starting at 1 in contents source.
            if startIndex != destinationIndex {
                let elementMoved = alteredElements[index]
                sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willMove: elementMoved, from: startIndex, to: destinationIndex)
                sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didMove: elementMoved, from: startIndex, to: destinationIndex)
            }
        }
        sampleListener.broadcastingOrderedSetDidEndTransactions(broadcastingOrderedSet)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testSetUpWithSorting() {
        //  Cleanup all the stuff from setUp (which all the other tests use so there).
        editableBroadcastingOrderedSet.contentsManager = nil
        nameSorter.contentsSource = nil
        editableBroadcastingOrderedSet.contents = NSOrderedSet()
        testListener.listenerLog = ""

        //  Now set the filter up again.
        nameSorter.contentsSource = broadcastingOrderedSetSource
        editableBroadcastingOrderedSet.contentsManager = nameSorter

        let insertedElements = sampleContent.sorted(by: nameSorter.sortingComparator)
        let expectedInsertion = IndexedElements(indexes: IndexSet(integersIn: 0 ..< insertedElements.count), elements: insertedElements)

        //  Assert that we got the right contents sorted.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count)
        XCTAssertEqual(broadcastingOrderedSet.array, insertedElements)

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: expectedInsertion)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: expectedInsertion)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testSortingReplacement() {
        //  This will be the second filter.
        let numberFilter = NumberSortContentsManager()

        //  Now set up the new filter.
        numberFilter.contentsSource = broadcastingOrderedSetSource
        editableBroadcastingOrderedSet.contentsManager = numberFilter

        //  Assert that we got the right contents sorted (it's the same as sampleContent).
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count)
        XCTAssertEqual(broadcastingOrderedSet.array, sampleContent)

        //  Trying to figure out the listener logs is a fool's errand as it's a complex transform and the moves could
        //  vary depending on the details of the algorithm used. That said it should be a complex transform of 8 moves
        //  as the longest sorted subsequence when going from name to number is 6 long and there's 14 elements.
        sampleListener.broadcastingOrderedSetWillBeginTransactions(broadcastingOrderedSet)
        XCTAssert(testListener.listenerLog.hasPrefix(sampleListener.listenerLog))

        sampleListener.listenerLog = ""
        sampleListener.broadcastingOrderedSetDidEndTransactions(broadcastingOrderedSet)
        XCTAssert(testListener.listenerLog.hasSuffix(sampleListener.listenerLog))

        XCTAssertEqual(testListener.listenerLog.count(of: "WILL MOVE"), 8)
    }


    func testInsertionOfOneElementInContentsSource() {
        let insertionArray = [BroadcastingCollectionTestContent.sampleLeo]

        var expectedArray = sampleContent
        expectedArray.append(contentsOf: insertionArray)
        expectedArray.sort(by: nameSorter.sortingComparator)

        let insertionOrderedSet = NSOrderedSet(array: insertionArray)
        let expectedOrderedSet = NSOrderedSet(array: expectedArray)

        broadcastingOrderedSetSource.insert(insertionOrderedSet, at: IndexSet(integersIn: sampleContent.count ..< sampleContent.count + insertionArray.count))

        //  Assert that we got the right contents sorted.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, expectedOrderedSet.count)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        let expectedInsertionIndexes = NSMutableIndexSet()
        var expectedSortedInsertedElements: [BroadcastingCollectionTestContent] = []
        expectedOrderedSet.enumerateObjects( { (object: Any, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            let element = object as! BroadcastingCollectionTestContent
            if insertionArray.contains(element) {
                expectedInsertionIndexes.add(index)
                expectedSortedInsertedElements.insert(element, at: expectedSortedInsertedElements.count)
            }
        })
        let expectedInsertion = IndexedElements(indexes: expectedInsertionIndexes as IndexSet, elements: expectedSortedInsertedElements)

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: expectedInsertion)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: expectedInsertion)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testInsertionOfManyElementsInContentsSource() {
        let insertionArray = [BroadcastingCollectionTestContent.sampleLeo,
                              BroadcastingCollectionTestContent.sampleBanon,
                              BroadcastingCollectionTestContent.sampleKefka,
                              BroadcastingCollectionTestContent.sampleGestalt]

        var expectedArray = sampleContent
        expectedArray.append(contentsOf: insertionArray)
        expectedArray.sort(by: nameSorter.sortingComparator)

        let insertionOrderedSet = NSOrderedSet(array: insertionArray)
        let expectedOrderedSet = NSOrderedSet(array: expectedArray)

        broadcastingOrderedSetSource.insert(insertionOrderedSet, at: IndexSet(integersIn: sampleContent.count ..< sampleContent.count + insertionArray.count))

        //  Assert that we got the right contents sorted.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, expectedOrderedSet.count)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        let expectedInsertionIndexes = NSMutableIndexSet()
        var expectedSortedInsertedElements: [BroadcastingCollectionTestContent] = []
        expectedOrderedSet.enumerateObjects( { (object: Any, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            let element = object as! BroadcastingCollectionTestContent
            if insertionArray.contains(element) {
                expectedInsertionIndexes.add(index)
                expectedSortedInsertedElements.insert(element, at: expectedSortedInsertedElements.count)
            }
        })
        let expectedInsertion = IndexedElements(indexes: expectedInsertionIndexes as IndexSet, elements: expectedSortedInsertedElements)

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: expectedInsertion)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: expectedInsertion)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testRemovalFromContentsSource() {
        var sourceRemovalIndexes = IndexSet(integer: sampleContent.count / 2 + 1)
        sourceRemovalIndexes.insert(sourceRemovalIndexes.first! + 2)
        let removedElements = NSOrderedSet(array: (sampleContent as NSArray).objects(at: sourceRemovalIndexes))

        var expectedArray = sampleContent
        expectedArray.sort(by: nameSorter.sortingComparator)
        let expectedOrderedSet = NSMutableOrderedSet(array: expectedArray)
        let expectedSortedRemovedIndexes = expectedOrderedSet.indexes(options: [], ofObjectsPassingTest: { (element: Any, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return removedElements.contains(element)
        })
        let expectedSortedRemovedElements = expectedOrderedSet.objects(at: expectedSortedRemovedIndexes) as! [BroadcastingCollectionTestContent]
        expectedOrderedSet.removeObjects(in: removedElements.array)

        broadcastingOrderedSetSource.remove(from: sourceRemovalIndexes)

        //  Assert that we got the right contents sorted.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, expectedOrderedSet.count)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        let expectedRemoval = IndexedElements(indexes: expectedSortedRemovedIndexes, elements: expectedSortedRemovedElements)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willRemove: expectedRemoval)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didRemove: expectedRemoval)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReplaceOneElementFromContentsSourceNoResorting() {
        let replacementElement = BroadcastingCollectionTestContent(number: 1, string: "Terra")
        let replaceeElement = sampleContent[0]
        let replacementIndex = IndexSet(integer: broadcastingOrderedSet.contents.index(of: replaceeElement))

        var expectedArray = sampleContent
        expectedArray[0] = replacementElement
        expectedArray.sort(by: nameSorter.sortingComparator)
        let expectedOrderedSet = NSOrderedSet(array: expectedArray)

        broadcastingOrderedSetSource.replace(replaceeElement, with: replacementElement)

        //  Assert that we got the right contents sorted.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, expectedOrderedSet.count)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        let expectedReplaced = IndexedElements(indexes: replacementIndex, elements: [replaceeElement])
        let expectedReplacement = IndexedElements(indexes: replacementIndex, elements: [replacementElement])
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willReplace: expectedReplaced, with: expectedReplacement)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didReplace: expectedReplaced, with: expectedReplacement)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReplaceOneElementFromContentsSourceWithResorting() {
        let replacementElement = BroadcastingCollectionTestContent(number: 8, string: "Shadow")
        let replaceeElement = sampleContent[7]
        let replacementIndex = IndexSet(integer: broadcastingOrderedSet.contents.index(of: replaceeElement))

        var expectedArray = sampleContent
        expectedArray[7] = replacementElement
        expectedArray.sort(by: nameSorter.sortingComparator)
        let expectedOrderedSet = NSOrderedSet(array: expectedArray)
        let replacementSortedIndex = expectedOrderedSet.index(of: replacementElement)

        broadcastingOrderedSetSource.replace(replaceeElement, with: replacementElement)

        //  Assert that we got the right contents sorted.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, expectedOrderedSet.count)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingOrderedSetWillBeginTransactions(broadcastingOrderedSet)

        let expectedReplaced = IndexedElements(indexes: replacementIndex, elements: [replaceeElement])
        let expectedReplacement = IndexedElements(indexes: replacementIndex, elements: [replacementElement])
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willReplace: expectedReplaced, with: expectedReplacement)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didReplace: expectedReplaced, with: expectedReplacement)

        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willMove: expectedReplacement.elements[0], from: replacementIndex[replacementIndex.startIndex], to: replacementSortedIndex)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didMove: expectedReplacement.elements[0], from: replacementIndex[replacementIndex.startIndex], to: replacementSortedIndex)

        sampleListener.broadcastingOrderedSetDidEndTransactions(broadcastingOrderedSet)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReplaceSeveralElementsNoResorting() {
        //  These are in the order they'll be replaced in sorted managed contents.
        let sortedReplacementElements = [BroadcastingCollectionTestContent(number: 2, string: "Lock"), BroadcastingCollectionTestContent(number: 1, string: "Terra")]
        let replacementElements = NSOrderedSet(array: sortedReplacementElements.reversed())  //  In the order they need to be replaced in source contents.
        let replaceeElements = [sampleContent[1], sampleContent[0]]  // In the order they'll be replaced in sorted managed contents.

        var expectedArray = sampleContent
        expectedArray[0] = replacementElements[0] as! BroadcastingCollectionTestContent
        expectedArray[1] = replacementElements[1] as! BroadcastingCollectionTestContent
        expectedArray.sort(by: nameSorter.sortingComparator)
        let expectedOrderedSet = NSOrderedSet(array: expectedArray)
        let replacementIndexes = IndexSet([expectedOrderedSet.index(of: replacementElements[0]), expectedOrderedSet.index(of: replacementElements[1])])

        broadcastingOrderedSetSource.replace(from: IndexSet(integersIn: 0 ..< 2), with: replacementElements)

        //  Assert that we got the right contents sorted.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, expectedOrderedSet.count)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        let expectedReplaced = IndexedElements(indexes: replacementIndexes, elements: replaceeElements)
        let expectedReplacement = IndexedElements(indexes: replacementIndexes, elements: sortedReplacementElements)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willReplace: expectedReplaced, with: expectedReplacement)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didReplace: expectedReplaced, with: expectedReplacement)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReplaceFromtestReplaceSeveralElementsWithResorting() {
        let sourceReplacementIndexes = IndexSet([0, 1, 6, 7, 11])

        let sourceContents = broadcastingOrderedSetSource.contents
        let sourceReplacedElements = NSOrderedSet(array: sourceContents.objects(at: sourceReplacementIndexes))

        let sourceReplacementElements = NSOrderedSet(array: [BroadcastingCollectionTestContent(number: 1, string: "Terra"),
                                                       BroadcastingCollectionTestContent(number: 2, string: "Lock"),
                                                       BroadcastingCollectionTestContent(number: 7, string: "Cyan"),
                                                       BroadcastingCollectionTestContent(number: 8, string: "Shadow"),
                                                       BroadcastingCollectionTestContent(number: 12, string: "Strago")])

        var expectedArray = sampleContent
        sourceReplacementIndexes.enumerated().forEach( { (enumeration: (offset: Int, index: Int)) -> Void in
            expectedArray[enumeration.index] = sourceReplacementElements[enumeration.offset] as! BroadcastingCollectionTestContent
        })
        expectedArray.sort(by: nameSorter.sortingComparator)
        let expectedOrderedSet = NSMutableOrderedSet(array: expectedArray)

        let sortedReplacedIndexes = broadcastingOrderedSet.contents.indexes(options: [], ofObjectsPassingTest: { (element: Any, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return sourceReplacedElements.contains(element)
        })
        let sortedReplaceeElements = broadcastingOrderedSet.array[sortedReplacedIndexes]

        let sortedReplacementElements = sortedReplacedIndexes.map( { (index) -> BroadcastingCollectionTestContent in
            return sourceReplacementElements[sourceReplacedElements.index(of: broadcastingOrderedSet[index])] as! BroadcastingCollectionTestContent
        })

        broadcastingOrderedSetSource.replace(from: sourceReplacementIndexes, with: sourceReplacementElements)

        //  Assert that we got the right contents sorted.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  There's some variability about how to do the sorting after the replacement. We'll be making sure the logs
        //  are correct for start/end, and that there's two moves only done after replacement.
        sampleListener.broadcastingOrderedSetWillBeginTransactions(broadcastingOrderedSet)

        let expectedReplaced = IndexedElements(indexes: sortedReplacedIndexes, elements: sortedReplaceeElements)
        let expectedReplacement = IndexedElements(indexes: sortedReplacedIndexes, elements: sortedReplacementElements)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willReplace: expectedReplaced, with: expectedReplacement)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didReplace: expectedReplaced, with: expectedReplacement)

        XCTAssert(testListener.listenerLog.hasPrefix(sampleListener.listenerLog))

        XCTAssert(testListener.listenerLog.count(of: "WILL MOVE") == 2)

        sampleListener.listenerLog = ""
        sampleListener.broadcastingOrderedSetDidEndTransactions(broadcastingOrderedSet)

        XCTAssert(testListener.listenerLog.hasSuffix(sampleListener.listenerLog))
    }
}
