//
//  BroadcastingOrderedSetSelectionControllerErrorTests.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


class BroadcastingOrderedSetSelectionControllerErrorTests: BroadcastingOrderedSetSelectionControllerTestCase {

    override func setUp() {
        super.setUp()

        //  Make sure we turn testing mode on.
        ErrorReporter.testingMode = true
        ErrorReporter.testingLog = ""
    }


    override func tearDown() {
        ErrorReporter.testingMode = false
        ErrorReporter.testingLog = ""

        super.tearDown()
    }


    func testAttemptingToSelectObjectNotInRepublishedContentsCausesError() {
        let fakeSelectedElements = Set([BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon])
        selectionController.selectedElements = fakeSelectedElements

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testSelectingPreviousWhileUnableCausesError() {
        //  Set the selection controller up without looping or other options.
        let selectionController = self.selectionController
        selectionController.loopsSelection = false
        selectionController.allowsEmptySelection = false
        selectionController.allowsMultipleSelection = false

        //  Make sure the first element is selected.
        selectionController.selectedIndexes = IndexSet(integer: 0)

        //  Attempt to select previous.
        selectionController.selectPrevious()

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testSelectingPreviousWithMultipleSelectionCausesError() {
        //  Set the selection controller up without looping or other options.
        let selectionController = self.selectionController
        selectionController.loopsSelection = false
        selectionController.allowsEmptySelection = false
        selectionController.allowsMultipleSelection = true

        //  Make sure the first element is selected.
        selectionController.selectedIndexes = IndexSet(integersIn: 2 ..< 4)

        //  Attempt to select previous.
        selectionController.selectPrevious()

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testSelectingNextWhileUnableCausesError() {
        //  Set the selection controller up without looping or other options.
        let selectionController = self.selectionController
        selectionController.loopsSelection = false
        selectionController.allowsEmptySelection = false
        selectionController.allowsMultipleSelection = false

        //  Make sure the first element is selected.
        selectionController.selectedIndexes = IndexSet(integer: selectionController.republishedBroadcastingOrderedSet!.contents.count - 1)

        //  Attempt to select previous.
        selectionController.selectNext()

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testSelectingNextWithMultipleSelectionCausesError() {
        //  Set the selection controller up without looping or other options.
        let selectionController = self.selectionController
        selectionController.loopsSelection = false
        selectionController.allowsEmptySelection = false
        selectionController.allowsMultipleSelection = true

        //  Make sure the first element is selected.
        selectionController.selectedIndexes = IndexSet(integersIn: 2 ..< 4)

        //  Attempt to select previous.
        selectionController.selectNext()

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }
}
