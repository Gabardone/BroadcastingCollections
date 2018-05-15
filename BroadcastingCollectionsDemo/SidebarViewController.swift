//
//  SidebarViewController.swift
//  BroadcastingCollectionsDemo
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import Cocoa
import Contacts


class ContactsSortingContentsManager: BroadcastingOrderedSetSetSortingContentsManager<CNContact> {

    var ascendingSort = true {
        didSet {
            if ascendingSort != oldValue && isUpdating {
                //  Pretty much need to resort the whole thing.
                (self as BroadcastingOrderedSetContentsManager<CNContact>).managedContents?.contents = calculateContents()
            }
        }
    }


    var sortingCriteria = CNContactSortOrder.familyName {
        didSet {
            if sortingCriteria != oldValue {
                //  Update the private comparator.
                contactsComparator = CNContact.comparator(forNameSortOrder: sortingCriteria)

                if isUpdating {
                    //  Pretty much need to resort the whole thing.
                    (self as BroadcastingOrderedSetContentsManager<CNContact>).managedContents?.contents = calculateContents()
                }
            }
        }
    }


    private var contactsComparator = CNContact.comparator(forNameSortOrder: .familyName)


    override func areInIncreasingOrder(_ left: CNContact, _ right: CNContact) -> Bool {
        return contactsComparator(left, right) == (ascendingSort ? .orderedAscending : .orderedDescending)
    }
}


class ContactsFilteringContentsManager: BroadcastingSetFilteringContentsManager<CNContact> {

    var filtersPeople = true {
        didSet {
            //  Reevaluate only people contacts.
            if filtersPeople != oldValue, let contentsSource = self.contentsSource {
                reevaluate(contentsSource.contents.filter { (contact) -> Bool in
                    return contact.contactType == .person
                })
            }
        }
    }


    var filtersOrganizations = true {
        didSet {
            //  Reevaluate only organization contacts.
            if filtersPeople != oldValue, let contentsSource = self.contentsSource {
                reevaluate(contentsSource.contents.filter { (contact) -> Bool in
                    return contact.contactType == .organization
                })
            }
        }
    }


    override func filters(_ element: CNContact) -> Bool {
        switch element.contactType {
        case .person:
            return filtersPeople

        case .organization:
            return filtersOrganizations
        }
    }
}


class SidebarViewController: NSViewController {

    @IBOutlet weak var separator: NSView!


    @IBAction func changeSortOrder(_ sender: NSPopUpButton) {
        switch sender.indexOfSelectedItem {
        case 0:
            sortingContentsManager.ascendingSort = true
        default:
            sortingContentsManager.ascendingSort = false
        }
    }


    @IBAction func changeSortCriteria(_ sender: NSPopUpButton) {
        switch sender.indexOfSelectedItem {
        case 0:
            sortingContentsManager.sortingCriteria = .familyName

        default:
            sortingContentsManager.sortingCriteria = .givenName
        }
    }


    @IBAction func changeFiltering(_ sender: NSPopUpButton) {
        if let filterContentsManager = self.filterContentsManager {
            switch sender.indexOfSelectedItem {
            case 0:
                //  All contacts.
                filterContentsManager.filtersOrganizations = true
                filterContentsManager.filtersPeople = true

            case 1:
                //  Only People
                filterContentsManager.filtersOrganizations = false
                filterContentsManager.filtersPeople = true

            default:
                //  Only organizations.
                filterContentsManager.filtersOrganizations = true
                filterContentsManager.filtersPeople = false
            }
        }
    }


    var broadcastSelection: BroadcastingSet<CNContact> {
        return contactsTableViewController.broadcastSelection
    }

    private var contactsTableViewController: ContactsTableViewController {
        //  Better not to call this before the view has loaded from the storyboard.
        return childViewControllers[0] as! ContactsTableViewController
    }


    private let allContacts = EditableBroadcastingSet<CNContact>()


    private var filterContentsManager: ContactsFilteringContentsManager! {
        get {
            return filteredContacts.contentsManager as? ContactsFilteringContentsManager
        }

        set {
            newValue?.contentsSource = allContacts
            filteredContacts.contentsManager = newValue
        }
    }


    private let filteredContacts = EditableBroadcastingSet<CNContact>()


    private var sortingContentsManager = ContactsSortingContentsManager()


    private func fetchAllContacts() {
        //  Dispatch the fetching to a high priority queue, put back the results in the main queue.
        DispatchQueue.global(qos: .userInitiated).async {
            let allContactsFetchRequest = CNContactFetchRequest(keysToFetch: [CNContact.descriptorForAllComparatorKeys(), CNContactFormatter.descriptorForRequiredKeys(for: .fullName)])
            do {
                try AppDelegate.contactStore.enumerateContacts(with: allContactsFetchRequest, usingBlock: { (contact, stop) in
                    DispatchQueue.main.async {
                        self.allContacts.add(contact)
                    }
                })
            } catch {
                preconditionFailure("Contact fetch failed with error \(error)")
            }
        }
    }

    //  MARK: - NSSeguePerforming Overrides

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let contactsTableViewController = segue.destinationController as? ContactsTableViewController {
            contactsTableViewController.displayContentsManager = sortingContentsManager
        }
    }

    //  MARK: - NSViewController Overrides

    private static let minWidth: CGFloat = 300.0


    private static let maxWidth: CGFloat = 600.0


    override func viewDidLoad() {
        super.viewDidLoad()

        //  Set up the custom separator separation.
        (view as? NSStackView)?.setCustomSpacing(0.0, after: self.separator)

        //  Set up min and max width (can't do in IB for some reason).
        view.widthAnchor.constraint(greaterThanOrEqualToConstant: SidebarViewController.minWidth).isActive = true
        view.widthAnchor.constraint(lessThanOrEqualToConstant: SidebarViewController.maxWidth).isActive = true

        //  Set up the filtering contents manager (a default one filters it all in).
        filterContentsManager = ContactsFilteringContentsManager()

        //  Set up the contacts sorting contents manager.
        sortingContentsManager.contentsSource = filteredContacts

        //  And now start fetching all the contacts.
        fetchAllContacts()
    }
}
