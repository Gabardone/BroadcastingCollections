//
//  BroadcastingOrderedSetTestCase.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


class BroadcastingOrderedSetTestCase: XCTestCase {

    typealias ListenerType = BroadcastingOrderedSetTestListener

    //  Our default broadcasting ordered set to do things to in tests.
    var broadcastingOrderedSet: BroadcastingOrderedSet<BroadcastingCollectionTestContent>!


    //  Most subclasses set a editable broadcasting ordered set as its broadcastingOrderedSet property. Use this to
    //  avoid typecasting all over the place.
    var editableBroadcastingOrderedSet: EditableBroadcastingOrderedSet<BroadcastingCollectionTestContent> {
        return broadcastingOrderedSet as! EditableBroadcastingOrderedSet<BroadcastingCollectionTestContent>
    }


    var sampleContent: [BroadcastingCollectionTestContent] {
        return BroadcastingCollectionTestContent.sampleContent
    }

    //  This one listens to any changes we're making to broadcastingOrderedSet
    var testListener: ListenerType!

    //  Use this one to replay expected changes and compare against the results captured in testListener
    var sampleListener: ListenerType!


    func createBroadcastingOrderedSet() -> BroadcastingOrderedSet<BroadcastingCollectionTestContent> {
        preconditionFailure("Attempted to call abstract property \(#function)")
    }


    override func setUp() {
        super.setUp()

        //  Create a new broadcasting ordered set.
        broadcastingOrderedSet = createBroadcastingOrderedSet()

        //  Create a new testListener and sest it to listen to broadcastingOrderedSet
        testListener = ListenerType()
        broadcastingOrderedSet.add(listener: testListener)

        //  Create a new sample listener.
        sampleListener = ListenerType()
    }


    override func tearDown() {
        //  Clear out all the auxiliary test objects.
        broadcastingOrderedSet = nil
        testListener = nil
        sampleListener = nil

        super.tearDown()
    }
}
