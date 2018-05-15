//
//  BroadcastingSetFilteringContentsManagerTests.swift
//  BroadcastingCollectionsTests
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


private class OddFilterTestContentsManager: BroadcastingSetFilteringContentsManager<BroadcastingCollectionTestContent> {

    override func filters(_ element: BroadcastingCollectionTestContent) -> Bool {
        return (element.number % 2) != 0
    }
}


private class OneInThreeTestContentsManager: BroadcastingSetFilteringContentsManager<BroadcastingCollectionTestContent> {

    override func filters(_ element: BroadcastingCollectionTestContent) -> Bool {
        return (element.number % 3) == 0
    }
}


class BroadcastingSetFilteringContentsManagerTests: BroadcastingSetSourcedContentsManagerTestCase {

    fileprivate var oddFilter = OddFilterTestContentsManager()  //  This guy doesn't really change, we can just leave it around without worrying about setup/tearDown


    override func setUp() {
        super.setUp()

        oddFilter.contentsSource = broadcastingSetSource
        editableBroadcastingSet.contentsManager = oddFilter

        //  Clear out the listener log.
        testListener.listenerLog = ""
    }


    override func tearDown() {
        editableBroadcastingSet.contentsManager = nil
        oddFilter.contentsSource = nil

        super.tearDown()
    }


