//
//  BroadcastingOrderedSetSetFaçadeTests.swift
//  BroadcastingCollectionsTests
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest

class BroadcastingOrderedSetSetFaçadeTests: EditableBroadcastingOrderedSetTestCase {

    typealias SetListenerType = BroadcastingSetTestListener

    //  We can use BroadcastingOrderedSetTestCase but we need different listeners for the testing.
    var setTestListener: SetListenerType!


    var setSampleListener: SetListenerType!


    var broadcastingSet: BroadcastingSet<BroadcastingCollectionTestContent> {
        return broadcastingOrderedSet.broadcastingSetFaçade
    }


    override func setUp() {
        super.setUp()

        //  Create a new setTestListener and set it to listen the editable broadcasting ordered set's set façade.
        setTestListener = SetListenerType()
        editableBroadcastingOrderedSet.broadcastingSetFaçade.add(listener: setTestListener)

        //  Create a new sample listener.
        setSampleListener = SetListenerType()
    }


    override func tearDown() {
        //  Clear out all the auxiliary test objects.
        setTestListener = nil
        setSampleListener = nil

        super.tearDown()
    }


    func testInsertionOfOneElementIntoEmptyBroadcastingOrderedSet() {
        editableBroadcastingOrderedSet.contents = []
        testListener.listenerLog = ""
        setTestListener?.listenerLog = ""

        let sampleFirst = sampleContent[0]
        let expectedContents = Set([sampleFirst])

        editableBroadcastingOrderedSet.insert(sampleFirst, at: 0)

        let contents = broadcastingSet.contents
        XCTAssertEqual(contents.count, 1)
        XCTAssertEqual(contents, expectedContents)

        setSampleListener.broadcastingSet(broadcastingSet, willAdd: expectedContents)
        setSampleListener.broadcastingSet(broadcastingSet, didAdd: expectedContents)

        XCTAssertEqual(setTestListener.listenerLog, setSampleListener.listenerLog)
    }


    func testInsertionOfOneElement() {
        let elementToInsert = BroadcastingCollectionTestContent.sampleLeo
        let insertionIndex = sampleContent.count / 2

        editableBroadcastingOrderedSet.insert(elementToInsert, at: insertionIndex)

        let broadcastingSet = editableBroadcastingOrderedSet.broadcastingSetFaçade
        let contents = broadcastingSet.contents
        XCTAssertEqual(contents.count, sampleContent.count + 1)
        XCTAssert(contents.contains(elementToInsert))

        var expectedContents = Set(sampleContent)
        expectedContents.insert(elementToInsert)

        XCTAssertEqual(expectedContents, contents)

        let insertionSet = Set([elementToInsert])
        setSampleListener.broadcastingSet(broadcastingSet, willAdd: insertionSet)
        setSampleListener.broadcastingSet(broadcastingSet, didAdd: insertionSet)

        XCTAssertEqual(setTestListener.listenerLog, setSampleListener.listenerLog)
    }


    func testInsertionOfMultipleElements() {
        let insertionArray = [BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon]
        let contentsCount = sampleContent.count
        let insertionIndexes: IndexSet = [contentsCount / 3, contentsCount / 2]

        editableBroadcastingOrderedSet.insert(NSOrderedSet(array: insertionArray), at: insertionIndexes)

        let insertionElements = Set([BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon])
        let broadcastingSet = editableBroadcastingOrderedSet.broadcastingSetFaçade
        let contents = broadcastingSet.contents
        XCTAssertEqual(contents.count, contentsCount + insertionElements.count)
        XCTAssert(contents.isSuperset(of: insertionElements))

        var modifiedSampleContent = Set(sampleContent)
        modifiedSampleContent.formUnion(insertionElements)

        XCTAssertEqual(modifiedSampleContent, contents)

        setSampleListener.broadcastingSet(broadcastingSet, willAdd: insertionElements)
        setSampleListener.broadcastingSet(broadcastingSet, didAdd: insertionElements)

        XCTAssertEqual(setTestListener.listenerLog, setSampleListener.listenerLog)
    }


    func testRemovalOfASingleElement() {
        let indexToRemove = sampleContent.count / 2
        let elementToRemove = sampleContent[indexToRemove]

        editableBroadcastingOrderedSet.remove(elementToRemove)

        let broadcastingSet = editableBroadcastingOrderedSet.broadcastingSetFaçade
        let contents = broadcastingSet.contents
        XCTAssertEqual(contents.count, sampleContent.count - 1)
        XCTAssertFalse(contents.contains(elementToRemove))

        var expectedContents = Set(sampleContent)
        expectedContents.remove(elementToRemove)

        XCTAssertEqual(expectedContents, contents)

        let removedElements = Set([elementToRemove])
        setSampleListener.broadcastingSet(broadcastingSet, willRemove: removedElements)
        setSampleListener.broadcastingSet(broadcastingSet, didRemove: removedElements)

        XCTAssertEqual(setTestListener.listenerLog, setSampleListener.listenerLog)
    }


