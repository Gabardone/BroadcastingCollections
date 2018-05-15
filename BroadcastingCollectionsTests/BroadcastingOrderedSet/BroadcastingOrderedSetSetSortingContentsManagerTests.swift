//
//  BroadcastingOrderedSetSetSortingContentsManagerTests.swift
//  BroadcastingCollectionsTests
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


private class NumberSortContentsManager: BroadcastingOrderedSetSetSortingContentsManager<BroadcastingCollectionTestContent> {

    override final func areInIncreasingOrder(_ left: BroadcastingCollectionTestContent, _ right: BroadcastingCollectionTestContent) -> Bool {
        return left.number < right.number
    }
}


private class NameSortContentsManager: BroadcastingOrderedSetSetSortingContentsManager<BroadcastingCollectionTestContent> {

    override final func areInIncreasingOrder(_ left: BroadcastingCollectionTestContent, _ right: BroadcastingCollectionTestContent) -> Bool {
        return left.string < right.string
    }
}



class BroadcastingOrderedSetSetSortingContentsManagerTests: BroadcastingOrderedSetTestCase {

    override func createBroadcastingOrderedSet() -> BroadcastingOrderedSet<BroadcastingCollectionTestContent> {
        return EditableBroadcastingOrderedSet<BroadcastingCollectionTestContent>()
    }


    //  Use broadcastingOrderedSet as the managed one, this one as the source.
    var broadcastingSetSource: EditableBroadcastingSet<BroadcastingCollectionTestContent>!


    fileprivate var nameSorter = NameSortContentsManager()  //  This guy doesn't really change, we can just leave it around without worrying about setup/tearDown


    override func setUp() {
        super.setUp()

        //  Clear the managed contents as we'll want it to get its contents from the contents manager.
        editableBroadcastingOrderedSet.contents = []

        //  Set up contents source.
        broadcastingSetSource = EditableBroadcastingSet<BroadcastingCollectionTestContent>()
        broadcastingSetSource.setupWithSampleContents()

        nameSorter.contentsSource = broadcastingSetSource
        editableBroadcastingOrderedSet.contentsManager = nameSorter

        //  Clear out the listener log.
        testListener.listenerLog = ""
    }


    override func tearDown() {
        editableBroadcastingOrderedSet.contentsManager = nil
        nameSorter.contentsSource = nil
        broadcastingSetSource = nil

        super.tearDown()
    }


    func testReevaluateElementsDidNotChange() {
        //  Just verify that telling it to reevalualte all elements with no actual changes causes no cascading effects.
        nameSorter.reevaluate(broadcastingSetSource.contents)

        XCTAssertEqual(testListener.listenerLog, "")
    }


    private func setupNumberSorting() -> NumberSortContentsManager {
        //  Use this for the reevaluate tests are we're going to be playing with numbers.
        //  This will be the second filter.
        let numberFilter = NumberSortContentsManager()

        //  Now set up the new filter.
        numberFilter.contentsSource = broadcastingSetSource
        editableBroadcastingOrderedSet.contentsManager = numberFilter

        //  Clear the listener log.
        testListener.listenerLog = ""

        return numberFilter
    }


