//
//  BroadcastingSetTestCase.swift
//  BroadcastingCollectionsTests
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import XCTest

import BroadcastingCollections
import XCTest


class BroadcastingSetTestCase: XCTestCase {

    typealias ListenerType = BroadcastingSetTestListener

    //  Our default broadcasting set to do things to in tests.
    var broadcastingSet: BroadcastingSet<BroadcastingCollectionTestContent>!

    var sampleContent: [BroadcastingCollectionTestContent] {
        return BroadcastingCollectionTestContent.sampleContent
    }

    //  This one listens to any changes we're making to broadcastingSet
    var testListener: ListenerType!

    //  Use this one to play expected changes and compare against the results captured in testListener
    var sampleListener: ListenerType!


    func createBroadcastingSet() -> BroadcastingSet<BroadcastingCollectionTestContent> {
        preconditionFailure("Attempted to call abstract property \(#function)")
    }


    override func setUp() {
        super.setUp()

        //  Create a new broadcasting set
        broadcastingSet = createBroadcastingSet()

        //  Create a new testListener and set it to listen to broadcastingSet
        testListener = ListenerType()
        broadcastingSet.add(listener: testListener)

        //  Create a new sample listener.
        sampleListener = ListenerType()
    }


    override func tearDown() {
        //  Clear out all the auxiliary test objects.
        broadcastingSet = nil
        testListener = nil
        sampleListener = nil

        super.tearDown()
    }
}

