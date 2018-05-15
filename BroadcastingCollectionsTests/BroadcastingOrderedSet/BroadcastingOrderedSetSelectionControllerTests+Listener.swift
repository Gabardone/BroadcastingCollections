//
//  BroadcastingOrderedSetSelectionControllerTests+Listener.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation
import XCTest


extension BroadcastingOrderedSetSelectionControllerTests {

    func testInsertionOfElementsBeforeSingleSelection() {
        let sampleContentCount = sampleContent.count
        let initialSelection = IndexSet(integer: sampleContentCount / 2)
        selectionController.selectedIndexes = initialSelection

        clearNotificationData()
        
        editableBroadcastingOrderedSet.insert(BroadcastingCollectionTestContent.sampleLeo, at: 0)

        let expectedFinalSelection = IndexSet(arrayLiteral: sampleContentCount / 2 + 1)
        XCTAssertEqual(selectionController.selectedIndexes, expectedFinalSelection)
        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, expectedFinalSelection)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")  //  No changes in selected elements.
    }


    func testInsertionOfElementsBeforeMultipleSelection() {
        selectionController.allowsMultipleSelection = true
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection

        clearNotificationData()

        editableBroadcastingOrderedSet.insert(BroadcastingCollectionTestContent.sampleLeo, at: 0)

        let expectedFinalSelection = IndexSet(arrayLiteral: halfPoint + 1, halfPoint + 3)
        XCTAssertEqual(selectionController.selectedIndexes, expectedFinalSelection)
        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, expectedFinalSelection)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")  //  No changes in selected elements.
    }
    
    
    func testInsertionOfElementsInBetweenMultipleSelection() {
        selectionController.allowsMultipleSelection = true
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection

        clearNotificationData()

        editableBroadcastingOrderedSet.insert(BroadcastingCollectionTestContent.sampleLeo, at: halfPoint + 1)

        let expectedFinalSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 3)
        XCTAssertEqual(selectionController.selectedIndexes, expectedFinalSelection)
        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, expectedFinalSelection)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")  //  No changes in selected elements.
    }
    
    
    func testInsertionOfElementsAfterSelection() {
        let sampleContentCount = sampleContent.count
        let initialSelection = IndexSet(arrayLiteral: sampleContentCount / 2)
        selectionController.selectedIndexes = initialSelection

        clearNotificationData()

        editableBroadcastingOrderedSet.insert(BroadcastingCollectionTestContent.sampleLeo, at: sampleContentCount - 2)

        //  Both of these false means nothing happened.
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")  //  No changes in selected elements.
        XCTAssertFalse(selectedIndexesDidChange)
    }


    func testInsertionOfElementsOnEmptyControllerNoEmptySelectionAllowed() {
        //  Clear the contents.
        editableBroadcastingOrderedSet.contents = NSOrderedSet()
        clearNotificationData()

        //  Set up some new content.
        let firstElementToInsert = BroadcastingCollectionTestContent.sampleLeo
        let secondElementToInsert = BroadcastingCollectionTestContent.sampleBanon
        let insertionElements: NSOrderedSet = [firstElementToInsert, secondElementToInsert]

        //  Insert that new content (equivalent to insertion)
        editableBroadcastingOrderedSet.insert(insertionElements, at: IndexSet(integersIn: 0 ..< insertionElements.count))

        let finalSelection = Set(arrayLiteral: insertionElements[0] as! BroadcastingCollectionTestContent)
        XCTAssertEqual(outgoingSelectedIndexes, IndexSet())
        XCTAssertEqual(incomingSelectedIndexes, IndexSet(arrayLiteral: 0))
        XCTAssertEqual(selectionController.selectedElements, finalSelection)

        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willAdd: finalSelection)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didAdd: finalSelection)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }


    func testRemovalOfElementsBeforeSingleSelection() {
        let sampleContentCount = sampleContent.count
        let initialSelection = IndexSet(arrayLiteral: sampleContentCount / 2)
        selectionController.selectedIndexes = initialSelection

        clearNotificationData()

        editableBroadcastingOrderedSet.remove(from: IndexSet(integersIn: 0 ..< 2))

        let expectedFinalSelection = IndexSet(arrayLiteral: sampleContentCount / 2 - 2)
        XCTAssertEqual(selectionController.selectedIndexes, expectedFinalSelection)
        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, expectedFinalSelection)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")  //  No changes in selected elements.
    }


    func testRemovalOfElementsBeforeMultipleSelection() {
        selectionController.allowsMultipleSelection = true
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection

        clearNotificationData()

        editableBroadcastingOrderedSet.remove(from: IndexSet(integersIn: 0 ..< 2))

        let expectedFinalSelection = IndexSet(arrayLiteral: halfPoint - 2, halfPoint)
        XCTAssertEqual(selectionController.selectedIndexes, expectedFinalSelection)
        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, expectedFinalSelection)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")  //  No changes in selected elements.
    }
    
    
    func testRemovalOfElementsInBetweenMultipleSelection() {
        selectionController.allowsMultipleSelection = true
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet([halfPoint, halfPoint + 2])
        selectionController.selectedIndexes = initialSelection
        let initialSelectedElements = selectionController.selectedElements

        clearNotificationData()

        editableBroadcastingOrderedSet.remove(from: IndexSet(arrayLiteral: halfPoint - 1, halfPoint + 1))

        let expectedFinalSelection = IndexSet(arrayLiteral: halfPoint - 1, halfPoint)
        XCTAssertEqual(selectionController.selectedIndexes, expectedFinalSelection)
        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, expectedFinalSelection)
        XCTAssertEqual(selectionController.selectedElements, initialSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")  //  No changes in selected elements.
    }


    func testRemovalOfElementsAfterSelection() {
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint)
        selectionController.selectedIndexes = initialSelection

        clearNotificationData()

        editableBroadcastingOrderedSet.remove(from: IndexSet(integersIn: halfPoint + 1 ..< halfPoint + 3))

        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")  //  No changes in selected elements.
        XCTAssertFalse(selectedIndexesDidChange)
    }


    func testRemovalOfWholeSelectionEmptySelectionAllowed() {
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection
        let initialSelectedElements = selectionController.selectedElements

        clearNotificationData()

        editableBroadcastingOrderedSet.remove(from: IndexSet(integersIn: halfPoint - 2 ..< halfPoint + 3))

        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, IndexSet())

        XCTAssertEqual(selectionController.broadcastingSelectedElements.contents, Set<BroadcastingCollectionTestContent>())

        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willRemove: initialSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didRemove: initialSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }


    func testRemovalOfSelectionNoEmptySelectionAllowed() {
        selectionController.allowsEmptySelection = false
        selectionController.allowsMultipleSelection = true
        selectionController.selectsPriorOnRemoval = false
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection
        let initialSelectedElements = selectionController.selectedElements
        let finalSelectedElements = Set([sampleContent[halfPoint + 3]])

        clearNotificationData()

        editableBroadcastingOrderedSet.remove(from: IndexSet(integersIn: halfPoint - 2 ..< halfPoint + 3))

        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, IndexSet(arrayLiteral: halfPoint - 2))
        XCTAssertEqual(selectionController.broadcastingSelectedElements.contents, finalSelectedElements)

        sampleSelectedElementChangeListener.broadcastingSetWillBeginTransactions(selectionController.broadcastingSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willRemove: initialSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didRemove: initialSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willAdd: finalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didAdd: finalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSetDidEndTransactions(selectionController.broadcastingSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }


    func testRemovalOfSelectionNoEmptySelectionAllowedAndSelectsPriorOnRemoval() {
        selectionController.allowsEmptySelection = false
        selectionController.allowsMultipleSelection = true
        selectionController.selectsPriorOnRemoval = true
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection
        let initialSelectedElements = selectionController.selectedElements
        let finalSelectedElements = Set([sampleContent[halfPoint - 3]])

        clearNotificationData()

        editableBroadcastingOrderedSet.remove(from: IndexSet(integersIn: halfPoint - 2 ..< halfPoint + 3))

        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, IndexSet(arrayLiteral: halfPoint - 3))
        XCTAssertEqual(selectionController.broadcastingSelectedElements.contents, finalSelectedElements)

        sampleSelectedElementChangeListener.broadcastingSetWillBeginTransactions(selectionController.broadcastingSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willRemove: initialSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didRemove: initialSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willAdd: finalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didAdd: finalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSetDidEndTransactions(selectionController.broadcastingSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }


    func testMoveOfElementBeforeSelection() {
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        editableBroadcastingOrderedSet.move(from: 0, to: halfPoint - 3)

        XCTAssertEqual(outgoingSelectedIndexes, nil)
        XCTAssertEqual(incomingSelectedIndexes, nil)
        XCTAssertEqual(selectionController.selectedElements, originalSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")
    }


    func testMoveOfElementAfterSelection() {
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let sampleContentCount = sampleContent.count
        let halfPoint = sampleContentCount / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        editableBroadcastingOrderedSet.move(from: halfPoint + 3, to: sampleContentCount - 1)

        XCTAssertEqual(outgoingSelectedIndexes, nil)
        XCTAssertEqual(incomingSelectedIndexes, nil)
        XCTAssertEqual(selectionController.selectedElements, originalSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")
    }


    func testMoveOfElementBeforeToAfter() {
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let sampleContentCount = sampleContent.count
        let halfPoint = sampleContentCount / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        editableBroadcastingOrderedSet.move(from: 0, to: sampleContentCount - 1)

        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, IndexSet(arrayLiteral: halfPoint - 1, halfPoint + 1))
        XCTAssertEqual(selectionController.selectedElements, originalSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")
    }


    func testMoveOfElementAfterToBefore() {
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let sampleContentCount = sampleContent.count
        let halfPoint = sampleContentCount / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        editableBroadcastingOrderedSet.move(from: sampleContentCount - 1, to: 0)

        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, IndexSet(arrayLiteral: halfPoint + 1, halfPoint + 3))
        XCTAssertEqual(selectionController.selectedElements, originalSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")
    }


    func testMoveOfElementInBetween() {
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        editableBroadcastingOrderedSet.move(from: 0, to: halfPoint + 1)

        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, IndexSet(arrayLiteral: halfPoint - 1, halfPoint + 2))
        XCTAssertEqual(selectionController.selectedElements, originalSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")
    }


    func testMoveOfSelectedElement() {
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        editableBroadcastingOrderedSet.move(from: halfPoint + 2, to: 0)

        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, IndexSet(arrayLiteral: 0, halfPoint + 1))
        XCTAssertEqual(selectionController.selectedElements, originalSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")
    }


    func testReplaceOfNonSelectedElements() {
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet([halfPoint, halfPoint + 2])
        selectionController.selectedIndexes = initialSelection
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        editableBroadcastingOrderedSet.replace(from: 0, with: BroadcastingCollectionTestContent.sampleLeo)

        XCTAssertEqual(outgoingSelectedIndexes, nil)
        XCTAssertEqual(incomingSelectedIndexes, nil)
        XCTAssertEqual(selectionController.selectedElements, originalSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")
    }


    func testReplaceOfAllSelectedElements() {
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection
        let initialSelectedElements = Set<BroadcastingCollectionTestContent>(initialSelection.map({ (index) -> BroadcastingCollectionTestContent in
            return sampleContent[index]
        }))

        clearNotificationData()

        let replacements = NSOrderedSet(objects: BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleGestalt)
        let finalSelectedElements = replacements.set as! Set<BroadcastingCollectionTestContent>

        editableBroadcastingOrderedSet.replace(from: initialSelection, with: replacements)

        XCTAssertEqual(outgoingSelectedIndexes, nil)
        XCTAssertEqual(incomingSelectedIndexes, nil)
        XCTAssertEqual(selectionController.broadcastingSelectedElements.contents, finalSelectedElements)

        sampleSelectedElementChangeListener.broadcastingSetWillBeginTransactions(selectionController.broadcastingSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willRemove: initialSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didRemove: initialSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willAdd: finalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didAdd: finalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSetDidEndTransactions(selectionController.broadcastingSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }


    func testReplaceOfSomeSelectedElements() {
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let halfPoint = sampleContent.count / 2
        let initialSelection = IndexSet(arrayLiteral: halfPoint, halfPoint + 2)
        selectionController.selectedIndexes = initialSelection
        let initialSelectedElements = Set<BroadcastingCollectionTestContent>(initialSelection.map({ (index) -> BroadcastingCollectionTestContent in
            return sampleContent[index]
        }))

        clearNotificationData()

        let replacement = BroadcastingCollectionTestContent.sampleLeo
        let removedSelectedElements = Set([sampleContent[halfPoint]])
        let insertedSelectedElements = Set([replacement])

        editableBroadcastingOrderedSet.replace(sampleContent[halfPoint], with: BroadcastingCollectionTestContent.sampleLeo)

        XCTAssertEqual(outgoingSelectedIndexes, nil)
        XCTAssertEqual(incomingSelectedIndexes, nil)
        XCTAssertEqual(selectionController.broadcastingSelectedElements.contents, initialSelectedElements.subtracting(removedSelectedElements).union(insertedSelectedElements))

        sampleSelectedElementChangeListener.broadcastingSetWillBeginTransactions(selectionController.broadcastingSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willRemove: removedSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didRemove: removedSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willAdd: insertedSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didAdd: insertedSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSetDidEndTransactions(selectionController.broadcastingSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }
}
