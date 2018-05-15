//
//  BroadcastingSetRepublisherTests.swift
//  BroadcastingCollectionsTests
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


class BroadcastingSetRepublisherTests: BroadcastingSetTestCase {

    typealias RepublisherListener = BroadcastingSetRepublisher<BroadcastingCollectionTestContent, BroadcastingCollectionTestContent>


    override func createBroadcastingSet() -> BroadcastingSet<BroadcastingCollectionTestContent> {
        return EditableBroadcastingSet<BroadcastingCollectionTestContent>()
    }


    var editableBroadcastingSet: EditableBroadcastingSet<BroadcastingCollectionTestContent> {
        return broadcastingSet as! EditableBroadcastingSet<BroadcastingCollectionTestContent>
    }


    var republisherListener = RepublisherListener() {
        willSet {
            if newValue !== republisherListener {
                republisherListener.remove(listener: passthroughListener)
            }
        }

        didSet {
            if oldValue !== republisherListener {
                republisherListener.republishedBroadcastingSet = broadcastingSet
                republisherListener.add(listener: passthroughListener)
            }
        }
    }


    let passthroughListener = ListenerType()


    override func setUp() {
        super.setUp()

        //  Just get a new one.
        republisherListener = RepublisherListener()

        //  Set some reasonable contents on the editableBroadcastingSet
        editableBroadcastingSet.contents = Set(sampleContent)

        sampleListener.ignoreBroadcastingCollectionIdentity = true
        passthroughListener.ignoreBroadcastingCollectionIdentity = true
        passthroughListener.listenerLog = ""
        testListener.ignoreBroadcastingCollectionIdentity = true
        testListener.listenerLog = ""
    }


    func testTransactionChangesPassThrough() {
        let orthogonalContent = Set([BroadcastingCollectionTestContent.sampleBanon,
                                     BroadcastingCollectionTestContent.sampleLeo,
                                     BroadcastingCollectionTestContent.sampleKefka,
                                     BroadcastingCollectionTestContent.sampleGestalt])

        editableBroadcastingSet.contents = orthogonalContent

        XCTAssertEqual(passthroughListener.listenerLog, testListener.listenerLog)

        //  Test that it got through the begin and end complex changes.
        sampleListener.broadcastingSetWillBeginTransactions(republisherListener)
        XCTAssert(passthroughListener.listenerLog.hasPrefix(sampleListener.listenerLog))

        sampleListener.listenerLog = ""
        sampleListener.broadcastingSetDidEndTransactions(republisherListener)
        XCTAssert(passthroughListener.listenerLog.hasSuffix(sampleListener.listenerLog))
    }


    func testInsertionChangesPassThrough() {
        let elementsToInsert = Set([BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon])

        editableBroadcastingSet.add(elementsToInsert)

        XCTAssert(passthroughListener.listenerLog == testListener.listenerLog)

        //  Test that it got the right changes.
        sampleListener.broadcastingSet(republisherListener, willAdd: elementsToInsert)
        sampleListener.broadcastingSet(republisherListener, didAdd: elementsToInsert)
        XCTAssert(passthroughListener.listenerLog == sampleListener.listenerLog)
    }


    func testRemovalChangesPassThrough() {
        let indexesToRemove = IndexSet(integersIn: (sampleContent.count / 2) ..< (sampleContent.count / 2 + 2))
        let elementsRemoved = Set(sampleContent[indexesToRemove])

        editableBroadcastingSet.remove(elementsRemoved)

        XCTAssert(passthroughListener.listenerLog == testListener.listenerLog)

        //  Test that it got the right changes.
        sampleListener.broadcastingSet(republisherListener, willRemove: elementsRemoved)
        sampleListener.broadcastingSet(republisherListener, didRemove: elementsRemoved)
        XCTAssert(passthroughListener.listenerLog == sampleListener.listenerLog)
    }
}