    func testRemovalOfMultipleElements() {
        let contentsCount = sampleContent.count
        let elementsToRemove = Set(sampleContent[[contentsCount / 3, contentsCount / 2]])

        editableBroadcastingOrderedSet.remove(Set(elementsToRemove))

        let broadcastingSet = editableBroadcastingOrderedSet.broadcastingSetFaçade
        let contents = broadcastingSet.contents
        XCTAssertEqual(contents.count, sampleContent.count - elementsToRemove.count)
        XCTAssert(contents.isDisjoint(with: elementsToRemove))

        var expectedContent = Set(sampleContent)
        expectedContent.subtract(elementsToRemove)

        XCTAssertEqual(expectedContent, contents)

        setSampleListener.broadcastingSet(broadcastingSet, willRemove: elementsToRemove)
        setSampleListener.broadcastingSet(broadcastingSet, didRemove: elementsToRemove)

        XCTAssertEqual(setTestListener.listenerLog, setSampleListener.listenerLog)
    }


    func testMoveItem() {
        let contentsCount = sampleContent.count
        let fromIndex = contentsCount / 3
        let toIndex = contentsCount / 2

        editableBroadcastingOrderedSet.move(from: fromIndex, to: toIndex)

        let broadcastingSet = editableBroadcastingOrderedSet.broadcastingSetFaçade
        let contents = broadcastingSet.contents
        XCTAssertEqual(contents.count, sampleContent.count)

        XCTAssertEqual(Set(sampleContent), contents)

        XCTAssertEqual(setTestListener.listenerLog, "")
    }


    func testReplaceSingleElement() {
        let indexToReplace = sampleContent.count / 2
        let replaceeElement = sampleContent[indexToReplace]
        let replacementElement = BroadcastingCollectionTestContent.sampleLeo

        editableBroadcastingOrderedSet.replace(from: indexToReplace, with: replacementElement)

        let broadcastingSet = editableBroadcastingOrderedSet.broadcastingSetFaçade
        let contents = broadcastingSet.contents
        XCTAssertEqual(contents.count, sampleContent.count)
        XCTAssertFalse(contents.contains(replaceeElement))
        XCTAssert(contents.contains(replacementElement))

        var expectedContent = Set(sampleContent)
        expectedContent.remove(replaceeElement)
        expectedContent.insert(replacementElement)

        XCTAssertEqual(expectedContent, contents)

        let removedSet = Set([replaceeElement])
        let addedSet = Set([replacementElement])
        setSampleListener.broadcastingSetWillBeginTransactions(broadcastingSet)
        setSampleListener.broadcastingSet(broadcastingSet, willRemove: removedSet)
        setSampleListener.broadcastingSet(broadcastingSet, willAdd: addedSet)
        setSampleListener.broadcastingSet(broadcastingSet, didRemove: removedSet)
        setSampleListener.broadcastingSet(broadcastingSet, didAdd: addedSet)
        setSampleListener.broadcastingSetDidEndTransactions(broadcastingSet)

        XCTAssertEqual(setTestListener.listenerLog, setSampleListener.listenerLog)
    }


    func testReplaceMultipleElements() {
        let indexesToReplace = IndexSet([sampleContent.count / 4, sampleContent.count / 3, sampleContent.count / 2])
        let replacedElements = Set(sampleContent[indexesToReplace])
        let replacementElementArray = [BroadcastingCollectionTestContent.sampleKefka, BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon]
        let replacementElements = Set(replacementElementArray)

        editableBroadcastingOrderedSet.replace(from: indexesToReplace, with: NSOrderedSet(array: replacementElementArray))

        let broadcastingSet = editableBroadcastingOrderedSet.broadcastingSetFaçade
        let contents = broadcastingSet.contents
        XCTAssertEqual(contents.count, sampleContent.count)
        XCTAssertTrue(contents.isDisjoint(with: replacedElements))
        XCTAssertTrue(contents.isSuperset(of: replacementElements))

        var expectedContent = Set(sampleContent)
        expectedContent.subtract(replacedElements)
        expectedContent.formUnion(replacementElements)

        XCTAssertEqual(expectedContent, contents)

        setSampleListener.broadcastingSetWillBeginTransactions(broadcastingSet)
        setSampleListener.broadcastingSet(broadcastingSet, willRemove: replacedElements)
        setSampleListener.broadcastingSet(broadcastingSet, willAdd: replacementElements)
        setSampleListener.broadcastingSet(broadcastingSet, didRemove: replacedElements)
        setSampleListener.broadcastingSet(broadcastingSet, didAdd: replacementElements)
        setSampleListener.broadcastingSetDidEndTransactions(broadcastingSet)

        XCTAssertEqual(setTestListener.listenerLog, setSampleListener.listenerLog)
    }
}

