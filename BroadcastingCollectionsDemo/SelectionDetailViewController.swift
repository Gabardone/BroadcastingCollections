//
//  SelectionDetailViewController.swift
//  BroadcastingCollectionsDemo
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import Cocoa
import Contacts
import ContactsUI


class SelectionDetailViewController: NSViewController, BroadcastingSetListener {

    @IBOutlet weak var centerLabel: NSTextField!


    private var contactViewController: CNContactViewController?


    private var displayContacts: Set<CNContact> {
        return representedObject as? Set<CNContact> ?? Set<CNContact>()
    }

    //  MARK: - BroadcastingSetListener Implementation

    typealias ListenedElement = CNContact


    typealias ListenedCollectionTypes = SetTypesWrapper<CNContact>


    func broadcastingSetDidEndTransactions(_ broadcastingSet: BroadcastingSet<CNContact>) {
        representedObject = broadcastingSet.contents
    }


    func broadcastingSet(_ broadcastingSet: BroadcastingSet<CNContact>, didApply change: CollectionChange<Set<CNContact>>) {
        if !broadcastingSet.isExecutingTransactions {
            //  Update the selection.
            representedObject = broadcastingSet.contents
        }
    }


    var broadcastSelection: BroadcastingSet<CNContact>! {
        willSet {
            if broadcastSelection !== newValue {
                broadcastSelection?.remove(listener: self)
            }
        }

        didSet {
            if broadcastSelection !== oldValue {
                broadcastSelection?.add(listener: self)

                representedObject = broadcastSelection?.contents ?? Set<CNContact>()
            }
        }
    }


    private func _updateSelectionDisplay() {
        let displayContacts = self.displayContacts
        let contactCount = displayContacts.count

        if contactCount == 1 {
            //  Display a contact view controller.
            centerLabel.isHidden = true
            if contactViewController == nil {
                contactViewController = CNContactViewController()
                let contactView = contactViewController!.view
                view.addSubview(contactView)

                NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|[contactView]|", options: .directionLeadingToTrailing, metrics: nil, views: ["contactView": contactView]))
                NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[contactView]|", options: [], metrics: nil, views: ["contactView": contactView]))
            }
            contactViewController?.contact = displayContacts.first
        } else {
            //  Display a label.
            centerLabel.isHidden = false
            contactViewController?.view.removeFromSuperview()
            contactViewController = nil

            let labelString = String.localizedStringWithFormat(NSLocalizedString("SELECTED_CONTACT_COUNT", tableName: "Localizable", bundle: Bundle.main, value: "%li Contacts Selected", comment: "Localizable string for label for no/multiple selected contacts. Extracted from stringsdict"), contactCount)
            centerLabel.stringValue = labelString
        }
    }

    //  MARK: - NSViewController Overrides.


    private static let minWidth: CGFloat = 400.0


    private static let maxWidth: CGFloat = 800.0


    private static let minHeight: CGFloat = 300.0


    override func viewDidLoad() {
        super.viewDidLoad()

        //  Set up min and max width/height (can't do in IB for some reason).
        view.widthAnchor.constraint(greaterThanOrEqualToConstant: SelectionDetailViewController.minWidth).isActive = true
        view.widthAnchor.constraint(lessThanOrEqualToConstant: SelectionDetailViewController.maxWidth).isActive = true
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: SelectionDetailViewController.minHeight).isActive = true

        //  Make sure the label shows the right text (should initialize with no contact selected...)
        _updateSelectionDisplay()
    }


    override var representedObject: Any? {
        didSet {
            let oldSet = oldValue as? Set<CNContact> ?? Set<CNContact>()
            let newValue = representedObject as? Set<CNContact> ?? Set<CNContact>()

            if oldSet != newValue {
                _updateSelectionDisplay()
            }
        }
    }
}
