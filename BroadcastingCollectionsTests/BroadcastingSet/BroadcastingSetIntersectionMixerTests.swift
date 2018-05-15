//
//  BroadcastingSetIntersectionMixerTests.swift
//  BroadcastingCollectionsTests
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


class BroadcastingSetIntersectionMixerTests: BroadcastingSetMixerTestCase {

    override func setUp() {
        super.setUp()

        //  Need to put something on the second source so we'll start with some contents.
        secondBroadcastingSetSource.contents = Set(sampleContent[0 ..< 8])

        //  Clear the listener log... again.
        testListener.listenerLog = ""
    }

    override func createBroadcastingSet() -> BroadcastingSet<BroadcastingCollectionTestContent> {
        return BroadcastingSetIntersectionMixer<BroadcastingCollectionTestContent>()
    }


    func testContentsSourcesSetUp() {
        //  Just test is as it comes from setUp.
        let expectedContents = firstBroadcastingSetSource.contents.intersection(secondBroadcastingSetSource.contents)
        XCTAssertEqual(broadcastingSet.contents, expectedContents)
    }


    func testInsertionOfElementsInNoSource() {
        let insertedElements = Set([BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon, BroadcastingCollectionTestContent.sampleKefka])

        secondBroadcastingSetSource.add(insertedElements)

        let expectedContents = Set(sampleContent[0 ..< 8])
        XCTAssertEqual(broadcastingSet.contents, expectedContents)

        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testInsertionOfElementsSomeInOneSourceAlready() {
        let insertedElements = Set([sampleContent[10], sampleContent[13], BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon, BroadcastingCollectionTestContent.sampleKefka])
        let expectedInsertion = Set([sampleContent[10], sampleContent[13]])

        secondBroadcastingSetSource.add(insertedElements)

        let expectedContents = Set(sampleContent[0 ..< 8]).union(expectedInsertion)
        XCTAssertEqual(broadcastingSet.contents, expectedContents)

        sampleListener.broadcastingSet(broadcastingSet, willAdd: expectedInsertion)
        sampleListener.broadcastingSet(broadcastingSet, didAdd: expectedInsertion)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testInsertionOfElementsAllInOneSourceAlready() {
        let insertedElements = Set([sampleContent[9], sampleContent[11], sampleContent[12]])

        secondBroadcastingSetSource.add(insertedElements)

        let expectedContents = Set(sampleContent[0 ..< 8]).union(insertedElements)
        XCTAssertEqual(broadcastingSet.contents, expectedContents)

        sampleListener.broadcastingSet(broadcastingSet, willAdd: insertedElements)
        sampleListener.broadcastingSet(broadcastingSet, didAdd: insertedElements)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testRemovalOfElementsAllInOnlyOneSource() {
        let removedElements = Set([sampleContent[8], sampleContent[10], sampleContent[13]])

        firstBroadcastingSetSource.remove(removedElements)

        XCTAssertEqual(broadcastingSet.contents, secondBroadcastingSetSource.contents)

        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testRemovalOfElementsAllInBothSources() {
        //  Note that both of these are in secondContents
        let removedElements = Set([sampleContent[0], sampleContent[7]])

        firstBroadcastingSetSource.remove(removedElements)

        let expectedContents = secondBroadcastingSetSource.contents.subtracting(removedElements)
        XCTAssertEqual(broadcastingSet.contents, expectedContents)

        sampleListener.broadcastingSet(broadcastingSet, willRemove: removedElements)
        sampleListener.broadcastingSet(broadcastingSet, didRemove: removedElements)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testRemovalOfElementsSomeInBothSources() {
        //  Note that some of these are in secondContents
        let removedElements = Set([sampleContent[0], sampleContent[7], sampleContent[9], sampleContent[12]])

        firstBroadcastingSetSource.remove(removedElements)

        let expectedRemoval = removedElements.intersection(secondBroadcastingSetSource.contents)
        let expectedContents = secondBroadcastingSetSource.contents.subtracting(expectedRemoval)
        XCTAssertEqual(broadcastingSet.contents, expectedContents)

        sampleListener.broadcastingSet(broadcastingSet, willRemove: expectedRemoval)
        sampleListener.broadcastingSet(broadcastingSet, didRemove: expectedRemoval)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }
}
