//
//  BroadcastingOrderedSetFilteringContentsManagerTests.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


private class OddFilterTestContentsManager: BroadcastingOrderedSetFilteringContentsManager<BroadcastingCollectionTestContent> {

    override func filters(_ element: BroadcastingCollectionTestContent) -> Bool {
        return (element.number % 2) != 0
    }
}


private class OneInThreeTestContentsManager: BroadcastingOrderedSetFilteringContentsManager<BroadcastingCollectionTestContent> {

    override func filters(_ element: BroadcastingCollectionTestContent) -> Bool {
        return (element.number % 3) == 0
    }
}


class BroadcastingOrderedSetFilteringContentsManagerTests: BroadcastingOrderedSetSourcedContentsManagerTestCase {

    fileprivate var oddFilter = OddFilterTestContentsManager()  //  This guy doesn't really change, we can just leave it around without worrying about setup/tearDown


    override func setUp() {
        super.setUp()

        oddFilter.contentsSource = broadcastingOrderedSetSource
        editableBroadcastingOrderedSet.contentsManager = oddFilter

        //  Clear out the listener log.
        testListener.listenerLog = ""
    }


    override func tearDown() {
        editableBroadcastingOrderedSet.contentsManager = nil
        oddFilter.contentsSource = nil

        super.tearDown()
    }


