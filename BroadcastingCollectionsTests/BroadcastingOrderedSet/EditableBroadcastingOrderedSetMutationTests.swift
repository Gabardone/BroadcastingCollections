//
//  EditableBroadcastingOrderedSetMutationTests.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

@testable import BroadcastingCollections
import XCTest


class EditableBroadcastingOrderedSetMutationTests: EditableBroadcastingOrderedSetTestCase {

    func testInsertionOfOneElementIntoEmptyContents() {
        //  Clean it up first, we don't want the sample content for this one.
        editableBroadcastingOrderedSet.contents = []
        testListener.listenerLog = ""

        let sampleFirst = sampleContent[0]

        editableBroadcastingOrderedSet.insert(sampleFirst, at: 0)

        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(contents.count, 1)
        XCTAssertEqual((contents.array as! [BroadcastingCollectionTestContent]), [sampleContent[0]])

        let insertedElementsAtIndexes = IndexedElements(indexes: IndexSet(integer: 0), elements: [sampleFirst])
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willInsert: insertedElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didInsert: insertedElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testInsertionOfOneElement() {
        let elementToInsert = BroadcastingCollectionTestContent.sampleLeo
        let insertionIndex = sampleContent.count / 2

        editableBroadcastingOrderedSet.insert(elementToInsert, at: insertionIndex)

        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(contents.count, sampleContent.count + 1)
        XCTAssertEqual(contents[insertionIndex] as! BroadcastingCollectionTestContent, elementToInsert)

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.insert(elementToInsert, at: Int(insertionIndex))

        XCTAssertEqual(modifiedSampleContent, contents)

        let insertionElementsAtIndexes = IndexedElements(indexes: IndexSet(integer: Int(insertionIndex)), elements: [elementToInsert])
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willInsert: insertionElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didInsert: insertionElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testInsertionOfOneElementAtTheEnd() {
        let elementToInsert = BroadcastingCollectionTestContent.sampleLeo
        let insertionIndex = sampleContent.count

        editableBroadcastingOrderedSet.insert(elementToInsert, at: insertionIndex)

        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(contents.count, sampleContent.count + 1)
        XCTAssertEqual(contents[insertionIndex] as! BroadcastingCollectionTestContent, elementToInsert)
        XCTAssertEqual(contents.lastObject as! BroadcastingCollectionTestContent, elementToInsert)

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.insert(elementToInsert, at: Int(insertionIndex))

        XCTAssertEqual(modifiedSampleContent, contents)

        let insertionElementsAtIndexes = IndexedElements(indexes: IndexSet(integer: Int(insertionIndex)), elements: [elementToInsert])
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willInsert: insertionElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didInsert: insertionElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testInsertionOfMultipleElements() {
        let firstElementToInsert = BroadcastingCollectionTestContent.sampleLeo
        let secondElementToInsert = BroadcastingCollectionTestContent.sampleBanon
        let insertionElements = [firstElementToInsert, secondElementToInsert]
        let contentsCount = sampleContent.count
        let insertionIndexes: IndexSet = [contentsCount / 3, contentsCount / 2]

        editableBroadcastingOrderedSet.insert(NSOrderedSet(array: insertionElements), at: insertionIndexes)

        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(contents.count, contentsCount + insertionElements.count)
        XCTAssertEqual(contents[insertionIndexes.first!] as! BroadcastingCollectionTestContent, firstElementToInsert)
        XCTAssertEqual(contents[insertionIndexes.last!] as! BroadcastingCollectionTestContent, secondElementToInsert)

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.insert(insertionElements, at: insertionIndexes)

        XCTAssertEqual(modifiedSampleContent, contents)

        let insertionElementsAtIndexes = IndexedElements(indexes: insertionIndexes, elements: insertionElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willInsert: insertionElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didInsert: insertionElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testInsertionOfMultipleElementsAtBeginningAndEnd() {
        let firstElementToInsert = BroadcastingCollectionTestContent.sampleLeo
        let secondElementToInsert = BroadcastingCollectionTestContent.sampleBanon
        let insertionElements = [firstElementToInsert, secondElementToInsert]
        let contentsCount = sampleContent.count
        let insertionIndexes: IndexSet = [0, contentsCount + 1]

        editableBroadcastingOrderedSet.insert(NSOrderedSet(array: insertionElements), at: insertionIndexes)

        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(contents.count, contentsCount + insertionElements.count)
        XCTAssertEqual(contents[insertionIndexes.first!] as! BroadcastingCollectionTestContent, firstElementToInsert)
        XCTAssertEqual(contents[insertionIndexes.last!] as! BroadcastingCollectionTestContent, secondElementToInsert)
        XCTAssertEqual(contents.firstObject as! BroadcastingCollectionTestContent, firstElementToInsert)
        XCTAssertEqual(contents.lastObject as! BroadcastingCollectionTestContent, secondElementToInsert)

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.insert(insertionElements, at: insertionIndexes)

        XCTAssertEqual(modifiedSampleContent, contents)

        let insertionElementsAtIndexes = IndexedElements(indexes: insertionIndexes, elements: insertionElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willInsert: insertionElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didInsert: insertionElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testAdditionOfOneElementAlreadyInContents() {
        let firstElementToInsert = sampleContent[0]

        editableBroadcastingOrderedSet.add(firstElementToInsert)

        //  Using add only guarantees that the contents will contain the same afterwards and that there'll be a single insertion.
        XCTAssertEqual(Set(sampleContent), editableBroadcastingOrderedSet.contents.set as! Set<BroadcastingCollectionTestContent>)
        XCTAssertTrue(testListener.listenerLog.isEmpty)
    }

    
    func testAdditionOfOneElementNotAlreadyInContents() {
        let firstElementToInsert = BroadcastingCollectionTestContent.sampleLeo

        editableBroadcastingOrderedSet.add(firstElementToInsert)

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.add(firstElementToInsert)

        //  Using add only guarantees that the contents will contain the same afterwards and that there'll be a single insertion.
        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(modifiedSampleContent.set, contents.set)
        XCTAssertEqual(contents.count, sampleContent.count + 1)
        XCTAssertEqual(testListener.listenerLog.count(of: "INSERT"), 2)    //  One each for WILL/DID
    }


    func testAdditionOfMultipleElementsAllInContents() {
        let elementsToInsert: Set<BroadcastingCollectionTestContent> = [sampleContent[0], sampleContent[6], sampleContent[10]]

        editableBroadcastingOrderedSet.add(elementsToInsert)

        XCTAssertEqual(editableBroadcastingOrderedSet.contents.array as! [BroadcastingCollectionTestContent], sampleContent)
        XCTAssertTrue(testListener.listenerLog.isEmpty)
    }


    func testAdditionOfMultipleElementsNoneInContents() {
        let elementsToInsert: Set<BroadcastingCollectionTestContent> = [BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon]

        editableBroadcastingOrderedSet.add(elementsToInsert)

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.addObjects(from: Array(elementsToInsert))

        //  Using add only guarantees that the contents will contain the same afterwards and that there'll be a single insertion.
        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(modifiedSampleContent.set, contents.set)
        XCTAssertEqual(contents.count, sampleContent.count + elementsToInsert.count)
        XCTAssertEqual(testListener.listenerLog.count(of: "INSERT"), 2)    //  One each for WILL/DID
    }


    func testAdditionOfMultipleElementsSomeInContents() {
        let elementsToInsert: Set<BroadcastingCollectionTestContent> = [BroadcastingCollectionTestContent.sampleLeo, sampleContent[0]]

        editableBroadcastingOrderedSet.add(elementsToInsert)

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.addObjects(from: Array(elementsToInsert))

        //  Using add only guarantees that the contents will contain the same afterwards and that there'll be a single insertion.
        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(modifiedSampleContent.set, contents.set)
        XCTAssertEqual(contents.count, sampleContent.count + 1)
        XCTAssertEqual(testListener.listenerLog.count(of: "INSERT"), 2)    //  One each for WILL/DID
    }

    
    func testRemovalOfASingleElementAtIndex() {
        let indexToRemove = sampleContent.count / 2
        let elementToRemove = sampleContent[indexToRemove]

        editableBroadcastingOrderedSet.remove(from: indexToRemove)

        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(contents.count, sampleContent.count - 1)
        XCTAssertFalse(contents.contains(elementToRemove))

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.removeObject(at: Int(indexToRemove))

        XCTAssertEqual(modifiedSampleContent, contents)

        let removalElementsAtIndexes = IndexedElements(indexes: IndexSet(integer: Int(indexToRemove)), elements: [elementToRemove])
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willRemove: removalElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didRemove: removalElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testRemovalOfASingleElement() {
        let indexToRemove = sampleContent.count / 2
        let elementToRemove = sampleContent[indexToRemove]

        editableBroadcastingOrderedSet.remove(elementToRemove)

        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(contents.count, sampleContent.count - 1)
        XCTAssertFalse(contents.contains(elementToRemove))

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.removeObject(at: Int(indexToRemove))

        XCTAssertEqual(modifiedSampleContent, editableBroadcastingOrderedSet.contents)

        let removalElementsAtIndexes = IndexedElements(indexes: IndexSet(integer: Int(indexToRemove)), elements: [elementToRemove])
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willRemove: removalElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didRemove: removalElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }
    
    
    func testRemovalOfMultipleIndexes() {
        let contentsCount = sampleContent.count
        let indexesToRemove: IndexSet = [contentsCount / 3, contentsCount / 2]
        let elementsToRemove = (sampleContent as NSArray).objects(at: indexesToRemove) as! [BroadcastingCollectionTestContent]

        editableBroadcastingOrderedSet.remove(from: indexesToRemove)

        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(contents.count, sampleContent.count - indexesToRemove.count)
        XCTAssertFalse(contents.contains(elementsToRemove[0]))
        XCTAssertFalse(contents.contains(elementsToRemove[1]))

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.removeObjects(at: indexesToRemove)

        XCTAssertEqual(modifiedSampleContent, editableBroadcastingOrderedSet.contents)

        let removalElementsAtIndexes = IndexedElements(indexes: indexesToRemove, elements: elementsToRemove)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willRemove: removalElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didRemove: removalElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testRemovalOfMultipleElements() {
        let contentsCount = sampleContent.count
        let indexesToRemove: IndexSet = [contentsCount / 3, contentsCount / 2]
        let elementsToRemove = sampleContent[indexesToRemove]

        editableBroadcastingOrderedSet.remove(Set(elementsToRemove))

        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(contents.count, sampleContent.count - indexesToRemove.count)
        XCTAssertFalse(contents.contains(elementsToRemove[0]))
        XCTAssertFalse(contents.contains(elementsToRemove[1]))

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.removeObjects(at: indexesToRemove)

        XCTAssertEqual(modifiedSampleContent, editableBroadcastingOrderedSet.contents)

        let removalElementsAtIndexes = IndexedElements(indexes: indexesToRemove, elements: elementsToRemove)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willRemove: removalElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didRemove: removalElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }
    
    
    func testMoveItem() {
        let contentsCount = sampleContent.count
        let fromIndex = contentsCount / 3
        let toIndex = contentsCount / 2
        let elementToMove = sampleContent[fromIndex]

        editableBroadcastingOrderedSet.move(from: fromIndex, to: toIndex)

        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(contents.count, sampleContent.count)
        XCTAssertFalse(contents[fromIndex] as! BroadcastingCollectionTestContent == elementToMove)
        XCTAssertEqual(contents[toIndex] as! BroadcastingCollectionTestContent, elementToMove)

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.moveObjects(at: IndexSet(integer: fromIndex), to: toIndex)

        XCTAssertEqual(modifiedSampleContent, editableBroadcastingOrderedSet.contents)

        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willMove: elementToMove, from: fromIndex, to: toIndex)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didMove: elementToMove, from: fromIndex, to: toIndex)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testReplaceSingleElement() {
        let indexToReplace = sampleContent.count / 2
        let replaceeElement = sampleContent[indexToReplace]
        let replacementElement = BroadcastingCollectionTestContent.sampleLeo

        editableBroadcastingOrderedSet.replace(from: indexToReplace, with: replacementElement)

        let contents = editableBroadcastingOrderedSet.contents
        XCTAssert(contents.count == sampleContent.count)
        XCTAssertFalse(contents.contains(replaceeElement))
        XCTAssert(contents[indexToReplace] as! BroadcastingCollectionTestContent == replacementElement)

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.replaceObject(at: Int(indexToReplace), with: replacementElement)

        XCTAssert(modifiedSampleContent == contents)

        let replaceeElementsAtIndexes = IndexedElements(indexes: [indexToReplace], elements: [replaceeElement])
        let replacementElementsAtIndexes = IndexedElements(indexes: [indexToReplace], elements: [replacementElement])
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    @discardableResult func _multipleReplacementTest(at indexes: IndexSet, with replacement: NSOrderedSet) -> NSOrderedSet {
        let validatedParameters = editableBroadcastingOrderedSet._validateReplacement(of: indexes, with: replacement)

        let replaceeElements = NSOrderedSet(array: editableBroadcastingOrderedSet.contents.array[validatedParameters.validatedIndexes] as! [BroadcastingCollectionTestContent])

        editableBroadcastingOrderedSet.replace(from: indexes, with: replacement)

        let contents = editableBroadcastingOrderedSet.contents
        XCTAssertEqual(contents.count, sampleContent.count)
        XCTAssertEqual(contents.objects(at: indexes) as! [BroadcastingCollectionTestContent], replacement.array as! [BroadcastingCollectionTestContent])

        let modifiedSampleContent = NSMutableOrderedSet(array: sampleContent)
        modifiedSampleContent.replaceObjects(at: indexes, with: replacement.array)

        XCTAssertEqual(modifiedSampleContent, contents)

        let replaceeElementsAtIndexes = IndexedElements(indexes: validatedParameters.validatedIndexes, elements: replaceeElements.array as! [BroadcastingCollectionTestContent])
        let replacementElementsAtIndexes = IndexedElements(indexes: validatedParameters.validatedIndexes, elements: validatedParameters.validatedElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)

        return replaceeElements
    }


    func testReplaceMultipleElementsOrthogonal() {
        let sampleContentCount = sampleContent.count
        let indexesToReplace: IndexSet = [sampleContentCount / 3, sampleContentCount / 2]
        let replacementElements = NSOrderedSet(array: [BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon])

        let replacees = _multipleReplacementTest(at: indexesToReplace, with: replacementElements)

        XCTAssert(editableBroadcastingOrderedSet.contents.set.isDisjoint(with: replacees.set))
    }


    func testReplaceMultipleElementsMixed() {
        let sampleContentCount = sampleContent.count
        let indexesToReplace: IndexSet = [sampleContentCount / 3, sampleContentCount / 2]

        let commonElement = editableBroadcastingOrderedSet.contents[indexesToReplace.first!] as! BroadcastingCollectionTestContent
        let replacement = NSOrderedSet(array: [commonElement, BroadcastingCollectionTestContent.sampleLeo])

        let replacees = _multipleReplacementTest(at: indexesToReplace, with: replacement)

        let intersection = replacement.set.intersection(replacees.set)
        XCTAssertTrue(intersection.isEmpty)
    }
}
