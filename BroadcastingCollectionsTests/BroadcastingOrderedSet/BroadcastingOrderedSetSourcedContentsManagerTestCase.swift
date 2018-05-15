//
//  BroadcastingOrderedSetSourcedContentsManagerTestCase.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


class BroadcastingOrderedSetSourcedContentsManagerTestCase: BroadcastingOrderedSetTestCase {

    override func createBroadcastingOrderedSet() -> BroadcastingOrderedSet<BroadcastingCollectionTestContent> {
        return EditableBroadcastingOrderedSet<BroadcastingCollectionTestContent>()
    }


    //  Use broadcastingOrderedSet as the managed one, this one as the source.
    var broadcastingOrderedSetSource: EditableBroadcastingOrderedSet<BroadcastingCollectionTestContent>!


    override func setUp() {
        super.setUp()

        //  Set up the contents source with the sample contents.
        broadcastingOrderedSetSource = EditableBroadcastingOrderedSet<BroadcastingCollectionTestContent>()
        broadcastingOrderedSetSource.setupWithSampleContents()
    }


    override func tearDown() {
        broadcastingOrderedSetSource = nil

        super.tearDown()
    }
}
