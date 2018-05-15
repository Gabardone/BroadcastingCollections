//
//  EditableBroadcastingSetTests.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


extension EditableBroadcastingSet where Element == BroadcastingCollectionTestContent {

    func setupWithSampleContents() {
        contents = Set(BroadcastingCollectionTestContent.sampleContent.map({ (element) -> BroadcastingCollectionTestContent in
            return element.clone()
        }))
    }
}


class EditableBroadcastingSetTests: BroadcastingSetTestCase {

    override func createBroadcastingSet() -> BroadcastingSet<BroadcastingCollectionTestContent> {
        return EditableBroadcastingSet<BroadcastingCollectionTestContent>()
    }


    override func setUp() {
        super.setUp()

        //  Set its data to a copy of sample content (notice that we don't have listeners yet).
        editableBroadcastingSet.setupWithSampleContents()

        //  Reset the test listener.
        testListener.listenerLog = ""
    }


    var editableBroadcastingSet: EditableBroadcastingSet<BroadcastingCollectionTestContent> {
        return broadcastingSet as! EditableBroadcastingSet<BroadcastingCollectionTestContent>
    }


    func testAdditionOfOneElementIntoEmptyContents() {
        let editableBroadcastingSet = self.editableBroadcastingSet

        editableBroadcastingSet.remove(editableBroadcastingSet.contents)
        testListener.listenerLog = ""

        let sampleFirst = sampleContent[0]

        editableBroadcastingSet.add(sampleFirst)

        let contents = editableBroadcastingSet.contents
        XCTAssertEqual(contents.count, 1)
        XCTAssertEqual(contents, Set([sampleContent[0]]))

        sampleListener.broadcastingSet(editableBroadcastingSet, willAdd: Set([sampleFirst]))
        sampleListener.broadcastingSet(editableBroadcastingSet, didAdd: Set([sampleFirst]))

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testAdditionOfOneElementAlreadyInContents() {
        let firstElementToInsert = sampleContent[0]

        let editableBroadcastingSet = self.editableBroadcastingSet
        editableBroadcastingSet.add(firstElementToInsert)

        //  Using add only guarantees that the contents will contain the same afterwards and that there'll be a single insertion.
        XCTAssertEqual(Set(sampleContent), editableBroadcastingSet.contents)
        XCTAssertTrue(testListener.listenerLog.isEmpty)
    }


    func testAdditionOfOneElementNotAlreadyInContents() {
        let firstElementToInsert = BroadcastingCollectionTestContent.sampleLeo

        let editableBroadcastingSet = self.editableBroadcastingSet
        editableBroadcastingSet.add(firstElementToInsert)

        var modifiedSampleContent = Set(sampleContent)
        modifiedSampleContent.insert(firstElementToInsert)

        //  Using add only guarantees that the contents will contain the same afterwards and that there'll be a single insertion.
        let contents = editableBroadcastingSet.contents
        XCTAssertEqual(modifiedSampleContent, contents)
        XCTAssertEqual(contents.count, sampleContent.count + 1)
        XCTAssertEqual(testListener.listenerLog.count(of: "ADD"), 2)    //  One each for WILL/DID
    }


    func testAdditionOfMultipleElementsAllInContents() {
        let elementsToInsert: Set<BroadcastingCollectionTestContent> = [sampleContent[0], sampleContent[6], sampleContent[10]]

        let editableBroadcastingSet = self.editableBroadcastingSet
        editableBroadcastingSet.add(elementsToInsert)

        XCTAssertEqual(editableBroadcastingSet.contents, Set(sampleContent))
        XCTAssertTrue(testListener.listenerLog.isEmpty)
    }


    func testAdditionOfMultipleElementsNoneInContents() {
        let elementsToInsert: Set<BroadcastingCollectionTestContent> = [BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon]

        let editableBroadcastingSet = self.editableBroadcastingSet
        editableBroadcastingSet.add(elementsToInsert)

        var modifiedSampleContent = Set(sampleContent)
        modifiedSampleContent.formUnion(elementsToInsert)

        //  Using add only guarantees that the contents will contain the same afterwards and that there'll be a single insertion.
        let contents = editableBroadcastingSet.contents
        XCTAssertEqual(modifiedSampleContent, contents)
        XCTAssertEqual(contents.count, sampleContent.count + elementsToInsert.count)
        XCTAssertEqual(testListener.listenerLog.count(of: "ADD"), 2)    //  One each for WILL/DID
    }


    func testAdditionOfMultipleElementsSomeInContents() {
        let elementsToInsert: Set<BroadcastingCollectionTestContent> = [BroadcastingCollectionTestContent.sampleLeo, sampleContent[0]]

        let editableBroadcastingSet = self.editableBroadcastingSet
        editableBroadcastingSet.add(elementsToInsert)

        var modifiedSampleContent = Set(sampleContent)
        modifiedSampleContent.formUnion(elementsToInsert)

        //  Using add only guarantees that the contents will contain the same afterwards and that there'll be a single insertion.
        let contents = editableBroadcastingSet.contents
        XCTAssertEqual(modifiedSampleContent, contents)
        XCTAssertEqual(contents.count, sampleContent.count + 1)
        XCTAssertEqual(testListener.listenerLog.count(of: "ADD"), 2)    //  One each for WILL/DID
    }


    func testRemovalOfASingleObject() {
        let elementToRemove = sampleContent[sampleContent.count / 2]

        let editableBroadcastingSet = self.editableBroadcastingSet
        editableBroadcastingSet.remove(elementToRemove)

        let contents = editableBroadcastingSet.contents
        XCTAssertEqual(contents.count, sampleContent.count - 1)
        XCTAssertFalse(contents.contains(elementToRemove))

        var modifiedSampleContent = Set(sampleContent)
        modifiedSampleContent.remove(elementToRemove)

        XCTAssertEqual(modifiedSampleContent, editableBroadcastingSet.contents)

        let removedSet = Set([elementToRemove])
        sampleListener.broadcastingSet(editableBroadcastingSet, willRemove: removedSet)
        sampleListener.broadcastingSet(editableBroadcastingSet, didRemove: removedSet)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testRemovalOfMultipleIndexes() {
        let contentsCount = sampleContent.count
        let elementsToRemove = Set([sampleContent[contentsCount / 3], sampleContent[contentsCount / 2]])

        let editableBroadcastingSet = self.editableBroadcastingSet
        editableBroadcastingSet.remove(elementsToRemove)

        let contents = editableBroadcastingSet.contents
        XCTAssertEqual(contents.count, sampleContent.count - elementsToRemove.count)
        elementsToRemove.forEach { (element) in
            XCTAssertFalse(contents.contains(element))
        }

        var modifiedSampleContent = Set(sampleContent)
        modifiedSampleContent.subtract(elementsToRemove)

        XCTAssertEqual(modifiedSampleContent, editableBroadcastingSet.contents)

        sampleListener.broadcastingSet(editableBroadcastingSet, willRemove: elementsToRemove)
        sampleListener.broadcastingSet(editableBroadcastingSet, didRemove: elementsToRemove)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testRemovalOfMultipleObjects() {
        let contentsCount = sampleContent.count
        let indexesToRemove: IndexSet = [contentsCount / 3, contentsCount / 2]
        let elementsToRemove = Set(sampleContent[indexesToRemove])

        let editableBroadcastingSet = self.editableBroadcastingSet
        editableBroadcastingSet.remove(Set(elementsToRemove))

        let contents = editableBroadcastingSet.contents
        XCTAssertEqual(contents.count, sampleContent.count - indexesToRemove.count)
        elementsToRemove.forEach { (element) in
            XCTAssertFalse(contents.contains(element))
        }

        var modifiedSampleContent = Set(sampleContent)
        modifiedSampleContent.subtract(elementsToRemove)

        XCTAssertEqual(modifiedSampleContent, editableBroadcastingSet.contents)

        sampleListener.broadcastingSet(editableBroadcastingSet, willRemove: elementsToRemove)
        sampleListener.broadcastingSet(editableBroadcastingSet, didRemove: elementsToRemove)
        
        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testTransformOnlyRemoves() {
        var destinationContent = Set(sampleContent)
        let removedIndexes: IndexSet = [1, 3, 5, 7, 9, 11, 13]
        let removedElements = Set(sampleContent[removedIndexes])
        destinationContent.subtract(removedElements)

        let editableBroadcastingSet = self.editableBroadcastingSet
        editableBroadcastingSet.contents = destinationContent

        //  The basic test for any transform test is that it transformed into the destination content.
        XCTAssertEqual(editableBroadcastingSet.contents, destinationContent)

        //  Test that the steps followed and broadcast are the expected ones.
        sampleListener.broadcastingSet(editableBroadcastingSet, willRemove: removedElements)
        sampleListener.broadcastingSet(editableBroadcastingSet, didRemove: removedElements)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testTransformOnlyInserts() {
        var destinationContent = Set(sampleContent)
        let insertedElements = Set([BroadcastingCollectionTestContent.sampleBanon, BroadcastingCollectionTestContent.sampleLeo])
        destinationContent.formUnion(insertedElements)

        let editableBroadcastingSet = self.editableBroadcastingSet
        editableBroadcastingSet.contents = destinationContent

        //  The basic test for any transform test is that it transformed into the destination content.
        XCTAssertEqual(editableBroadcastingSet.contents, destinationContent)

        //  Test that the steps followed and broadcast are the expected ones.
        sampleListener.broadcastingSet(editableBroadcastingSet, willAdd: insertedElements)
        sampleListener.broadcastingSet(editableBroadcastingSet, didAdd: insertedElements)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testTransformRemovesAndInserts() {
        var destinationContent = Set(sampleContent)
        let removedElements = Set(sampleContent[IndexSet([1, 3, 5, 7, 9, 11, 13])])
        destinationContent.subtract(removedElements)

        let insertedElements = Set([BroadcastingCollectionTestContent.sampleBanon, BroadcastingCollectionTestContent.sampleLeo])
        destinationContent.formUnion(insertedElements)

        let editableBroadcastingSet = self.editableBroadcastingSet
        editableBroadcastingSet.contents = destinationContent

        //  The basic test for any transform test is that it transformed into the destination content.
        XCTAssertEqual(editableBroadcastingSet.contents, destinationContent)

        //  Test that the steps followed and broadcast are the expected ones.
        sampleListener.broadcastingSetWillBeginTransactions(editableBroadcastingSet)
        sampleListener.broadcastingSet(editableBroadcastingSet, willRemove: removedElements)
        sampleListener.broadcastingSet(editableBroadcastingSet, didRemove: removedElements)
        sampleListener.broadcastingSet(editableBroadcastingSet, willAdd: insertedElements)
        sampleListener.broadcastingSet(editableBroadcastingSet, didAdd: insertedElements)
        sampleListener.broadcastingSetDidEndTransactions(editableBroadcastingSet)
        
        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }
}
