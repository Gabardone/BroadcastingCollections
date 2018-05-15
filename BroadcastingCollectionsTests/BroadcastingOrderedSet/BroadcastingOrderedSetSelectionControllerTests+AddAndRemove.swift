//
//  BroadcastingOrderedSetSelectionControllerTests+AddAndRemove.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation
import BroadcastingCollections
import XCTest


extension BroadcastingOrderedSetSelectionControllerTests {
    
    func testAddElementsToSelection() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        selectionController.selectedIndexes = IndexSet(integersIn: 2..<5)
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        //  We include an element that is already selected, it shouldn't affect the method.
        let additionalSelectedElements = Set(arrayLiteral: sampleContent[3], sampleContent[7], sampleContent[9])
        let finalSelectedElements = originalSelectedElements.union(additionalSelectedElements)
        let actuallyAddedSelectedElements = finalSelectedElements.subtracting(originalSelectedElements)

        selectionController.addElementsToSelection(additionalSelectedElements)

        XCTAssertEqual(selectionController.broadcastingSelectedElements.contents, finalSelectedElements)

        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willAdd: actuallyAddedSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didAdd: actuallyAddedSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }


    func testAddElementsToSelectionAlreadySelectedDoesNothing() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        selectionController.selectedIndexes = IndexSet(integersIn: 2..<5)
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        //  We only include already selected elements.
        let additionalSelectedElements = Set([sampleContent[2], sampleContent[4]])

        selectionController.addElementsToSelection(additionalSelectedElements)

        XCTAssertEqual(selectionController.broadcastingSelectedElements.contents, originalSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")
    }


    func testRemoveAllElementsFromSelection() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        selectionController.selectedIndexes = IndexSet(integersIn: 2..<5)
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        //  We only include already selected elements.
        let selectedElementsToRemove = Set([sampleContent[2], sampleContent[3], sampleContent[4]])

        selectionController.removeElementsFromSelection(selectedElementsToRemove)

        XCTAssertEqual(selectionController.selectedElements, Set<BroadcastingCollectionTestContent>())

        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willRemove: originalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didRemove: originalSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }


    func testRemoveSomeElementsFromSelection() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        selectionController.selectedIndexes = IndexSet(integersIn: 2..<5)
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        //  We only include already selected elements.
        let selectedElementsToRemove = Set([sampleContent[2], sampleContent[4]])

        selectionController.removeElementsFromSelection(selectedElementsToRemove)

        XCTAssertEqual(selectionController.selectedElements, originalSelectedElements.subtracting(selectedElementsToRemove))

        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willRemove: selectedElementsToRemove)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didRemove: selectedElementsToRemove)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }


    func testAddIndexesToSelection() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let originalSelectedIndexes = IndexSet(integersIn: 2..<5)
        selectionController.selectedIndexes = originalSelectedIndexes

        clearNotificationData()

        //  We include already selected elements and a few more for kicks.
        let indexesToAdd = IndexSet(arrayLiteral: 1, 2, 4, 5, 7, 9)

        selectionController.addIndexesToSelection(indexesToAdd)

        XCTAssertEqual(outgoingSelectedIndexes, originalSelectedIndexes, "Outgoing selected indexes are not the same that were originally in the selection controller")
        XCTAssertEqual(incomingSelectedIndexes, originalSelectedIndexes.union(indexesToAdd), "Incoming selected indexes are not the expected")
    }


    func testAddIndexesToSelectionAlreadySelectedDoesNothing() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let originalSelectedIndexes = IndexSet(integersIn: 2..<5)
        selectionController.selectedIndexes = originalSelectedIndexes
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        //  We include already selected elements and a few more for kicks.
        let indexesToAdd = IndexSet(arrayLiteral: 2, 4)

        selectionController.addIndexesToSelection(indexesToAdd)

        XCTAssertEqual(selectionController.broadcastingSelectedElements.contents, originalSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, "")
    }


    func testRemoveAllIndexesFromSelection() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let originalSelectedIndexes = IndexSet(integersIn: 2..<5)
        selectionController.selectedIndexes = originalSelectedIndexes

        clearNotificationData()

        //  We include already selected elements and a few more for kicks.
        let indexesToRemove = IndexSet(arrayLiteral: 1, 2, 3, 4, 5, 7, 9)

        selectionController.removeIndexesFromSelection(indexesToRemove)

        XCTAssertEqual(outgoingSelectedIndexes, originalSelectedIndexes, "Outgoing selected indexes are not the same that were originally in the selection controller")
        XCTAssertEqual(incomingSelectedIndexes, IndexSet(), "Incoming selected indexes are not an empty set")
    }


    func testRemoveSomeIndexesFromSelection() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let originalSelectedIndexes = IndexSet(integersIn: 2..<5)
        selectionController.selectedIndexes = originalSelectedIndexes

        clearNotificationData()

        //  We include already selected elements and a few more for kicks.
        let indexesToRemove = IndexSet(arrayLiteral: 2, 4, 7, 9)

        selectionController.removeIndexesFromSelection(indexesToRemove)
        
        XCTAssertEqual(outgoingSelectedIndexes, originalSelectedIndexes, "Outgoing selected indexes are not the same that were originally in the selection controller")
        XCTAssertEqual(incomingSelectedIndexes, originalSelectedIndexes.subtracting(indexesToRemove), "Incoming selected indexes are not the expected")
    }
}
