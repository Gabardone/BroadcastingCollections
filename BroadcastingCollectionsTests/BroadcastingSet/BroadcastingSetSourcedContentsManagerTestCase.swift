//
//  BroadcastingSetSourcedContentsManagerTestCase.swift
//  BroadcastingCollectionsTests
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


class BroadcastingSetSourcedContentsManagerTestCase: BroadcastingSetTestCase {

    override func createBroadcastingSet() -> BroadcastingSet<BroadcastingCollectionTestContent> {
        return EditableBroadcastingSet<BroadcastingCollectionTestContent>()
    }


    var editableBroadcastingSet: EditableBroadcastingSet<BroadcastingCollectionTestContent> {
        return broadcastingSet as! EditableBroadcastingSet<BroadcastingCollectionTestContent>
    }


    //  Use broadcastingSet as the managed one, this one as the source.
    var broadcastingSetSource: EditableBroadcastingSet<BroadcastingCollectionTestContent>!


    override func setUp() {
        super.setUp()

        //  Set up the contents source with the sample contents.
        broadcastingSetSource = EditableBroadcastingSet<BroadcastingCollectionTestContent>()
        broadcastingSetSource.setupWithSampleContents()
    }


    override func tearDown() {
        broadcastingSetSource = nil

        super.tearDown()
    }
}
