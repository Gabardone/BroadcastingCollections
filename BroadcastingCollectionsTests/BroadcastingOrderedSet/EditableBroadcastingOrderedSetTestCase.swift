//
//  EditableBroadcastingOrderedSetTestCase.swift
//  BroadcastingCollectionsTests
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


extension EditableBroadcastingOrderedSet where Element == BroadcastingCollectionTestContent {

    func setupWithSampleContents() {
        contents = NSOrderedSet(array: BroadcastingCollectionTestContent.sampleContent.map({ (element) -> BroadcastingCollectionTestContent in
            return element.clone()
        }))
    }
}


class EditableBroadcastingOrderedSetTestCase: BroadcastingOrderedSetTestCase {

    override func createBroadcastingOrderedSet() -> BroadcastingOrderedSet<BroadcastingCollectionTestContent> {
        return EditableBroadcastingOrderedSet<BroadcastingCollectionTestContent>()
    }


    override func setUp() {
        super.setUp()

        //  Set its data to a copy of sample content (notice that we don't have listeners yet).
        editableBroadcastingOrderedSet.setupWithSampleContents()

        //  Reset the test listener.
        testListener.listenerLog = ""
    }
}
