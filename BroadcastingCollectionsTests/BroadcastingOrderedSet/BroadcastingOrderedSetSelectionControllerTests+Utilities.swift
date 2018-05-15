//
//  BroadcastingOrderedSetSelectionControllerTests+Utilities.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation
import XCTest


extension BroadcastingOrderedSetSelectionControllerTests {

    func testCanSelectElements() {
        //  Test that it returns no when attempting to select elements not there.
        XCTAssertFalse(selectionController.canSelect(Set<BroadcastingCollectionTestContent>(arrayLiteral: BroadcastingCollectionTestContent.sampleLeo)))

        //  Test that it returns false when attempting to empty selection and it is not allowed.
        selectionController.allowsEmptySelection = false
        XCTAssertFalse(selectionController.canSelect(Set()))

        //  Test that it returns false when attempting to select multiple and it is not allowed.
        selectionController.allowsMultipleSelection = false
        XCTAssertFalse(selectionController.canSelect(Set<BroadcastingCollectionTestContent>(arrayLiteral: BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent(number: 19, string: "2B"))))
    }


    func testCanSelectPrevious() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true

        //  Start by setting a multiple selection.
        selectionController.selectedIndexes = IndexSet(integersIn: 2..<5)

        XCTAssertFalse(selectionController.canSelectPrevious)

        //  Now select nothing.
        selectionController.selectedElements = Set()

        XCTAssert(selectionController.canSelectPrevious)

        //  Select the first element with looping enabled.
        selectionController.loopsSelection = true
        selectionController.selectedIndexes = IndexSet(arrayLiteral: 0)

        XCTAssert(selectionController.canSelectPrevious)

        //  Now verify that with looping selection off it won't allow to select previous.
        selectionController.loopsSelection = false

        XCTAssertFalse(selectionController.canSelectPrevious)
    }


    func testSelectPrevious() {
        let initialSelection = IndexSet(arrayLiteral: 7)
        selectionController.selectedIndexes = initialSelection

        clearNotificationData()

        selectionController.selectPrevious()

        let expectedFinalSelection = IndexSet(arrayLiteral: 6)
        XCTAssert(selectionController.selectedIndexes == expectedFinalSelection, "selectNext didn't select the next item")
        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, expectedFinalSelection)
    }


    func testSelectPreviousNoPriorSelection() {
        selectionController.allowsEmptySelection = true
        let initialSelection = IndexSet()
        selectionController.selectedIndexes = initialSelection

        clearNotificationData()

        selectionController.selectPrevious()

        let expectedFinalSelection: IndexSet = [sampleContent.count - 1]
        XCTAssert(selectionController.selectedIndexes == expectedFinalSelection, "selectNext didn't select the next item")
        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, expectedFinalSelection)
    }


    func testSelectPreviousLoopSelection() {
        selectionController.loopsSelection = true
        let initialSelection = IndexSet(arrayLiteral: 0)
        selectionController.selectedIndexes = initialSelection

        clearNotificationData()

        selectionController.selectPrevious()

        let expectedFinalSelection: IndexSet = [sampleContent.count - 1]
        XCTAssert(selectionController.selectedIndexes == expectedFinalSelection, "selectNext didn't select the next item")
        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, expectedFinalSelection)
    }


    func testCanSelectNext() {
        //  Ensure selection controller is properly configured.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true

        //  Start by setting a multiple selection.
        selectionController.selectedIndexes = IndexSet(integersIn: 2..<5)

        XCTAssertFalse(selectionController.canSelectNext)

        //  Now select nothing.
        selectionController.selectedElements = Set()

        XCTAssert(selectionController.canSelectNext)

        //  Select the last element with looping enabled.
        selectionController.loopsSelection = true
        selectionController.selectedIndexes = [sampleContent.count - 1]

        XCTAssert(selectionController.canSelectNext)

        //  Now verify that with looping selection off it won't allow to select next.
        selectionController.loopsSelection = false

        XCTAssertFalse(selectionController.canSelectNext)
    }


    func testSelectNext() {
        let initialSelection = IndexSet(arrayLiteral: 1)
        selectionController.selectedIndexes = initialSelection

        clearNotificationData()

        selectionController.selectNext()

        let expectedFinalSelection = IndexSet(arrayLiteral: 2)
        XCTAssert(selectionController.selectedIndexes == expectedFinalSelection, "selectNext didn't select the next item")
        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, expectedFinalSelection)
    }


    func testSelectNextNoPriorSelection() {
        selectionController.allowsEmptySelection = true
        let initialSelection = IndexSet()
        selectionController.selectedIndexes = initialSelection

        clearNotificationData()

        selectionController.selectNext()

        let expectedFinalSelection = IndexSet(arrayLiteral: 0)
        XCTAssert(selectionController.selectedIndexes == expectedFinalSelection, "selectNext didn't select the next item")
        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, expectedFinalSelection)
    }


    func testSelectNextLoopSelection() {
        selectionController.loopsSelection = true
        let initialSelection: IndexSet = [sampleContent.count - 1]
        selectionController.selectedIndexes = initialSelection

        clearNotificationData()

        selectionController.selectNext()

        let expectedFinalSelection = IndexSet(arrayLiteral: 0)
        XCTAssert(selectionController.selectedIndexes == expectedFinalSelection, "selectNext didn't select the next item")
        XCTAssertEqual(outgoingSelectedIndexes, initialSelection)
        XCTAssertEqual(incomingSelectedIndexes, expectedFinalSelection)
    }
}
