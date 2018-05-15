//
//  BroadcastingOrderedSetSelectionControllerTests+Configuration.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import Foundation
import XCTest


extension BroadcastingOrderedSetSelectionControllerTests {

    func testReplacingContentsWithNilRemovesSelection() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        selectionController.selectedIndexes = IndexSet(integersIn: 2..<5)
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        selectionController.republishedBroadcastingOrderedSet = nil

        XCTAssert(selectionController.selectedElements.isEmpty)

        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willRemove: originalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didRemove: originalSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }
    
    
    func testReplacingContentsRemovesSelection() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        selectionController.selectedIndexes = IndexSet(integersIn: 2..<5)
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        let replacementContents = NSOrderedSet(array: [BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon])
        let replacementRepublished = EditableBroadcastingOrderedSet<BroadcastingCollectionTestContent>()
        replacementRepublished.contents = replacementContents

        selectionController.republishedBroadcastingOrderedSet = replacementRepublished

        XCTAssert(selectionController.selectedElements.isEmpty)

        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willRemove: originalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didRemove: originalSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }


    func testReplacingContentWithNoAllowedEmptySelectionSelectsFirstReplacement() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = false
        selectionController.allowsMultipleSelection = true
        selectionController.selectedIndexes = IndexSet(integersIn: 2..<5)
        let originalSelectedElements = selectionController.selectedElements

        clearNotificationData()

        let replacementContents = NSOrderedSet(array: [BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon])
        let replacementRepublished = EditableBroadcastingOrderedSet<BroadcastingCollectionTestContent>()
        replacementRepublished.contents = replacementContents

        selectionController.republishedBroadcastingOrderedSet = replacementRepublished

        let finalSelectedElements = Set([replacementContents.firstObject as! BroadcastingCollectionTestContent])
        XCTAssertEqual(selectionController.selectedElements, finalSelectedElements)

        sampleSelectedElementChangeListener.broadcastingSetWillBeginTransactions(selectionController.broadcastingSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willRemove: originalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didRemove: originalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willAdd: finalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didAdd: finalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSetDidEndTransactions(selectionController.broadcastingSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }


    func testTurningOffAllowsEmptySelectionSelectsFirstItem() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true

        clearNotificationData()

        selectionController.allowsEmptySelection = false

        let finalSelectedElements = Set([selectionController.republishedBroadcastingOrderedSet![0]])
        XCTAssertEqual(selectionController.selectedElements, finalSelectedElements)

        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willAdd: finalSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didAdd: finalSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }


    func testTurningOffAllowsMultipleSelectionDeselectsEverythingButLowestSelectedIndex() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true
        let originalSelectedIndexes = IndexSet(integersIn: 2..<5)
        selectionController.selectedIndexes = originalSelectedIndexes
        let originalSelectedElements = selectionController.selectedElements
        let finalSelectedElements = Set([sampleContent[2]])
        let removedSelectedElements = originalSelectedElements.subtracting(finalSelectedElements)

        clearNotificationData()

        selectionController.allowsMultipleSelection = false

        XCTAssertEqual(selectionController.selectedElements, finalSelectedElements)

        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, willRemove: removedSelectedElements)
        sampleSelectedElementChangeListener.broadcastingSet(selectionController.broadcastingSelectedElements, didRemove: removedSelectedElements)
        XCTAssertEqual(selectedElementChangeListener.listenerLog, sampleSelectedElementChangeListener.listenerLog)
    }
}
