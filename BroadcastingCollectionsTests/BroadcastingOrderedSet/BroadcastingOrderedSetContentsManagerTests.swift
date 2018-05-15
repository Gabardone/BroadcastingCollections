//
//  BroadcastingOrderedSetContentsManagerTests.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


class BroadcastingOrderedSetTestContentsManager: BroadcastingOrderedSetContentsManager<BroadcastingCollectionTestContent> {

    var callsToStartUpdating = 0

    var callsToStopUpdating = 0

    override func startUpdating() {
        callsToStartUpdating += 1
    }

    override func stopUpdating() {
        callsToStopUpdating += 1
    }
}


class BroadcastingOrderedSetContentsManagerTests: EditableBroadcastingOrderedSetTestCase {

    func testSettingUpAContentsManagerLeavesItUpdating() {
        let dummyContentsManager = BroadcastingOrderedSetTestContentsManager()

        XCTAssert(dummyContentsManager.isUpdating == false)
        XCTAssert(dummyContentsManager.callsToStartUpdating == 0)
        XCTAssert(dummyContentsManager.callsToStopUpdating == 0)

        editableBroadcastingOrderedSet.contentsManager = dummyContentsManager

        XCTAssert(dummyContentsManager.isUpdating == true)
        XCTAssert(dummyContentsManager.callsToStartUpdating == 1)
        XCTAssert(dummyContentsManager.callsToStopUpdating == 0)

        editableBroadcastingOrderedSet.contentsManager = nil

        XCTAssert(dummyContentsManager.isUpdating == false)
        XCTAssert(dummyContentsManager.callsToStartUpdating == 1)
        XCTAssert(dummyContentsManager.callsToStopUpdating == 1)
    }
}