    func testReevaluateOneElementDidNotChangeSorting() {
        let numberSorter = setupNumberSorting()

        //  We change one element and reevaluate it, but sorting should stay the same.
        let modifiedElement = broadcastingSetSource.contents[broadcastingSetSource.contents.index(of: sampleContent[0])!]
        modifiedElement.number = -1

        numberSorter.reevaluate(modifiedElement)

        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testReevaluateOneElementDidChangeSorting() {
        let numberSorter = setupNumberSorting()

        //  We change one element so it's sort order should change (sending it to the end) and reevaluate it.
        let modifiedElement = broadcastingSetSource.contents[broadcastingSetSource.contents.index(of: sampleContent[6])!]
        modifiedElement.number = 20

        numberSorter.reevaluate(modifiedElement)

        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willMove: modifiedElement, from: 6, to: sampleContent.count - 1)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didMove: modifiedElement, from: 6, to: sampleContent.count - 1)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReevaluateSeveralElementsWithNoSortingChanges() {
        let numberSorter = setupNumberSorting()

        //  We change several elements but none of them change their sorting as they all end up sorted the same respective to each other.
        let sampleContent = broadcastingSetSource.contents.sorted(by: numberSorter.sortingComparator)
        let alteredRange = sampleContent.count / 3 ..< sampleContent.count
        for index in alteredRange {
            sampleContent[index].number += 1
        }

        numberSorter.reevaluate(Set(sampleContent[alteredRange]))

        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testReevaluateSeveralElementsWithAllSortingChanges() {
        let numberSorter = setupNumberSorting()

        //  We change several elements so they all change their sorting order.
        let sampleContent = broadcastingSetSource.contents.sorted(by: numberSorter.sortingComparator)
        let alteredRange = sampleContent.count / 3 ..< (sampleContent.count / 3) * 2
        for index in alteredRange {
            let sampleContentElement = sampleContent[index];
            sampleContentElement.number = alteredRange.upperBound - index + alteredRange.lowerBound
        }

        numberSorter.reevaluate(Set(sampleContent[alteredRange]))

        sampleListener.broadcastingOrderedSetWillBeginTransactions(broadcastingOrderedSet)
        //  We know that the transform algorithm resorts from the lower indexes up so it will push up all the resorted items for our test case.
        let startIndex = alteredRange.lowerBound
        for index in alteredRange {
            let destinationIndex = alteredRange.upperBound - index + alteredRange.lowerBound - 1  //  -1 due to numbers starting at 1 in sampleContents.
            if startIndex != destinationIndex {
                let movedElement = sampleContent[index]
                sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willMove: movedElement, from: startIndex, to: destinationIndex)
                sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didMove: movedElement, from: startIndex, to: destinationIndex)
            }
        }
        sampleListener.broadcastingOrderedSetDidEndTransactions(broadcastingOrderedSet)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testSetUpWithSorting() {
        //  Cleanup all the stuff from setUp (which all the other tests use so there).
        editableBroadcastingOrderedSet.contentsManager = nil
        nameSorter.contentsSource = nil
        editableBroadcastingOrderedSet.contents = []
        testListener.listenerLog = ""

        //  Now set the filter up again.
        nameSorter.contentsSource = broadcastingSetSource
        editableBroadcastingOrderedSet.contentsManager = nameSorter

        let expectedDisplayContents = sampleContent.sorted(by: nameSorter.sortingComparator)

        //  Assert that we got the right contents sorted.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count)
        XCTAssertEqual(broadcastingOrderedSet.array, expectedDisplayContents)

        //  Now make sure the listeners got the right changes.
        let expectedInsertion = IndexedElements(indexes: IndexSet(integersIn: 0 ..< expectedDisplayContents.count), elements: expectedDisplayContents)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: expectedInsertion)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: expectedInsertion)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testSortingReplacement() {
        //  This will be the second filter.
        let numberFilter = NumberSortContentsManager()

        //  Now set up the new filter.
        numberFilter.contentsSource = broadcastingSetSource
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

        let expectedOrderedSet = NSOrderedSet(array: expectedArray)

        broadcastingSetSource.add(Set(insertionArray))

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

        //  Now make sure the listeners got the right changes.
        let expectedInsertion = IndexedElements(indexes: expectedInsertionIndexes as IndexSet, elements: expectedSortedInsertedElements)
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

        let expectedOrderedSet = NSOrderedSet(array: expectedArray)

        broadcastingSetSource.add(Set(insertionArray))

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

        //  Now make sure the listeners got the right changes.
        let expectedInsertion = IndexedElements(indexes: expectedInsertionIndexes as IndexSet, elements: expectedSortedInsertedElements)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: expectedInsertion)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: expectedInsertion)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testRemovalFromContentsSource() {
        var sourceRemovalIndexes = IndexSet(integer: sampleContent.count / 2 + 1)
        sourceRemovalIndexes.insert(sourceRemovalIndexes.first! + 2)
        let removedElements = Set(sampleContent[IndexSet(integer: sampleContent.count / 2 + 1)])

        var expectedArray = sampleContent
        expectedArray.sort(by: nameSorter.sortingComparator)
        let expectedOrderedSet = NSMutableOrderedSet(array: expectedArray)
        let expectedSortedRemovedIndexes = expectedOrderedSet.indexes(options: [], ofObjectsPassingTest: { (element: Any, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return removedElements.contains(element as! BroadcastingCollectionTestContent)
        })
        let expectedSortedRemovedElements = expectedOrderedSet.objects(at: expectedSortedRemovedIndexes) as! [BroadcastingCollectionTestContent]
        expectedOrderedSet.minusSet(removedElements)

        broadcastingSetSource.remove(removedElements)

        //  Assert that we got the right contents sorted.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, expectedOrderedSet.count)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        let expectedRemoval = IndexedElements(indexes: expectedSortedRemovedIndexes, elements: expectedSortedRemovedElements)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willRemove: expectedRemoval)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didRemove: expectedRemoval)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }
}
