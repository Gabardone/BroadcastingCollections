//
//  BroadcastingSetListener.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/**
 A protocol for types who subscribe to a BroadcastingSet changes.
 */
public protocol BroadcastingSetListener: BroadcastingCollectionListener where ListenedCollectionTypes == SetTypesWrapper<ListenedElement> {

    /// Element type for the elements in the broadcasting set contents.
    associatedtype ListenedElement: Hashable

    /**
     Called by a listened broadcasting set right before starting transactions.

     You can implement this method to make any preparations to record or otherwise deal with the fact that the listened
     broadcasting set will be performing transactions. For example if you don't plan on reacting to changes
     during transactions but still expect to be able to refer to the original values, you may want to store a copy of
     the current contents.

     - Note: At the point of the call broadcastingSet.isExecutingTransactions will still be false.
     - Parameter broadcastingSet: The broadcasting set about to begin performing transactions.
     */
    func broadcastingSetWillBeginTransactions(_ broadcastingSet: BroadcastingSet<ListenedElement>)


    /**
     Called by a broadcasting set right after transactions are all done.

     A good opportunity to update your layer if you didn't want to reflect every single change happening within the
     transactions, or to close out any logic intended to deal with them.

     - Note: At the point of the call broadcastingSet.isExecutingTransactions will be back to false.
     - Parameter broadcastingSet: The broadcasting set that just ended performing transactions.
     */
    func broadcastingSetDidEndTransactions(_ broadcastingSet: BroadcastingSet<ListenedElement>)


    /**
     Broadcast by the broadcasting set right before applying a change.

     Implement this method to prepare for the upcoming changes. For example it's the perfect time to stop caring about
     anything in the collection that is about to be removed from it.

     - Note: At the point of the call broadcastingSet.contents is guaranteed to not have the given change applied to it.

     - Parameter broadcastingSet: The broadcasting set about to apply the given change.
     - Parameter change: The change about to be applied. Refer to the set type's change documentation for
     further details.
     */
    func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, willApply change: CollectionChange<ListenedCollectionTypes.ChangeDescription>)


    /**
     Broadcast by the broadcasting set right after applying a change.

     Implement this method to deal with the changes that have just happened in the set. Update your UI, deal with
     newly inserted objects etc.

     - Note: At the point of the call broadcastingSet.contents is guaranteed to have the given change already applied to it.

     - Parameter broadcastingSet: The broadcasting set that has just applied the given change.
     - Parameter change: The change that has just been applied. Refer to the set type's change documentation for
     further details.
     */
    func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, didApply change: CollectionChange<ListenedCollectionTypes.ChangeDescription>)
}


/**
 Default behavior for transaction listener methods is to do nothing.

 - Note: This is for the convenience of simple implementers of the protocol. If you expect or need to allow different
 implementations in subclasses you still need to implement these in the original implementer class or you won't get
 the expected behavior when called from the listened broadcasting ordered set.
 */
public extension BroadcastingSetListener {

    func broadcastingSetWillBeginTransactions(_ broadcastingSet: BroadcastingSet<ListenedElement>) {
    }


    func broadcastingSetDidEndTransactions(_ broadcastingSet: BroadcastingSet<ListenedElement>) {
    }


    func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, willApply change: CollectionChange<Set<ListenedElement>>) {
    }


    func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, didApply change: CollectionChange<Set<ListenedElement>>) {
    }
}


/**
 A protocol for subscribers that want to have more fine grained control over the changes that are being received from
 their listened BroadcastingSet.
 */
public protocol BroadcastingSetFullListener: BroadcastingSetListener {

    /**
     Broadcast right before inserting the given set of elements.

     - Parameter broadcastingSet: The broadcasting set about to insert the given elements.
     - Parameter elements: The set of new elements about to be inserted. They have already been validated as not
     present in broadcastingSet.contents
     */
    func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, willAdd elements: Set<ListenedElement>)


    /**
     Broadcast right after inserting the given set of elements.

     - Parameter broadcastingSet: The broadcasting set that just inserted the given elements.
     - Parameter elements: The set of new elements about to be inserted. They were validated as not present in
     broadcastingSet.contents before the insertion happened.
     */
    func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, didAdd elements: Set<ListenedElement>)


    /**
     Broadcast right before removing the given set of elements.

     - Parameter broadcastingSet: The broadcasting set about to remove the given elements.
     - Parameter elements: The set of new elements about to be removed. They have already been validated as present in
     broadcastingSet.contents
     */
    func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, willRemove elements: Set<ListenedElement>)


    /**
     Broadcast right after removing the given set of elements.

     - Parameter broadcastingSet: The broadcasting set that just removed the given elements.
     - Parameter elements: The set of elements that were just removed. They were validated as present in
     broadcastingSet.contents before the removal happened.
     */
    func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, didRemove elements: Set<ListenedElement>)
}


/**
 Default behavior is offered that spreads calls to broadcastingSet(:willApply:)/broadcastintSet(:didApply:) into their
 more specific versions. Due to Swift's vagaries wrt extension-based compliance with protocols vs. class method
 overriding it may be necessary to manually call the offered utilities if you have any subclasses that implement
 BroadcastingSetFullListener with an ancestor implementing BroadcastingSetListener.

 - Note: The default implementations for the change listen methods (including willApply/didApply) are for the
 convenience of simple implementers of the protocol. If you expect or need to allow override implementations in
 subclasses you still need to implement these in the original implementer class or you won't get the expected behavior
 when called from the listened broadcasting ordered set. The process utility methods however can be freely called.
 */

public extension BroadcastingSetFullListener {

    /**
     Decomposes and calls the more specific full listener methods. Default implementation calls this, left as a
     separate method so it can be called in those cases where the default won't apply (i.e. overrides of classes
     implementing the vanilla listener protocol differently).

     - Parameter broadcastingSet: The broadcasting set which will apply the given change.
     - Parameter change: The change to be applied.
     */
    public func process(broadcastingSet: BroadcastingSet<ListenedElement>, willApply change: SetChange<ListenedElement>) {
        switch change {
        case .insertion(let insertedElements, _):
            self.broadcastingSet(broadcastingSet, willAdd: insertedElements)

        case .removal(let removedElements, _):
            self.broadcastingSet(broadcastingSet, willRemove: removedElements)
        }
    }


    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, willApply change: SetChange<ListenedElement>) {
        process(broadcastingSet: broadcastingSet, willApply: change)
    }


    /**
     Decomposes and calls the more specific full listener methods. Default implementation calls this, left as a
     separate method so it can be called in those cases where the default won't apply (i.e. overrides of classes
     implementing the vanilla listener protocol differently).

     - Parameter broadcastingSet: The broadcasting set which did apply the given change.
     - Parameter change: The change that was applied.
     */
    public func process(broadcastingSet: BroadcastingSet<ListenedElement>, didApply change: SetChange<ListenedElement>) {
        switch change {
        case .insertion(let insertedElements, _):
            self.broadcastingSet(broadcastingSet, didAdd: insertedElements)

        case .removal(let removedElements, _):
            self.broadcastingSet(broadcastingSet, didRemove: removedElements)
        }
    }


    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, didApply change: SetChange<ListenedElement>) {
        process(broadcastingSet: broadcastingSet, didApply: change)
    }


    func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, willAdd elements: Set<ListenedElement>) {
    }


    func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, didAdd elements: Set<ListenedElement>) {
    }


    func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, willRemove elements: Set<ListenedElement>) {
    }


    func broadcastingSet(_ broadcastingSet: BroadcastingSet<ListenedElement>, didRemove elements: Set<ListenedElement>) {
    }
}
