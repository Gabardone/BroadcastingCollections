//
//  BroadcastingOrderedSetSelectionControllerTestCase.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


class BroadcastingOrderedSetSelectionControllerTestCase: EditableBroadcastingOrderedSetTestCase {

    typealias SelectionControllerType = BroadcastingOrderedSetSelectionController<BroadcastingCollectionTestContent>


    var selectionController: SelectionControllerType = SelectionControllerType()


    override public func setUp() {
        super.setUp()

        selectionController = SelectionControllerType()
        selectionController.republishedBroadcastingOrderedSet = broadcastingOrderedSet
    }

    
    override public func tearDown() {
        selectionController.republishedBroadcastingOrderedSet = nil

        super.tearDown()
    }
}
