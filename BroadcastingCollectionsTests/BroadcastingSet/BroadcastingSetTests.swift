//
//  BroadcastingSetTests.swift
//  BroadcastingCollectionsTests
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

@testable import BroadcastingCollections
import XCTest

class BroadcastingSetTests: XCTestCase {

    var broadcastingSet: BroadcastingSet<BroadcastingCollectionTestContent>!

    override func setUp() {
        super.setUp()

        broadcastingSet = BroadcastingSet<BroadcastingCollectionTestContent>()
    }
    
    override func tearDown() {
        broadcastingSet = nil

        super.tearDown()
    }


    func testAddAndRemoveListener() {
        //  Sanity test to verify that add and remove listeners works.
        XCTAssertFalse(broadcastingSet.hasListeners)

        let testListener = BroadcastingSetTestListener()
        broadcastingSet.add(listener: testListener)

        XCTAssertTrue(broadcastingSet.hasListeners)

        broadcastingSet.remove(listener: testListener)

        XCTAssertFalse(broadcastingSet.hasListeners)
    }


    func testBroadcastingSetFaçadeIsSelf() {
        //  Sanity test to verify that the broadcasting set façade for an actual broadcasting set is itself.
        XCTAssertTrue(broadcastingSet === broadcastingSet.broadcastingSetFaçade)
    }
}
