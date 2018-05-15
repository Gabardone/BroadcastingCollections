//
//  BroadcastingOrderedSetSelectionControllerTests.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


class BroadcastingOrderedSetSelectionControllerTests: BroadcastingOrderedSetSelectionControllerTestCase {

    var selectedIndexesDidChange = false
    var selectedElementChangeListener: BroadcastingSetTestListener!
    var sampleSelectedElementChangeListener: BroadcastingSetTestListener!
    var selectedIndexChangeNotificationObserver: Any? = nil
    var incomingSelectedElements: Set<BroadcastingCollectionTestContent>? = nil
    var outgoingSelectedElements: Set<BroadcastingCollectionTestContent>? = nil
    var incomingSelectedIndexes: IndexSet? = nil
    var outgoingSelectedIndexes: IndexSet? = nil


    override func setUp() {
        super.setUp()

        selectedElementChangeListener = BroadcastingSetTestListener()
        selectionController.broadcastingSelectedElements.add(listener: selectedElementChangeListener)

        sampleSelectedElementChangeListener = BroadcastingSetTestListener()

        selectedIndexChangeNotificationObserver = NotificationCenter.default.addObserver(forName: SelectionControllerType.selectedIndexesDidChange, object: selectionController, queue: nil) { (notification) in
            self.incomingSelectedIndexes = notification.userInfo?[SelectionControllerType.incomingSelectedIndexes] as? IndexSet
            self.outgoingSelectedIndexes = notification.userInfo?[SelectionControllerType.outgoingSelectedIndexes] as? IndexSet
            self.selectedIndexesDidChange = true
        }
    }


    override func tearDown() {
        clearNotificationData()

        selectedElementChangeListener = nil
        sampleSelectedElementChangeListener = nil
        NotificationCenter.default.removeObserver(selectedIndexChangeNotificationObserver!)
        selectedIndexChangeNotificationObserver = nil

        super.tearDown()
    }


    func clearNotificationData() {
        incomingSelectedElements = nil
        outgoingSelectedElements = nil
        incomingSelectedIndexes = nil
        outgoingSelectedIndexes = nil
        selectedElementChangeListener?.listenerLog = ""
        selectedIndexesDidChange = false
    }
}
