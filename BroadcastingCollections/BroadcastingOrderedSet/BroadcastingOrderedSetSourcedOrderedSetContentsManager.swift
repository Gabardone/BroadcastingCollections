//
//  BroadcastingOrderedSetSourcedOrderedSetContentsManager
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


open class BroadcastingOrderedSetSourcedOrderedSetContentsManager<ManagedElement: Hashable & AnyObject, ListenedElement: Hashable & AnyObject>: BroadcastingOrderedSetContentsManager<ManagedElement>, BroadcastingCollectionSourcedContentsManager, BroadcastingOrderedSetListener {

    //  MARK: - BroadcastingOrderedSetContentsManager Implementation.

    open func startUpdating(_ element: ListenedElement) {
        //  For subclasses to override.
    }


    open func stopUpdating(_ element: ListenedElement) {
        //  For subclasses to override.
    }


    /**
     Starts up suspended due to having neither a managed contentsnor contents source set.

     Superclass sets up nil managed contents suspension reason.
     */
    public override init() {
        super.init()

        //  We start suspended because we have no contents source set.
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
            preconditionFailure("Attempted to reevaluate an element \(element) that isn't in contentsSource.contents")
        }

        //  By default do nothing. This allows us to call super for validation of parameters.
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
    open func reevaluate(elementsAt indexes: IndexSet) {
        guard let maxIndex = indexes.max() else {
            //  Empty index set, nothing to evaluate.
            return
        }

        guard let contentsSource = self.contentsSource else {
            preconditionFailure("Attempted to reevaluate elements at indexes \(indexes) with no contents source set.")
        }

        guard contentsSource.contents.count > maxIndex else {
            //  Out of bounds error. Catching it even if default implementation doesn't mind.
            preconditionFailure("Out of bounds index for elements at indexes \(indexes) against contents source \(contentsSource)")
        }

        //  By default do nothing. This allows us to call super for validation of parameters.
    }

    //  MARK: - BroadcastingOrderedSetListener Implementation

    //  The default implementation for broadcastingOrderedSet(_:willApply) and broadcastingOrderedSet(_:didApply:) suits us fine.

    public typealias ListenedCollectionTypes = OrderedSetTypesWrapper<ListenedElement>


    /**
     Default behavior validates, the source, then begins an inherited transaction for it.
     */
    public func broadcastingOrderedSetWillBeginTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>) {
        validateContentsSource(forSource: broadcastingOrderedSet, called: #function)

        (self as BroadcastingOrderedSetContentsManager<ManagedElement>).managedContents?.beginTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: broadcastingOrderedSet))
    }


    /**
     Default behavior validates, the source, then ends an inherited transaction for it.
     */
    public func broadcastingOrderedSetDidEndTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>) {
        validateContentsSource(forSource: broadcastingOrderedSet, called: #function)

        (self as BroadcastingOrderedSetContentsManager<ManagedElement>).managedContents?.endTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: broadcastingOrderedSet))
    }


    /**
     Default behavior validates the parameters and stops updating to outgoing elements.
     */
    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willApply change: CollectionChange<IndexedElements<ListenedElement>>) {
        validateContentsSource(forSource: broadcastingOrderedSet, called: #function)

        switch change {
        case .removal(let changeDescription, _):
            //  Stop updating for the stuff that is leaving.
            for element in changeDescription.elements {
                stopUpdating(element)
            }
        default:
            break
        }
    }


    /**
     Default behavior validates the parameters and starts updating for incoming elements.
     */
    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didApply change: CollectionChange<IndexedElements<ListenedElement>>) {
        validateContentsSource(forSource: broadcastingOrderedSet, called: #function)

        switch change {
        case .insertion(let changeDescription, _):
            //  Stop updating for the stuff that is leaving.
            for element in changeDescription.elements {
                startUpdating(element)
            }
        default:
            break
        }
    }

    //  MARK: - BroadcastingCollectionSourcedContentsManager Implementation

    public var _contentsSource: BroadcastingOrderedSet<ListenedElement>?

    //  MARK: - BroadcastingSetContentsManager Overrides

    /** This override sets itself as a listener of contentsSource and calls startUpdating(element:) for
     each element in contentsSource's contents.

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
            (self as BroadcastingOrderedSetContentsManager<ManagedElement>).managedContents?.beginTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: contentsSource))
        }

        //  Make sure we're being updated for any specific elements currently in contents.
        contentsSource.array.forEach({ (element) -> Void in
            startUpdating(element)
        })

        //  Finally, start listening to further changes in basteBroadcaster.
        contentsSource.add(listener: self)
    }


    /** This override stops listening to contentsSource and calls stopUpdating(element:) for each element in
     contentsSource's contents.

     It will also end an inherited transaction if the contentsSource was executing transactions.

     If contentsSource is being replaced or removed, this will be called before the change is effective.

     Always call super from any override of this method.
     */
    override open func stopUpdating() {
        guard let contentsSource = self.contentsSource else {
            //  Yup this is also a big problem, we should go through this before baseBroadcaster is set to nil or whatever.
            preconditionFailure("Sourced contents manager \(self) stopped updating with no contentsSource set")
        }

        //  Stop listening!
        contentsSource.remove(listener: self)

        //  Stop updating as soon as possible.
        contentsSource.array.forEach { (element) in
            stopUpdating(element)
        }

        //  Remove the inherited transaction if the contentsSource is executing transactions at the point we stop updates.
        if contentsSource.isExecutingTransactions {
            (self as BroadcastingOrderedSetContentsManager<ManagedElement>).managedContents?.endTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: contentsSource))
        }

        //  Call super in case it ever does anything.
        super.stopUpdating()
    }
}
//}
