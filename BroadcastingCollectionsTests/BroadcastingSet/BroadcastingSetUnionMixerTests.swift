//
//  BroadcastingSetUnionMixerTests.swift
//  BroadcastingCollectionsTests
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


class BroadcastingSetUnionMixerTests: BroadcastingSetMixerTestCase {

    override func createBroadcastingSet() -> BroadcastingSet<BroadcastingCollectionTestContent> {
        return BroadcastingSetUnionMixer<BroadcastingCollectionTestContent>()
    }


    func testContentsSourcesSetUp() {
        //  Just test is as it comes from setUp.
        let expectedContents = firstBroadcastingSetSource.contents.union(secondBroadcastingSetSource.contents)
        XCTAssertEqual(broadcastingSet.contents, expectedContents)
    }


    func testInsertionOfElementsNoneInContents() {
        let insertedElements = Set([BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon, BroadcastingCollectionTestContent.sampleKefka])

        secondBroadcastingSetSource.add(insertedElements)

        let expectedContents = Set(sampleContent).union(insertedElements)
        XCTAssertEqual(broadcastingSet.contents, expectedContents)

        sampleListener.broadcastingSet(broadcastingSet, willAdd: insertedElements)
        sampleListener.broadcastingSet(broadcastingSet, didAdd: insertedElements)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testInsertionOfElementsSomeInContents() {
        let insertedElements = Set([sampleContent[0], sampleContent[7], BroadcastingCollectionTestContent.sampleLeo, BroadcastingCollectionTestContent.sampleBanon, BroadcastingCollectionTestContent.sampleKefka])

        secondBroadcastingSetSource.add(insertedElements)

        let expectedContents = Set(sampleContent).union(insertedElements)
        XCTAssertEqual(broadcastingSet.contents, expectedContents)

        let expectedInsertion = insertedElements.subtracting(Set(sampleContent))
        sampleListener.broadcastingSet(broadcastingSet, willAdd: expectedInsertion)
        sampleListener.broadcastingSet(broadcastingSet, didAdd: expectedInsertion)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testInsertionOfElementsAllInContents() {
        let insertedElements = Set([sampleContent[0], sampleContent[7], sampleContent[11]])

        secondBroadcastingSetSource.add(insertedElements)

        let expectedContents = Set(sampleContent)
        XCTAssertEqual(broadcastingSet.contents, expectedContents)

        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testRemovalOfElementsAllInOnlyOneSource() {
        let removedElements = Set([sampleContent[0], sampleContent[7], sampleContent[11]])

        firstBroadcastingSetSource.remove(removedElements)

        let expectedContents = Set(sampleContent).subtracting(removedElements)
        XCTAssertEqual(broadcastingSet.contents, expectedContents)

        sampleListener.broadcastingSet(broadcastingSet, willRemove: removedElements)
        sampleListener.broadcastingSet(broadcastingSet, didRemove: removedElements)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testRemovalOfElementsAllInBothSources() {
        let secondContents = Set(sampleContent[0 ..< 8])
        secondBroadcastingSetSource.add(secondContents)

        //  The above should have caused no changes to be broadcast below.
        XCTAssertEqual(testListener.listenerLog, "")

        //  Note that both of these are in secondContents
        let removedElements = Set([sampleContent[0], sampleContent[7]])

        firstBroadcastingSetSource.remove(removedElements)

        let expectedContents = Set(sampleContent)
        XCTAssertEqual(broadcastingSet.contents, expectedContents)

        XCTAssertEqual(testListener.listenerLog, "")
    }


    func testRemovalOfElementsSomeInBothSources() {
        let secondContents = Set(sampleContent[0 ..< 8])
        secondBroadcastingSetSource.add(secondContents)

        //  The above should have caused no changes to be broadcast below.
        XCTAssertEqual(testListener.listenerLog, "")

        //  Note that some of these are in secondContents
        let removedElements = Set([sampleContent[0], sampleContent[7], sampleContent[9], sampleContent[12]])

        firstBroadcastingSetSource.remove(removedElements)

        let expectedRemoval = removedElements.subtracting(secondContents)
        let expectedContents = Set(sampleContent).subtracting(expectedRemoval)
        XCTAssertEqual(broadcastingSet.contents, expectedContents)

        sampleListener.broadcastingSet(broadcastingSet, willRemove: expectedRemoval)
        sampleListener.broadcastingSet(broadcastingSet, didRemove: expectedRemoval)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }
}
