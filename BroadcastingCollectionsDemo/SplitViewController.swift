//
//  SplitViewController.swift
//  BroadcastingCollectionsDemo
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import Cocoa
import Contacts


class SplitViewController: NSSplitViewController {

    var sidebarViewController: SidebarViewController {
        //  Don't call before the view controller has been loaded from the storyboard.
        return splitViewItems[0].viewController as! SidebarViewController
    }


    var selectionDetailViewController: SelectionDetailViewController {
        //  Don't call before the view controller has been loaded from the storyboard.
        return splitViewItems[1].viewController as! SelectionDetailViewController
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        //  Set up detail view controller with selection broadcasting set.
        selectionDetailViewController.broadcastSelection = sidebarViewController.broadcastSelection
    }
}