    func testReevaluateElementsDidNotChange() {
        //  Just verify that telling it to reevalualte all elements with no actual changes causes no cascading effects.
        oddFilter.reevaluate(Set(sampleContent))

        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testReevaluateOneElementDidNotChangeFiltering() {
        //  We change one element and reevaluate it, but filtering should stay the same.
        let alteredElement = broadcastingSetSource.contents[broadcastingSetSource.contents.index(of: sampleContent[0])!]
        alteredElement.number = 31

        oddFilter.reevaluate(alteredElement)

        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testReevaluateOneElementDidChangeFromFilteredToUnfiltered() {
        //  We change an element that was filtered in so it's not anymore, and then we track that the changes in the filtered managed contents are what we expect.
        let alteredElement = broadcastingSetSource.contents[broadcastingSetSource.contents.index(of: sampleContent[6])!]
        alteredElement.number = 32

        oddFilter.reevaluate(alteredElement)

        let alteredElementSet = Set([alteredElement])
        let filteredBroadcastingSet = editableBroadcastingSet
        sampleListener.broadcastingSet(filteredBroadcastingSet, willRemove: alteredElementSet)
        sampleListener.broadcastingSet(filteredBroadcastingSet, didRemove: alteredElementSet)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReevaluateOneElementDidChangeFromUnfilteredToFiltered() {
        //  We change an element that was not filtered in so it is, and then we track that the changes in the filtered managed contents are what we expect.
        let alteredElement = broadcastingSetSource.contents[broadcastingSetSource.contents.index(of: sampleContent[7])!]
        alteredElement.number = 31

        oddFilter.reevaluate(alteredElement)

        let alteredElementSet = Set([alteredElement])
        let filteredBroadcastingSet = editableBroadcastingSet
        sampleListener.broadcastingSet(filteredBroadcastingSet, willAdd: alteredElementSet)
        sampleListener.broadcastingSet(filteredBroadcastingSet, didAdd: alteredElementSet)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReevaluateSeveralElementsWithNoFilteringChanges() {
        //  We change several elements but none of them change their filtering status. Verify that no changes percolate.
        //  Need to access references to the actual elements in contents
        let sourceContents = broadcastingSetSource.contents
        let alteredRange = sampleContent.count / 3 ..< (sampleContent.count / 3) * 2
        let alteredElements = Set(sampleContent[alteredRange].map({ (element) -> BroadcastingCollectionTestContent in
            return sourceContents[sourceContents.index(of: element)!]
        }))

        alteredElements.forEach { (element) in
            element.number += 40
        }

        oddFilter.reevaluate(alteredElements)

        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testReevaluateSeveralElementsWithAllFilteringChanges() {
        //  We change several elements but none of them change their filtering status. Verify that no changes percolate.
        //  Need to access references to the actual elements in contents
        let sourceContents = broadcastingSetSource.contents
        let alteredRange = sampleContent.count / 3 ..< (sampleContent.count / 3) * 2
        let alteredElements = Set(sampleContent[alteredRange].map({ (element) -> BroadcastingCollectionTestContent in
            return sourceContents[sourceContents.index(of: element)!]
        }))

        alteredElements.forEach { (element) in
            element.number += 39
        }

        let removedElements = alteredElements.filter { (element) -> Bool in
            return !oddFilter.filters(element)
        }

        let addedElements = alteredElements.filter { (element) -> Bool in
            return oddFilter.filters(element)
        }

        oddFilter.reevaluate(alteredElements)

        let filteredBroadcastingSet = editableBroadcastingSet
        sampleListener.broadcastingSetWillBeginTransactions(filteredBroadcastingSet)
        sampleListener.broadcastingSet(filteredBroadcastingSet, willRemove: removedElements)
        sampleListener.broadcastingSet(filteredBroadcastingSet, didRemove: removedElements)
        sampleListener.broadcastingSet(filteredBroadcastingSet, willAdd: addedElements)
        sampleListener.broadcastingSet(filteredBroadcastingSet, didAdd: addedElements)
        sampleListener.broadcastingSetDidEndTransactions(filteredBroadcastingSet)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


        func testSetUpFromFilteredContents() {
        //  Cleanup all the stuff from setUp (which all the other tests use so there).
        let filteredBroadcastingSet = editableBroadcastingSet
        filteredBroadcastingSet.contentsManager = nil
        oddFilter.contentsSource = nil
        filteredBroadcastingSet.contents = []
        testListener.listenerLog = ""

        //  Now set the filter up again.
        oddFilter.contentsSource = broadcastingSetSource
        filteredBroadcastingSet.contentsManager = oddFilter

        let filteredElements = Set(sampleContent.filter({ (element) -> Bool in
            return oddFilter.filters(element)
        }))

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(filteredBroadcastingSet.contents.count, sampleContent.count / 2)
        XCTAssertEqual(filteredBroadcastingSet.contents, filteredElements)

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingSet(filteredBroadcastingSet, willAdd: filteredElements)
        sampleListener.broadcastingSet(filteredBroadcastingSet, didAdd: filteredElements)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testFilterReplacement() {
        //  This will be the second filter.
        let oneInThreeFilter = OneInThreeTestContentsManager()

        //  Time to figure out what we'll be removing.
        let filteredBroadcastingSet = editableBroadcastingSet
        let elementsRemoved = filteredBroadcastingSet.contents.filter { (element) -> Bool in
            return !oneInThreeFilter.filters(element)
        }

        let elementsInserted = broadcastingSetSource.contents.filter { (element) -> Bool in
            return oneInThreeFilter.filters(element) && !filteredBroadcastingSet.contents.contains(element)
        }

        let expectedElements = Set(sampleContent.filter({ (element) -> Bool in
            return oneInThreeFilter.filters(element)
        }))

        //  Now set up the new filter.
        oneInThreeFilter.contentsSource = broadcastingSetSource
        editableBroadcastingSet.contentsManager = oneInThreeFilter

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(filteredBroadcastingSet.contents.count, sampleContent.count / 3)
        XCTAssertEqual(filteredBroadcastingSet.contents, expectedElements)

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingSetWillBeginTransactions(filteredBroadcastingSet)
        sampleListener.broadcastingSet(filteredBroadcastingSet, willRemove: elementsRemoved)
        sampleListener.broadcastingSet(filteredBroadcastingSet, didRemove: elementsRemoved)
        sampleListener.broadcastingSet(filteredBroadcastingSet, willAdd: elementsInserted)
        sampleListener.broadcastingSet(filteredBroadcastingSet, didAdd: elementsInserted)
        sampleListener.broadcastingSetDidEndTransactions(filteredBroadcastingSet)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testAddOnFilteredNoneInsertedFiltered() {
        let addedElements = Set([BroadcastingCollectionTestContent.sampleBanon, BroadcastingCollectionTestContent.sampleGestalt])

        let filteredBroadcastingSet = editableBroadcastingSet
        let expectedSet = filteredBroadcastingSet.contents //  Yay value types.

        broadcastingSetSource.add(addedElements)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(filteredBroadcastingSet.contents.count, sampleContent.count / 2)
        XCTAssertEqual(filteredBroadcastingSet.contents, expectedSet)

        //  Now make sure the listeners got the right changes.
        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testInsertOnFilteredAllInsertedFiltered() {
        let addedElements = Set([BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleKefka])

        let filteredBroadcastingSet = editableBroadcastingSet
        let expectedSet = filteredBroadcastingSet.contents.union(addedElements)

        broadcastingSetSource.add(addedElements)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(filteredBroadcastingSet.contents.count, sampleContent.count / 2 + addedElements.count)
        XCTAssertEqual(filteredBroadcastingSet.contents, expectedSet)

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingSet(filteredBroadcastingSet, willAdd: addedElements)
        sampleListener.broadcastingSet(filteredBroadcastingSet, didAdd: addedElements)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testInsertOnFilteredSomeInsertedFiltered() {
        //  These get added to broadcastingSetSource
        let addedElements = Set([BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon])

        //  These are what actually gets added to managedContents.contents
        let addedFilteredElements = addedElements.filter({ (element) -> Bool in
            return oddFilter.filters(element)
        })

        let filteredBroadcastingSet = editableBroadcastingSet
        let expectedContents = filteredBroadcastingSet.contents.union(addedFilteredElements)

        broadcastingSetSource.add(addedElements)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(filteredBroadcastingSet.contents.count, sampleContent.count / 2 + 1)
        XCTAssertEqual(filteredBroadcastingSet.contents, expectedContents)

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingSet(filteredBroadcastingSet, willAdd: addedFilteredElements)
        sampleListener.broadcastingSet(filteredBroadcastingSet, didAdd: addedFilteredElements)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testRemovalFromFilteredNoneRemovedFiltered() {
        let removedElements = Set([sampleContent[sampleContent.count / 2], sampleContent[sampleContent.count / 2 + 2]])
        let filteredBroadcastingSet = editableBroadcastingSet
        let expectedContents = filteredBroadcastingSet.contents   //  Yay CoW

        broadcastingSetSource.remove(removedElements)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(filteredBroadcastingSet.contents.count, sampleContent.count / 2)
        XCTAssertEqual(filteredBroadcastingSet.contents, expectedContents)

        //  Now make sure the listeners got the right changes.
        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testRemovalFromFilteredAllRemovedFiltered() {
        let removedElements = Set([sampleContent[sampleContent.count / 2 + 1], sampleContent[sampleContent.count / 2 + 3]])
        let filteredBroadcastingSet = editableBroadcastingSet
        let expectedContents = filteredBroadcastingSet.contents.subtracting(removedElements)

        broadcastingSetSource.remove(removedElements)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(filteredBroadcastingSet.contents.count, sampleContent.count / 2 - removedElements.count)
        XCTAssertEqual(filteredBroadcastingSet.contents, expectedContents)

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingSet(filteredBroadcastingSet, willRemove: removedElements)
        sampleListener.broadcastingSet(filteredBroadcastingSet, didRemove: removedElements)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testRemovalFromFilteredSomeRemovedFiltered() {
        let removedElements = Set(sampleContent[sampleContent.count / 2 ..< sampleContent.count / 2 + 4])
        let removedFilteredElements = removedElements.filter { (element) -> Bool in
            return oddFilter.filters(element)
        }
        let filteredBroadcastingSet = editableBroadcastingSet
        let expectedContents = filteredBroadcastingSet.contents.subtracting(removedElements)

        broadcastingSetSource.remove(removedElements)

        //  Assert that we got the right contents filtered.
        XCTAssertEqual(filteredBroadcastingSet.contents.count, sampleContent.count / 2 - removedFilteredElements.count)
        XCTAssertEqual(filteredBroadcastingSet.contents, expectedContents)

        //  Now make sure the listeners got the right changes.
        sampleListener.broadcastingSet(filteredBroadcastingSet, willRemove: removedFilteredElements)
        sampleListener.broadcastingSet(filteredBroadcastingSet, didRemove: removedFilteredElements)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }
}
