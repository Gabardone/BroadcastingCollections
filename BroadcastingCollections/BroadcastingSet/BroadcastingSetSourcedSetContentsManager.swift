//
//  BroadcastingSetSourcedSetContentsManager.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/**
 Base class for an editable broadcasting set contents manager that sources its contents from another broadcasting set.
 */
open class BroadcastingSetSourcedSetContentsManager<ManagedElementType: Hashable, ListenedElementType: Hashable>: BroadcastingSetContentsManager<ManagedElementType>, BroadcastingCollectionSourcedContentsManager, BroadcastingSetListener {

    //  MARK: - BroadcastingSetContentsManager Implementation.

    open func startUpdating(_ element: ListenedElement) {
        //  For subclasses to override.
    }


    open func stopUpdating(_ element: ListenedElement) {
        //  For subclasses to override.
    }


    /**
     Default initializer adds .nilContentsSource as an additional reason to suspend updates.

     Superclass sets up .nilManagedContents suspension reason.
     */
    public override init() {
        super.init()

        suspendUpdating(for: .nilContentsSource)
    }


    /**
     Single element reevaluation. Called by the contents manager when something has happened that may have changed how
     the contents manager wants to deal with that specific element. It's also valid to call directly if there's reason
     to believe a reevaluation is needed (although that may be a design problem with the contents manager).

     The default implementation just calls the multiple element version.

     - Precondition: element is contained in contentsSource.contents.
     - Parameter element: The element from the contents source set that needs to be reevaluated.
     */
    open func reevaluate(_ element: ListenedElement) {
        guard let contentsSource = self.contentsSource else {
            preconditionFailure("Attempted to reevaluate an element \(element) with no contents source set.")
        }

        //  Make sure the element is actually one we know about.
        guard contentsSource.contents.contains(element) else {
            preconditionFailure("Attempted to reevaluate an element \(element) that isn't in contents source \(contentsSource)")
        }

        //  Do nothing by default.
    }


    /**
     Multiple element reevaluation. Called by the contents manager when something has happened that may have changed the
     managed criteria for the given elements. It's also valid to call directly if there's reason to believe a
     reevaluation is needed for those elements (although that may be a design problem with the contents manager).

     The default implementation doesn't do anything beyond parameter validation, and should be called from subclasses
     precisely for that reason.

     - Precondition: all elements are contained in contentsSource.contents
     - Parameter elementIndexes: The indexes of the elements in contentsSource.contents that needs to be reevaluated.
     */
    open func reevaluate(_ elements: Set<ListenedElement>) {
        guard !elements.isEmpty else {
            return
        }

        guard let contentsSource = self.contentsSource else {
            preconditionFailure("Attempted to reevaluate elements \(elements) with no contents source set.")
        }

        guard contentsSource.contents.isSuperset(of: elements) else {
            preconditionFailure("Attempted to reevaluate elements \(elements) that are not a subset of contents source \(contentsSource)")
        }

        //  Do nothing by default.
    }

    //  MARK: - BroadcastingSetListener Implementation

    //  The default implementation for broadcastingSet(_:willApply) and broadcastingSet(_:didApply:) suits us fine.

    public typealias ListenedCollectionTypes = SetTypesWrapper<ListenedElement>

    public typealias ListenedElement = ListenedElementType


    public func broadcastingSetWillBeginTransactions(_ broadcastingSet: BroadcastingSet<ListenedElement>) {
        validateContentsSource(forSource: broadcastingSet, called: #function)

        (self as BroadcastingSetContentsManager<ManagedElementType>).managedContents?.beginTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: broadcastingSet))
    }


    public func broadcastingSetDidEndTransactions(_ broadcastingSet: BroadcastingSet<ListenedElement>) {
        validateContentsSource(forSource: broadcastingSet, called: #function)

        (self as BroadcastingSetContentsManager<ManagedElementType>).managedContents?.endTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: broadcastingSet))
    }


    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElementType>, willApply change: CollectionChange<Set<ListenedElementType>>) {
        validateContentsSource(forSource: broadcastingSet, called: #function)

        switch change {
        case .removal(let changeDescription, _):
            //  Stop updating for the stuff that is leaving.
            for element in changeDescription {
                stopUpdating(element)
            }
        default:
            break
        }
    }

    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElementType>, didApply change: CollectionChange<Set<ListenedElementType>>) {
        validateContentsSource(forSource: broadcastingSet, called: #function)

        switch change {
        case .insertion(let changeDescription, _):
            //  Stop updating for the stuff that is leaving.
            for element in changeDescription {
                startUpdating(element)
            }
        default:
            break
        }
    }

    //  MARK: - BroadcastingCollectionSourcedContentsManager Implementation

    public var _contentsSource: BroadcastingSet<ListenedElementType>?

    //  MARK: - BroadcastingSetContentsManager Overrides

    /** This override sets itself as a listener of contentsSource and calls startUpdating(element:) for each element in
     the contentsSource's contents.

     It will also begin an inherited transaction if the contentsSource is executing transactions.

     If contentsSource is being replaced or removed, this will be called after the change is effective.

     Always call super from any override of this method.
     */
    override open func startUpdating() {
        //  Let super do its thing.
        super.startUpdating()

        guard let contentsSource = self.contentsSource else {
            preconditionFailure("Sourced contents manager \(self) started updating with no contentsSource set")
        }

        //  Add an inherited transaction if the contentsSource is executing transactions.
        if contentsSource.isExecutingTransactions {
            (self as BroadcastingSetContentsManager<ManagedElementType>).managedContents?.beginTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: contentsSource))
        }

        //  Make sure we're being updated for any specific elements currently in contents.
        contentsSource.contents.forEach({ (element) -> Void in
            startUpdating(element)
        })

        //  Finally, start listening to further changes in basteBroadcaster.
        contentsSource.add(listener: self)
    }


    /** This override stops listening to contentsSource and calls stopUpdating(element:) for each element in
     contentSource's contents.

     It will also end an inherited transaction if the contentsSource was executing transactions.

     If contentsSource is being replaced or removed, this will be called before the change is effective.

     Always call super from any override of this method.
     */
    override open func stopUpdating() {
        guard let contentsSource = self.contentsSource else {
            //  Yup this is also a big problem, we should go through this before contentsSource is set to nil or whatever.
            preconditionFailure("Sourced contents manager \(self) stopped updating with no contentsSource set")
        }

        //  Stop listening!
        contentsSource.remove(listener: self)

        //  Stop updating as soon as possible.
        contentsSource.contents.forEach { (element) in
            stopUpdating(element)
        }

        //  Remove the inherited transaction if the contentsSource is executing transactions at the point we stop updates.
        if contentsSource.isExecutingTransactions {
            (self as BroadcastingSetContentsManager<ManagedElementType>).managedContents?.endTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: contentsSource))
        }

        //  Call super in case it ever does anything.
        super.stopUpdating()
    }
}
