//
//  BroadcastingOrderedSetRepublisherTests.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation
import BroadcastingCollections
import XCTest


class BroadcastingOrderedSetRepublisherTests: EditableBroadcastingOrderedSetTestCase {

    typealias RepublisherListener = BroadcastingOrderedSetRepublisher<BroadcastingCollectionTestContent, BroadcastingCollectionTestContent>


    var republisherListener = RepublisherListener() {
        willSet {
            if newValue !== republisherListener {
                republisherListener.remove(listener: passthroughListener)
            }
        }

        didSet {
            if oldValue !== republisherListener {
                republisherListener.republishedBroadcastingOrderedSet = broadcastingOrderedSet
                republisherListener.add(listener: passthroughListener)
            }
        }
    }


    let passthroughListener = ListenerType()


    override func setUp() {
        super.setUp()

        //  Just get a new one.
        republisherListener = RepublisherListener()

        testListener.ignoreBroadcastingCollectionIdentity = true
        passthroughListener.ignoreBroadcastingCollectionIdentity = true
        sampleListener.ignoreBroadcastingCollectionIdentity = true
    }


    func testComplexChangeChangesPassThrough() {
        let reversedContent = Array(sampleContent.reversed())

        editableBroadcastingOrderedSet.contents = NSOrderedSet(array: reversedContent)

        XCTAssertEqual(passthroughListener.listenerLog, testListener.listenerLog)

        //  Test that it got through the begin and end complex changes.
        sampleListener.broadcastingOrderedSetWillBeginTransactions(republisherListener)
        XCTAssert(passthroughListener.listenerLog.hasPrefix(sampleListener.listenerLog))

        sampleListener.listenerLog = ""
        sampleListener.broadcastingOrderedSetDidEndTransactions(republisherListener)
        XCTAssert(passthroughListener.listenerLog.hasSuffix(sampleListener.listenerLog))
    }


    func testInsertionChangesPassThrough() {
        let elementsToInsert = NSOrderedSet(array: [BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon])
        let indexesToInsert = IndexSet(integersIn: (sampleContent.count / 2) ..< (sampleContent.count / 2 + 2))

        editableBroadcastingOrderedSet.insert(elementsToInsert, at: indexesToInsert)

        XCTAssert(passthroughListener.listenerLog == testListener.listenerLog)

        //  Test that it got the right changes.
        let indexedInsertion = IndexedElements(indexes: indexesToInsert, elements: elementsToInsert.array as! [BroadcastingCollectionTestContent])
        sampleListener.broadcastingOrderedSet(republisherListener, willInsert: indexedInsertion)
        sampleListener.broadcastingOrderedSet(republisherListener, didInsert: indexedInsertion)
        XCTAssert(passthroughListener.listenerLog == sampleListener.listenerLog)
    }


    func testRemovalChangesPassThrough() {
        let indexesToRemove = IndexSet(integersIn: (sampleContent.count / 2) ..< (sampleContent.count / 2 + 2))
        let elementsRemoved = editableBroadcastingOrderedSet.contents.objects(at: indexesToRemove) as! [BroadcastingCollectionTestContent]

        editableBroadcastingOrderedSet.remove(from: indexesToRemove)

        XCTAssert(passthroughListener.listenerLog == testListener.listenerLog)

        //  Test that it got the right changes.
        let indexedRemoval = IndexedElements(indexes: indexesToRemove, elements: elementsRemoved)
        sampleListener.broadcastingOrderedSet(republisherListener, willRemove: indexedRemoval)
        sampleListener.broadcastingOrderedSet(republisherListener, didRemove: indexedRemoval)
        XCTAssert(passthroughListener.listenerLog == sampleListener.listenerLog)
    }


    func testMovingChangesPassThrough() {
        let fromIndex = 2
        let toIndex = sampleContent.count - 2
        let elementMoved = sampleContent[fromIndex]

        editableBroadcastingOrderedSet.move(from: fromIndex, to: toIndex)

        XCTAssert(passthroughListener.listenerLog == testListener.listenerLog)

        //  Test that it got the right changes.
        sampleListener.broadcastingOrderedSet(republisherListener, willMove: elementMoved, from: fromIndex, to: toIndex)
        sampleListener.broadcastingOrderedSet(republisherListener, didMove: elementMoved, from: fromIndex, to: toIndex)

        XCTAssert(passthroughListener.listenerLog == sampleListener.listenerLog)
    }


    func testReplaceChangesPassThrough() {
        let replacements = NSOrderedSet(array: [BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon])
        let indexesToReplace = IndexSet(integersIn: (sampleContent.count / 2) ..< (sampleContent.count / 2 + 2))
        let replacees = editableBroadcastingOrderedSet.contents.objects(at: indexesToReplace) as! [BroadcastingCollectionTestContent]

        editableBroadcastingOrderedSet.replace(from: indexesToReplace, with: replacements)

        XCTAssert(passthroughListener.listenerLog == testListener.listenerLog)

        //  Test that it got the right changes.
        let indexedReplacees = IndexedElements(indexes: indexesToReplace, elements: replacees)
        let indexedReplacements = IndexedElements(indexes: indexesToReplace, elements: replacements.array as! [BroadcastingCollectionTestContent])
        sampleListener.broadcastingOrderedSet(republisherListener, willReplace: indexedReplacees, with: indexedReplacements)
        sampleListener.broadcastingOrderedSet(republisherListener, didReplace: indexedReplacees, with: indexedReplacements)
        XCTAssert(passthroughListener.listenerLog == sampleListener.listenerLog)
    }
}