    func testReevaluateElementsDidNotChange() {
        //  Just verify that telling it to reevalualte all elements with no actual changes causes no cascading effects.
        oddFilter.reevaluate(elementsAt: IndexSet(integersIn: 0 ..< sampleContent.count))

        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testReevaluateOneElementDidNotChangeFiltering() {
        //  We change one element and reevaluate it, but filtering should stay the same.
        let sourceContents = broadcastingOrderedSetSource.array
        sourceContents[0].number = 31

        oddFilter.reevaluate(sourceContents[0])

        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testReevaluateOneElementDidChangeFromFilteredToUnfiltered() {
        //  We change an element that was filtered in so it's not anymore, and then we track that the changes in the filtered managed contents are what we expect.
        let sourceContents = broadcastingOrderedSetSource.array
        let filteredIndex = broadcastingOrderedSet.contents.index(of: sourceContents[6])
        sourceContents[6].number = 32

        oddFilter.reevaluate(sourceContents[6])

        let indexedRemoval = IndexedElements(indexes: IndexSet(integer: filteredIndex), elements: [sourceContents[6]])
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willRemove: indexedRemoval)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didRemove: indexedRemoval)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReevaluateOneElementDidChangeFromUnfilteredToFiltered() {
        //  We change an element that was not filtered in so it is, and then we track that the changes in the filtered managed contents are what we expect.
        let sourceContents = broadcastingOrderedSetSource.array
        sourceContents[7].number = 31

        oddFilter.reevaluate(sourceContents[7])

        let filteredIndex = (7 + 1) / 2 //  Divided by two rounded up as we're filtering 0, 2, 4, ... by default.
        let indexedInsertion = IndexedElements(indexes: IndexSet(integer: filteredIndex), elements: [sourceContents[7]])
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: indexedInsertion)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: indexedInsertion)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReevaluateSeveralElementsWithNoFilteringChanges() {
        //  We change several elements but none of them change their filtering status. Verify that no changes percolate.
        let sourceContents = broadcastingOrderedSetSource.array
        let alteredRange = sourceContents.count / 3 ..< (sourceContents.count / 3) * 2
        for index in alteredRange {
            sourceContents[index].number += 40
        }

        oddFilter.reevaluate(elementsAt: IndexSet(integersIn: alteredRange))

        XCTAssertEqual(testListener.listenerLog, "")

    }
    
    
    func testReevaluateSeveralElementsWithAllFilteringChanges() {
        //  We change several elements so they all change their filtering status.
        let sourceContents = broadcastingOrderedSetSource.array
        let alteredRange = sourceContents.count / 3 ..< (sourceContents.count / 3) * 2
        var insertedElementsArray: [BroadcastingCollectionTestContent] = []
        var removedElementsArray: [BroadcastingCollectionTestContent] = []
        for index in alteredRange {
            let sourceContentsElement = sourceContents[index];
            sourceContentsElement.number += 39
            if oddFilter.filters(sourceContentsElement) {
                insertedElementsArray.append(sourceContentsElement)
            } else {
                removedElementsArray.append(sourceContentsElement)
            }
        }

        let filteredIndexes = IndexSet(integersIn: sourceContents.count / 6 ..< sourceContents.count / 3)

        oddFilter.reevaluate(elementsAt: IndexSet(integersIn: alteredRange))

        sampleListener.broadcastingOrderedSetWillBeginTransactions(broadcastingOrderedSet)

        let indexedRemoval = IndexedElements(indexes: filteredIndexes, elements: removedElementsArray)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willRemove: indexedRemoval)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didRemove: indexedRemoval)

        let indexedInsertion = IndexedElements(indexes: filteredIndexes, elements: insertedElementsArray)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: indexedInsertion)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: indexedInsertion)

        sampleListener.broadcastingOrderedSetDidEndTransactions(broadcastingOrderedSet)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }

    
    func testSetUpFromFilteredContents() {
        //  Cleanup all the stuff from setUp (which all the other tests use so there).
        broadcastingOrderedSetSource.contentsManager = nil
        oddFilter.contentsSource = nil
        editableBroadcastingOrderedSet.contents = NSOrderedSet()
        testListener.listenerLog = ""

        //  Now set the filter up again.
        oddFilter.contentsSource = broadcastingOrderedSetSource
        broadcastingOrderedSetSource.contentsManager = oddFilter

        let filteredIndexes = IndexSet(sampleContent.enumerated().compactMap({ (enumeration: (index: Int, element: BroadcastingCollectionTestContent)) -> Int? in
            return oddFilter.filters(enumeration.element) ? enumeration.index : nil
        }))
        let expectedDisplayContents = filteredIndexes.map({ (index) -> BroadcastingCollectionTestContent in
            return sampleContent[index]
        })

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2)
        XCTAssertEqual(broadcastingOrderedSet.array, expectedDisplayContents)

        //  Now make sure the listeners got the right changes.
        let indexedInsertion = IndexedElements(indexes: IndexSet(integersIn: 0 ..< expectedDisplayContents.count), elements: expectedDisplayContents)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: indexedInsertion)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: indexedInsertion)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testFilterReplacement() {
        //  This will be the second filter.
        let oneInThreeFilter = OneInThreeTestContentsManager()

        //  Time to figure out what we'll be removing.
        let indexesToRemove = broadcastingOrderedSet.contents.indexes(ofObjectsPassingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            let castElement = obj as! BroadcastingCollectionTestContent
            return oddFilter.filters(castElement) && !oneInThreeFilter.filters(castElement)
        }
        let elementsToRemove = broadcastingOrderedSet.array[indexesToRemove]

        //  Now set up the new filter.
        oneInThreeFilter.contentsSource = broadcastingOrderedSetSource
        editableBroadcastingOrderedSet.contentsManager = oneInThreeFilter

        let filteredIndexes = IndexSet(sampleContent.enumerated().compactMap({ (enumeration: (index: Int, element: BroadcastingCollectionTestContent)) -> Int? in
            return oneInThreeFilter.filters(enumeration.element) ? enumeration.index : nil
        }))
        let expectedDisplayContents = sampleContent[filteredIndexes]

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 3)
        XCTAssertEqual(broadcastingOrderedSet.array, expectedDisplayContents)

        //  Time to capture what we inserted according to the filters we've used.
        let insertionIndexes = broadcastingOrderedSet.contents.indexes(ofObjectsPassingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return !oddFilter.filters(obj as! BroadcastingCollectionTestContent) && oneInThreeFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        let insertionElements =  broadcastingOrderedSet.array[insertionIndexes]

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingOrderedSetWillBeginTransactions(broadcastingOrderedSet)

        let indexedRemoval = IndexedElements(indexes: indexesToRemove, elements: elementsToRemove)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willRemove: indexedRemoval)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didRemove: indexedRemoval)

        let indexedInsertion = IndexedElements(indexes: insertionIndexes, elements: insertionElements)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: indexedInsertion)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: indexedInsertion)

        sampleListener.broadcastingOrderedSetDidEndTransactions(broadcastingOrderedSet)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testInsertOnFilteredNoneInsertedFiltered() {
        let insertionArray = [BroadcastingCollectionTestContent.sampleBanon, BroadcastingCollectionTestContent.sampleGestalt]
        let insertionOrderedSet = NSOrderedSet(array: insertionArray)

        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        let expectedOrderedSet = NSOrderedSet(array: (sampleContent as NSArray).objects(at: filteredIndexes))

        broadcastingOrderedSetSource.insert(insertionOrderedSet, at: IndexSet(integersIn: sampleContent.count / 2 ..< sampleContent.count / 2 + insertionArray.count))

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testInsertOnFilteredAllInsertedFiltered() {
        let insertionArray = [BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleKefka]
        let insertionOrderedSet = NSOrderedSet(array: insertionArray)

        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        var expectedContentsArray = (sampleContent as NSArray).objects(at: filteredIndexes) as! [BroadcastingCollectionTestContent]
        expectedContentsArray.insert(contentsOf: insertionArray, at: expectedContentsArray.count / 2 + 1)
        let expectedOrderedSet = NSOrderedSet(array: expectedContentsArray)

        broadcastingOrderedSetSource.insert(insertionOrderedSet, at: IndexSet(integersIn: sampleContent.count / 2 ..< sampleContent.count / 2 + insertionArray.count))

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2 + insertionArray.count)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        let indexedInsertion = IndexedElements(indexes: IndexSet(integersIn: expectedOrderedSet.count / 2 ..< expectedOrderedSet.count / 2 + insertionArray.count), elements: insertionArray)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: indexedInsertion)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: indexedInsertion)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testInsertOnFilteredSomeInsertedFiltered() {
        let insertionArray = [BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon]
        let insertionOrderedSet = NSOrderedSet(array: insertionArray)

        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        var expectedContentsArray = (sampleContent as NSArray).objects(at: filteredIndexes) as! [BroadcastingCollectionTestContent]
        expectedContentsArray.insert(insertionArray[0], at: expectedContentsArray.count / 2 + 1)
        let expectedOrderedSet = NSOrderedSet(array: expectedContentsArray)

        broadcastingOrderedSetSource.insert(insertionOrderedSet, at: IndexSet(integersIn: sampleContent.count / 2 ..< sampleContent.count / 2 + insertionArray.count))

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2 + 1)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        let indexedInsertion = IndexedElements(indexes: IndexSet(integersIn: expectedOrderedSet.count / 2 ..< expectedOrderedSet.count / 2 + 1), elements: [insertionArray[0]])
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: indexedInsertion)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: indexedInsertion)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testRemovalFromFilteredNoneRemovedFiltered() {
        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        let expectedOrderedSet = NSOrderedSet(array: (sampleContent as NSArray).objects(at: filteredIndexes))

        var removalIndexes = IndexSet(integer: sampleContent.count / 2)
        removalIndexes.insert(removalIndexes.first! + 2)

        broadcastingOrderedSetSource.remove(from: removalIndexes)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testRemovalFromFilteredAllRemovedFiltered() {
        var removalIndexes = IndexSet(integer: sampleContent.count / 2 + 1)
        removalIndexes.insert(removalIndexes.first! + 2)
        let removedElements = sampleContent[removalIndexes]
        let removedIndexes = IndexSet(removedElements.map({ (element) -> Int in
            broadcastingOrderedSet.contents.index(of: element)
        }))

        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        let expectedOrderedSet = NSMutableOrderedSet(array: (sampleContent as NSArray).objects(at: filteredIndexes) as! [BroadcastingCollectionTestContent])
        expectedOrderedSet.removeObjects(in: (sampleContent as NSArray).objects(at: removalIndexes))

        broadcastingOrderedSetSource.remove(from: removalIndexes)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2 - removalIndexes.count)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        let indexedRemoval = IndexedElements(indexes: removedIndexes, elements: removedElements)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willRemove: indexedRemoval)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didRemove: indexedRemoval)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testRemovalFromFilteredSomeRemovedFiltered() {
        let removalIndex = sampleContent.count / 2 + 1
        var removalIndexes = IndexSet(integer: removalIndex)
        removalIndexes.insert(removalIndexes.first! + 1)
        let removedElement = sampleContent[removalIndex]
        let removedIndexes = IndexSet(integer: broadcastingOrderedSet.contents.index(of: removedElement))

        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        let expectedOrderedSet = NSMutableOrderedSet(array: (sampleContent as NSArray).objects(at: filteredIndexes) as! [BroadcastingCollectionTestContent])
        expectedOrderedSet.removeObjects(in: (sampleContent as NSArray).objects(at: removalIndexes))

        broadcastingOrderedSetSource.remove(from: removalIndexes)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2 - 1)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        let indexedRemoval = IndexedElements(indexes: removedIndexes, elements: [removedElement])
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willRemove: indexedRemoval)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didRemove: indexedRemoval)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testMoveNonFilteredUp() {
        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        let expectedOrderedSet = NSOrderedSet(array: (sampleContent as NSArray).objects(at: filteredIndexes))

        let fromIndex = sampleContent.count / 2
        let toIndex = sampleContent.count - 1
        broadcastingOrderedSetSource.move(from: fromIndex, to: toIndex)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testMoveNonFilteredDown() {
        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        let expectedOrderedSet = NSOrderedSet(array: (sampleContent as NSArray).objects(at: filteredIndexes))

        let fromIndex = sampleContent.count / 2
        broadcastingOrderedSetSource.move(from: fromIndex, to: 0)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testMoveFilteredUp() {
        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        let expectedOrderedSet = NSMutableOrderedSet(array: (sampleContent as NSArray).objects(at: filteredIndexes))
        let expectedMovedElement = sampleContent[2]
        let expectedFromIndex = 1
        let expectedToIndex = expectedOrderedSet.count - 2
        expectedOrderedSet.moveObjects(at: IndexSet(integer: expectedFromIndex), to: expectedToIndex)

        let toIndex = sampleContent.count - 3
        broadcastingOrderedSetSource.move(from: 2, to: toIndex)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willMove: expectedMovedElement, from: expectedFromIndex, to: expectedToIndex)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didMove: expectedMovedElement, from: expectedFromIndex, to: expectedToIndex)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testMoveFilteredDown() {
        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        let toIndex = sampleContent.count - 4
        let expectedOrderedSet = NSMutableOrderedSet(array: (sampleContent as NSArray).objects(at: filteredIndexes))
        let expectedMovedElement = sampleContent[toIndex]
        let expectedFromIndex = expectedOrderedSet.count - 2
        let expectedToIndex = 1
        expectedOrderedSet.moveObjects(at: IndexSet(integer: expectedFromIndex), to: expectedToIndex)

        broadcastingOrderedSetSource.move(from: toIndex, to: 2)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willMove: expectedMovedElement, from: expectedFromIndex, to: expectedToIndex)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didMove: expectedMovedElement, from: expectedFromIndex, to: expectedToIndex)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReplaceFromFilteredNoneFilteredBeforeOrAfter() {
        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        let expectedOrderedSet = NSOrderedSet(array: (sampleContent as NSArray).objects(at: filteredIndexes))

        let replacementContent = NSOrderedSet(array: [BroadcastingCollectionTestContent(number:8, string:"Shadow"), BroadcastingCollectionTestContent(number: 12, string:"Strago")])
        var replacementIndexes = IndexSet(integer: 7)   //  Clyde's index.
        replacementIndexes.insert(11)   //  Stragus index.

        broadcastingOrderedSetSource.replace(from: replacementIndexes, with: replacementContent)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testReplaceFromFilteredAllFilteredBeforeAndAfter() {
        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        let expectedOrderedSet = NSMutableOrderedSet(array: (sampleContent as NSArray).objects(at: filteredIndexes))

        let replacementContent = [BroadcastingCollectionTestContent(number:1, string:"Terra"), BroadcastingCollectionTestContent(number: 7, string:"Cyan")]
        var replacementIndexes = IndexSet(integer: 0)   //  Tina's index.
        replacementIndexes.insert(6)   //  Cayenne's index.

        var filteredReplacementIndexes = IndexSet(integer: 0)
        filteredReplacementIndexes.insert(3)
        expectedOrderedSet.replaceObjects(at: filteredReplacementIndexes, with: replacementContent)

        let replacedContent = broadcastingOrderedSetSource.array[replacementIndexes]

        broadcastingOrderedSetSource.replace(from: replacementIndexes, with: NSOrderedSet(array: replacementContent))

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        let indexedReplacees = IndexedElements(indexes: filteredReplacementIndexes, elements: replacedContent)
        let indexedReplacement = IndexedElements(indexes: filteredReplacementIndexes, elements: replacementContent)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willReplace: indexedReplacees, with: indexedReplacement)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didReplace: indexedReplacees, with: indexedReplacement)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReplaceFromFilteredNotFilteredBeforeFilteredAfter() {
        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        let expectedOrderedSet = NSMutableOrderedSet(array: (sampleContent as NSArray).objects(at: filteredIndexes))

        let replacementContent = [BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleKefka]
        var replacementIndexes = IndexSet(integer: 1)   //  Locke's index.
        replacementIndexes.insert(9)   //  Setzer's index.

        var filteredInsertionIndexes = IndexSet(integer: 1)
        filteredInsertionIndexes.insert(6)
        expectedOrderedSet.insert(replacementContent, at: filteredInsertionIndexes)

        broadcastingOrderedSetSource.replace(from: replacementIndexes, with: NSOrderedSet(array: replacementContent))

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2 + replacementContent.count)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        let indexedInsertion = IndexedElements(indexes: filteredInsertionIndexes, elements: replacementContent)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: indexedInsertion)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: indexedInsertion)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReplaceFromFilteredFilteredBeforeNotFilteredAfter() {
        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        let expectedOrderedSet = NSMutableOrderedSet(array: (sampleContent as NSArray).objects(at: filteredIndexes))

        let replacementContent = NSOrderedSet(array: [BroadcastingCollectionTestContent(number:16, string:"Leo"), BroadcastingCollectionTestContent.sampleGestalt])
        var replacementIndexes = IndexSet(integer: 2)   //  Mog's index.
        replacementIndexes.insert(8)   //  Gau's index.

        var filteredRemovalIndexes = IndexSet(integer: 1)
        filteredRemovalIndexes.insert(4)
        expectedOrderedSet.removeObjects(at: filteredRemovalIndexes)

        let removedObjects = broadcastingOrderedSetSource.array[replacementIndexes]

        broadcastingOrderedSetSource.replace(from: replacementIndexes, with: replacementContent)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2 - replacementContent.count)
        XCTAssertEqual(broadcastingOrderedSet.contents, expectedOrderedSet)

        //  Now make sure the listeners got the right changes.
        let indexedRemoval = IndexedElements(indexes: filteredRemovalIndexes, elements: removedObjects)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willRemove: indexedRemoval)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didRemove: indexedRemoval)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReplaceFromFilteredMixOfFilteredBeforeAfterAndReplacement() {
        let filteredIndexes = (sampleContent as NSArray).indexesOfObjects(passingTest:) { (obj: Any, idx: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return oddFilter.filters(obj as! BroadcastingCollectionTestContent)
        }
        var expectedContents = sampleContent[filteredIndexes]

        let replacementContent = [BroadcastingCollectionTestContent(number:1, string:"Terra"), BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon]
        var replacementIndexes = IndexSet(integer: 0)   //  Tina's index. Will be replaced.
        replacementIndexes.insert(7)   //  Clyde's index. Will go from not filtered to filtered.
        replacementIndexes.insert(10)   //  Relm's index. Will go from filtered to not filtered.

        let filteredRemovalIndexes = IndexSet(integer: 5)
        let filteredRemovedElements = [expectedContents[5]]

        let filteredReplacementIndexes = IndexSet(integer: 0)
        let filteredReplacementElements = [replacementContent[0]]
        let filteredReplacedElements = [expectedContents[0]]

        let filteredInsertionIndexes = IndexSet(integer: 4)
        let filteredInsertionElements = [replacementContent[1]]

        expectedContents.remove(at: 5)
        expectedContents[0] = replacementContent[0]
        expectedContents.insert(replacementContent[1], at: 4)

        broadcastingOrderedSetSource.replace(from: replacementIndexes, with: NSOrderedSet(array: replacementContent))

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(broadcastingOrderedSet.contents.count, sampleContent.count / 2)
        XCTAssertEqual(broadcastingOrderedSet.array, expectedContents)

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingOrderedSetWillBeginTransactions(broadcastingOrderedSet)

        let indexedRemoval = IndexedElements(indexes: filteredRemovalIndexes, elements: filteredRemovedElements)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willRemove: indexedRemoval)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didRemove: indexedRemoval)

        let indexedReplacee = IndexedElements(indexes: filteredReplacementIndexes, elements: filteredReplacedElements)
        let indexedReplacement = IndexedElements(indexes: filteredReplacementIndexes, elements: filteredReplacementElements)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willReplace: indexedReplacee, with: indexedReplacement)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didReplace: indexedReplacee, with: indexedReplacement)

        let indexedInsertion = IndexedElements(indexes: filteredInsertionIndexes, elements: filteredInsertionElements)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: indexedInsertion)
        sampleListener.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: indexedInsertion)
        sampleListener.broadcastingOrderedSetDidEndTransactions(broadcastingOrderedSet)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }
}
