//
//  BroadcastingSetMixerTestCase.swift
//  BroadcastingCollectionsTests
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


class BroadcastingSetMixerTestCase: BroadcastingSetTestCase {

    var broadcastingSetMixer: BroadcastingSetMixer<BroadcastingCollectionTestContent> {
        return broadcastingSet as! BroadcastingSetMixer<BroadcastingCollectionTestContent>
    }

    var firstBroadcastingSetSource: EditableBroadcastingSet<BroadcastingCollectionTestContent>!
    var secondBroadcastingSetSource: EditableBroadcastingSet<BroadcastingCollectionTestContent>!

    override func setUp() {
        super.setUp()

        //  Create the broadcasting set contents sources.
        //  First one has sampleContents by default.
        firstBroadcastingSetSource = EditableBroadcastingSet<BroadcastingCollectionTestContent>()
        firstBroadcastingSetSource.contents = Set(sampleContent)

        //  Second one empty by default.
        secondBroadcastingSetSource = EditableBroadcastingSet<BroadcastingCollectionTestContent>()

        broadcastingSetMixer.contentsSources = Set([firstBroadcastingSetSource, secondBroadcastingSetSource])

        testListener.listenerLog = ""
    }

    override func tearDown() {

        firstBroadcastingSetSource = nil
        secondBroadcastingSetSource = nil

        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}
