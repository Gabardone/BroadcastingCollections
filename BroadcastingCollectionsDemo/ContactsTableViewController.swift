//
//  ContactsTableViewController.swift
//  BroadcastingCollectionsDemo
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import Cocoa
import Contacts


class ContactsTableViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, BroadcastingOrderedSetFullListener {

    @IBOutlet weak var tableView: NSTableView!


    //  Sorting contents manager for displayOrderedSet.
    var displayContentsManager: BroadcastingOrderedSetContentsManager<CNContact>? {
        get {
            return displayOrderedSet.contentsManager
        }

        set {
            displayOrderedSet.contentsManager = newValue
        }
    }


    //  Actual elements displayed on the table.
    private var displayOrderedSet = EditableBroadcastingOrderedSet<CNContact>()


    //  Controls the table selection and is the one we listen to for table management. Wired in viewDidLoad()
    private let selectionController = BroadcastingOrderedSetSelectionController<CNContact>()


    var broadcastSelection: BroadcastingSet<CNContact> {
        return selectionController.broadcastingSelectedElements
    }


    private var selectionNotificationObserver: NSObjectProtocol?


    deinit {
        if let observer = selectionNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    //  MARK: - NSViewController Overrides.

    override func viewDidLoad() {
        super.viewDidLoad()

        //  Set up the selection controller.
        selectionController.allowsEmptySelection = true
        selectionController.allowsMultipleSelection = true

        //  Set us up to listen to the selection change notification in the selection controller.
        selectionNotificationObserver = NotificationCenter.default.addObserver(forName: BroadcastingOrderedSetSelectionController<CNContact>.selectedIndexesDidChange as NSNotification.Name, object: selectionController, queue: OperationQueue.main) { [weak self] (notification) in
            self?.selectionController.selectedIndexes = notification.userInfo![BroadcastingOrderedSetSelectionController<CNContact>.incomingSelectedIndexes] as! IndexSet
        }

        //  Set up the private broadcasting ordered set listener chain.
        selectionController.republishedBroadcastingOrderedSet = displayOrderedSet
        selectionController.add(listener: self)
    }

    //  MARK: - NSTableViewDataSource Implementation

    func numberOfRows(in tableView: NSTableView) -> Int {
        return selectionController.contents.count
    }

    //  MARK: - NSTableViewDelegate Implementation

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let result = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else {
            preconditionFailure("Couldn't create contact cell for column \(String(describing: tableColumn)) row \(row)")
        }

        let contact = selectionController.array[row]

        result.textField?.stringValue = CNContactFormatter.string(from: contact, style: .fullName) ?? NSLocalizedString("CONTACT_FORMAT_ERROR", tableName: "Localizable", bundle: Bundle.main, value: "Contact Formatter Error", comment: "String to display when there is a formatting error with a contact's name.")

        return result
    }


    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView, tableView === self.tableView else {
            preconditionFailure("We're getting a notification from another table's selection.")
        }

        selectionController.selectedIndexes = tableView.selectedRowIndexes
    }

    //  MARK: - BroadcastingOrderedSetFullListener Implementation

    typealias ListenedElement = CNContact


    typealias ListenedCollectionTypes = OrderedSetTypesWrapper<CNContact>


    func broadcastingOrderedSetWillBeginTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<CNContact>) {
        tableView?.beginUpdates()
    }


    func broadcastingOrderedSetDidEndTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<CNContact>) {
        tableView?.endUpdates()
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<CNContact>, didInsert elementsAtIndexes: IndexedElements<CNContact>) {
        tableView?.insertRows(at: elementsAtIndexes.indexes, withAnimation: [.slideUp, .effectFade])
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<CNContact>, didRemove elementsAtIndexes: IndexedElements<CNContact>) {
        tableView?.removeRows(at: elementsAtIndexes.indexes, withAnimation: [.slideUp, .effectFade])
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<CNContact>, didMove element: CNContact, from fromIndex: Int, to toIndex: Int) {
        tableView?.moveRow(at: fromIndex, to: toIndex)
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<CNContact>, didReplace replacees: IndexedElements<CNContact>, with replacements: IndexedElements<CNContact>) {
        tableView?.reloadData(forRowIndexes: replacees.indexes, columnIndexes: IndexSet(integer: 0))
    }
}
