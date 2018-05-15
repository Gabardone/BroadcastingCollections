//
//  EditableBroadcastingOrderedSetErrorTests.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation
import BroadcastingCollections
import XCTest


//  Note that we're only testing issues that we check for ourselves. Other caller errors like trying to insert out of
//  bounds will blow up normally.
class EditableBroadcastingOrderedSetErrorTests: EditableBroadcastingOrderedSetTestCase {

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


    func testThatSettingContentsWithDifferentCountOfReplaceesAndReplacementsCausesError() {
        //  We send one replacee index, two replacement elements.
        let replaceeIndexes = IndexSet(integer: 0)

        let finalContents = NSMutableOrderedSet(array: sampleContent)
        finalContents[0] = BroadcastingCollectionTestContent(number: 1, string: "Terra")
        finalContents[6] = BroadcastingCollectionTestContent(number: 7, string: "Cyan")

        let realReplaceeIndexes = IndexSet([0, 6])
        let replacementElements = NSOrderedSet(array: realReplaceeIndexes.map({ (index) -> BroadcastingCollectionTestContent in
            return finalContents[index] as! BroadcastingCollectionTestContent
        }))

        editableBroadcastingOrderedSet.set(finalContents, replacing: replaceeIndexes, with: replacementElements)

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testThatSettingContentsWithReplacementElementsNotInFinalContentsCausesError() {
        //  replacementElements is not contained in the finalContents
        let replaceeIndexes = IndexSet(integer: 0)

        let finalContents = NSMutableOrderedSet(array: sampleContent)
        finalContents[0] = BroadcastingCollectionTestContent(number: 1, string: "Terra")

        let replacementElements = NSOrderedSet(object: BroadcastingCollectionTestContent.sampleLeo)

        editableBroadcastingOrderedSet.set(finalContents, replacing: replaceeIndexes, with: replacementElements)

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testThatSettingContentsWithReplacementElementsAlreadyInContentsCausesError() {
        let replaceeIndexes = IndexSet(integer: 0)

        let finalContents = NSMutableOrderedSet(array: sampleContent)
        finalContents[0] = BroadcastingCollectionTestContent(number: 1, string: "Terra")

        let replacementElements = NSOrderedSet(object: sampleContent[1])

        editableBroadcastingOrderedSet.set(finalContents, replacing: replaceeIndexes, with: replacementElements)

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testInsertionOfAlreadyExistingElementAtDifferentIndexCausesError() {
        editableBroadcastingOrderedSet.insert(sampleContent[0], at: 1)

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testInsertionOfAlreadyExistingElementAtSameIndexDoesNotCauseError() {
        editableBroadcastingOrderedSet.insert(sampleContent[7], at: 7)

        //  Assert that we did not get stuff in the error reporter log.
        XCTAssertTrue(ErrorReporter.testingLog.isEmpty)
    }


    func testInsertionOfAlreadyExistingElementsAtDifferentIndexesCausesError() {
        let sampleContentCount = sampleContent.count
        let insertionElements = NSOrderedSet(array: Array<BroadcastingCollectionTestContent>(sampleContent[(sampleContentCount / 3) ..< (sampleContentCount / 2)]))

        editableBroadcastingOrderedSet.insert(insertionElements, at: IndexSet(integersIn: 0 ..< sampleContentCount / 2))

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testInsertionOfAlreadyExistingElementsAtSameIndexesDoesNotCauseError() {
        let sampleContentCount = sampleContent.count
        let insertionRange = sampleContentCount / 3 ..< sampleContentCount / 2
        let insertionElements = NSOrderedSet(array: Array<BroadcastingCollectionTestContent>(sampleContent[insertionRange]))

        editableBroadcastingOrderedSet.insert(insertionElements, at: IndexSet(integersIn: insertionRange))

        //  Assert that we did not get stuff in the error reporter log.
        XCTAssertTrue(ErrorReporter.testingLog.isEmpty)
    }


    func testReplacementOfExistingItemAtDifferentIndexCausesError() {
        editableBroadcastingOrderedSet.replace(from: 0, with: sampleContent[7])

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testReplacementOfExistingItemAtSameIndexDoesNotCauseError() {
        editableBroadcastingOrderedSet.replace(from: 0, with: sampleContent[0])

        //  Assert that we did not get stuff in the error reporter log.
        XCTAssertTrue(ErrorReporter.testingLog.isEmpty)
    }


    func testReplacementOfDifferentCountOfIndexesAndReplacementsCausesError() {
        //  One replacee, two replacements.
        let replaceeIndexes = IndexSet(integer: 0)
        let fakeReplacements = NSOrderedSet(array: [BroadcastingCollectionTestContent.sampleKefka, BroadcastingCollectionTestContent.sampleGestalt])

        editableBroadcastingOrderedSet.replace(from: replaceeIndexes, with: fakeReplacements)

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testReplacementOfAlreadyExistingElementsAtNonReplacedIndexesCausesError() {
        let sampleContentCount = sampleContent.count
        let replacementRange = sampleContentCount / 3 ..< sampleContentCount / 2
        let replacementElements = NSOrderedSet(array: sampleContent, range: NSRange(location: replacementRange.startIndex, length: replacementRange.distance(from: replacementRange.startIndex, to: replacementRange.endIndex)), copyItems: false)
        var replacementIndexSet = IndexSet(integersIn: replacementRange)
        replacementIndexSet.remove(replacementIndexSet.first!)
        replacementIndexSet.insert(0)

        editableBroadcastingOrderedSet.replace(from: replacementIndexSet, with: replacementElements)

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testReplacementOfAlreadyExistingElementsAtSameIndexSetDoesNotCauseError() {
        let sampleContentCount = sampleContent.count
        let replacementRange = sampleContentCount / 3 ..< sampleContentCount / 2
        let replacementElements = NSOrderedSet(array: sampleContent, range: NSRange(location: replacementRange.startIndex, length: replacementRange.distance(from: replacementRange.startIndex, to: replacementRange.endIndex)), copyItems: false)
        let replacementIndexSet = IndexSet(integersIn: replacementRange)

        editableBroadcastingOrderedSet.replace(from: replacementIndexSet, with: replacementElements)

        //  Assert that we did not get stuff in the error reporter log.
        XCTAssertTrue(ErrorReporter.testingLog.isEmpty)
    }


    func testThatReplacingAnElementNotInContentsCausesError() {
        editableBroadcastingOrderedSet.replace(BroadcastingCollectionTestContent.sampleLeo, with: BroadcastingCollectionTestContent.sampleBanon)

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testReplacingDifferentCountOfReplaceesAndReplacementsCausesError() {
        //  One replacee, two replacements.
        let replacees = NSOrderedSet(object: BroadcastingCollectionTestContent(number: 1, string: "Tina"))
        let replacements = NSOrderedSet(arrayLiteral: BroadcastingCollectionTestContent.sampleKefka, BroadcastingCollectionTestContent.sampleGestalt)

        editableBroadcastingOrderedSet.replace(replacees, with: replacements)

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testThatReplacingSeveralElementsNotInContentsCausesError() {
        let replacees = NSOrderedSet(arrayLiteral: BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon)
        let replacements = NSOrderedSet(arrayLiteral: BroadcastingCollectionTestContent.sampleKefka, BroadcastingCollectionTestContent.sampleGestalt)

        editableBroadcastingOrderedSet.replace(replacees, with: replacements)

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }


    func testThatReplacingSomeElementsNotInContentsCausesError() {
        let replacees = NSOrderedSet(arrayLiteral: BroadcastingCollectionTestContent.sampleLeo, sampleContent[0])
        let replacements = NSOrderedSet(arrayLiteral: BroadcastingCollectionTestContent.sampleKefka, BroadcastingCollectionTestContent.sampleGestalt)

        editableBroadcastingOrderedSet.replace(replacees, with: replacements)

        //  Assert that we got stuff in the error reporter log.
        XCTAssertFalse(ErrorReporter.testingLog.isEmpty)
    }
}
