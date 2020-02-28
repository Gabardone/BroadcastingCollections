//
//  BroadcastingOrderedSetListener.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/**
 A protocol for types who subscribe to BroadcastingOrderedSet changes.
 */
public protocol BroadcastingOrderedSetListener: BroadcastingCollectionListener where ListenedCollectionTypes == OrderedSetTypesWrapper<ListenedElement> {

    /// Element type for the elements in the broadcasting ordered set contents.
    associatedtype ListenedElement: AnyObject & Hashable


    /**
     Called by a listened broadcasting ordered set right before starting transactions.

     You can implement this method to make any preparations to record or otherwise deal with the fact that the listened
     broadcasting ordered set will be performing transactions. For example if you don't plan on reacting to changes
     during transactions but still expect to be able to refer to the original values, you may want to store a copy of
     the current contents.

     - Note: At the point of the call broadcastingOrderedSet.isExecutingTransactions will still be false.
     - Parameter broadcastingOrderedSet: The broadcasting ordered set about to begin performing transactions.
     */
    func broadcastingOrderedSetWillBeginTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>)


    /**
     Called by a broadcasting ordered set right after transactions are all done.

     A good opportunity to update your layer if you didn't want to reflect every single change happening within the
     transactions, or to close out any logic intended to deal with them.

     - Note: At the point of the call broadcastingOrderedSet.isExecutingTransactions will be back to false.
     - Parameter broadcastingOrderedSet: The broadcasting ordered set that just ended performing transactions.
     */
    func broadcastingOrderedSetDidEndTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>)


    /**
     Broadcast by the broadcasting ordered set right before applying a change.

     Implement this method to prepare for the upcoming changes. For example it's the perfect time to stop caring about
     anything in the collection that is about to be removed from it.

     - Note: At the point of the call broadcastingOrderedSet.contents is guaranteed to not have the given change applied to it.

     - Parameter broadcastingOrderedSet: The broadcasting ordered set about to apply the given change.
     - Parameter change: The change about to be applied. Refer to the ordered set type's change documentation for
     further details.
     */
    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willApply change: IndexedCollectionChange<ListenedElement>)


    /**
     Broadcast by the broadcasting ordered set right after applying a change.

     Implement this method to deal with the changes that have just happened in the ordered set. Update your UI, deal
     with newly inserted objects etc.

     - Note: At the point of the call broadcastingOrderedSet.contents is guaranteed to have the given change already applied to it.

     - Parameter broadcastingOrderedSet: The broadcasting ordered set that has just applied the given change.
     - Parameter change: The change that has just been applied. Refer to the ordered set type's change documentation for
     further details.
     */
    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didApply change: IndexedCollectionChange<ListenedElement>)
}


/**
 Default behavior for transaction listener methods is to do nothing.

 - Note: This is for the convenience of simple implementers of the protocol. If you expect or need to allow different
 implementations in subclasses you still need to implement these in the original implementer class or you won't get
 the expected behavior when called from the listened broadcasting ordered set.
 */
public extension BroadcastingOrderedSetListener {

    func broadcastingOrderedSetWillBeginTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>) {
    }


    func broadcastingOrderedSetDidEndTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>) {
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willApply change: IndexedCollectionChange<ListenedElement>) {
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didApply change: IndexedCollectionChange<ListenedElement>) {
    }
}


/**
 A protocol for subscribers that want to have more fine grained control over the changes that are being received from
 their listened BroadcastingOrderedSet.

 - Note: The default implementations for the change listen methods (including willApply/didApply) are for the
 convenience of simple implementers of the protocol. If you expect or need to allow override implementations in
 subclasses you still need to implement these in the original implementer class or you won't get the expected behavior
 when called from the listened broadcasting ordered set.
 */
public protocol BroadcastingOrderedSetFullListener: BroadcastingOrderedSetListener {

    /**
     Broadcast right before inserting the given elements.

     - Parameter broadcastingOrderedSet: The broadcasting ordered set about to insert the given elements.
     - Parameter elementsAtIndexes: The new elements about to be inserted and the corresponding indexes they'll be
     inserted at. The parameter will always come in fully validated.
     */
    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willInsert elementsAtIndexes: IndexedElements<ListenedElement>)


    /**
     Broadcast right after the given elements have been inserted.

     - Parameter broadcastingOrderedSet: The broadcasting ordered set where the given elements were just inserted.
     - Parameter elementsAtIndexes: The new elements that were just inserted and the corresponding indexes they were
     inserted at. The parameter will always come in fully validated.
     */
    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didInsert elementsAtIndexes: IndexedElements<ListenedElement>)


    /**
     Broadcast right before the given elements are removed.

     - Parameter broadcastingOrderedSet: The broadcasting ordered set the given elements will be removed from.
     - Parameter elementsAtIndexes: The new elements about to be removed and the corresponding indexes where the
     currently are in contents. The parameter will always come in fully validated.
     */
    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willRemove elementsFromIndexes: IndexedElements<ListenedElement>)


    /**
     Broadcast right after the given elements are removed.

     - Parameter broadcastingOrderedSet: The broadcasting ordered set the given elements were just removed from.
     - Parameter elementsAtIndexes: The removed elements and the indexes they were removed from. The parameter will
     always come in fully validated.
     */
    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didRemove elementsFromIndexes: IndexedElements<ListenedElement>)


    /**
     Broadcast right before an element is moved.

     All the parameters always come in fully validated.
     - Parameter broadcastingOrderedSet: The broadcasting ordered set where the element will be moved.
     - Parameter element: The element that will be moved around.
     - Parameter fromIndex: The index the element will be moved from.
     - Parameter toIndex: The index the element will be moved to.
     */
    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willMove element: ListenedElement, from fromIndex: Int, to toIndex: Int)


    /**
     Broadcast right after an element is moved.

     All the parameters always come in fully validated.
     - Parameter broadcastingOrderedSet: The broadcasting ordered set where the element was moved.
     - Parameter element: The element that was moved around.
     - Parameter fromIndex: The index the element was moved from.
     - Parameter toIndex: The index the element was moved to.
     */
    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didMove element: ListenedElement, from fromIndex: Int, to toIndex: Int)


    /**
     Broadcast right before the given elements are replaced.

     All the parameters always come in fully validated.
     - Parameter broadcastingOrderedSet: The broadcasting ordered set where the elements will be replaced.
     - Parameter replacees: The elements about to be replaced and their corresponding indexes in contents.
     - Parameter replacements: The replacement elements and their corresponding indexes in contents.
     - Precondition: replacees.indexes == replacements.indexes
     */
    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willReplace replacees: IndexedElements<ListenedElement>, with replacements: IndexedElements<ListenedElement>)


    /**
     Broadcast right after the given elements are replaced.

     All the parameters always come in fully validated.
     - Parameter broadcastingOrderedSet: The broadcasting ordered set where the elements will be replaced.
     - Parameter replacees: The elements about to be replaced and their corresponding indexes in contents.
     - Parameter replacements: The replacement elements and their corresponding indexes in contents.
     - Precondition: replacees.indexes == replacements.indexes
     */
    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didReplace replacees: IndexedElements<ListenedElement>, with replacements: IndexedElements<ListenedElement>)
}


/**
 Default behavior for implementers of BroadcastingOrderedSetFullListener. New utilities are offered for the default
 processing of incoming changes into the detailed methods, and the default implementations of the detailed change
 methods is empty.

 - Note: The default implementations for the change listen methods (including willApply/didApply) are for the
 convenience of simple implementers of the protocol. If you expect or need to allow override implementations in
 subclasses you still need to implement these in the original implementer class or you won't get the expected behavior
 when called from the listened broadcasting ordered set. The process utility methods however can be freely called.
 */
public extension BroadcastingOrderedSetFullListener {

    //  Decomposes and calls the more specific Full Listener methods. Default implementation calls this, left as a
    //  separate method so it can be called in those cases where the default won't apply (i.e. overrides of classes
    //  implementing the vanilla listener protocol differently).
    func process(broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willApply change: IndexedCollectionChange<ListenedElement>) {
        switch change {
        case .insertion(let inserted, let associatedRemoval):
            //  If we have an associated it's the end of a move/replace so we don't need to report on willApply.
            if associatedRemoval == nil {
                //  Report as a will insert.
                self.broadcastingOrderedSet(broadcastingOrderedSet, willInsert: inserted)
            }

        case .removal(let removal, let associatedInserted):
            if let insertion = associatedInserted {
                if change.isReplacement {
                    //  It's a replacement.
                    self.broadcastingOrderedSet(broadcastingOrderedSet, willReplace: removal, with: insertion)
                } else if let (from, to) = change.singleMoveIndexes {
                    //  Report a will move.
                    self.broadcastingOrderedSet(broadcastingOrderedSet, willMove: removal.elements[0], from: from, to: to)
                } else {
                    //  We don't support this kind of complex change so far.
                    preconditionFailure("Multiple move or replacement of different number of element changes not supported (\(change) -> \(insertion))")
                }
            } else {
                //  A vanilla removal.
                self.broadcastingOrderedSet(broadcastingOrderedSet, willRemove: removal)
            }
        }
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willApply change: IndexedCollectionChange<ListenedElement>) {
        process(broadcastingOrderedSet: broadcastingOrderedSet, willApply: change)
    }


    //  Decomposes and calls the more specific Full Listener methods. Default implementation calls this, left as a
    //  separate method so it can be called in those cases where the default won't apply (i.e. overrides of classes
    //  implementing the vanilla listener protocol differently).
    func process(broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didApply change: IndexedCollectionChange<ListenedElement>) {
        //  Decompose the changes into calls to the more find grained methods.
        switch change {
        case .insertion(let insertion, let associatedRemoval):
            if let removal = associatedRemoval {
                //  Figure out if it's a move or a replace.
                if change.isReplacement {
                    //  It's a replacement.
                    self.broadcastingOrderedSet(broadcastingOrderedSet, didReplace: removal, with: insertion)
                } else if let (from, to) = change.singleMoveIndexes {
                    //  Report a didMove
                    self.broadcastingOrderedSet(broadcastingOrderedSet, didMove: insertion.elements[0] , from: from, to: to)
                } else {
                    //  We don't support this kind of complex change so far.
                    preconditionFailure("Multiple move or replacement of different number of element changes not supported (\(change) -> \(removal))")
                }
            } else {
                //  A vanilla insertion.
                self.broadcastingOrderedSet(broadcastingOrderedSet, didInsert: insertion)
            }

        case .removal(let removed, let associatedInsertion):
            //  If we have an associated it's the beginning of a move/replace so we don't need to report on didApply.
            if associatedInsertion == nil {
                //  Report as a did remove.
                self.broadcastingOrderedSet(broadcastingOrderedSet, didRemove: removed)
            }
        }
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didApply change: IndexedCollectionChange<ListenedElement>) {
        process(broadcastingOrderedSet: broadcastingOrderedSet, didApply: change)
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willInsert elementsAtIndexes: IndexedElements<ListenedElement>) {
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didInsert elementsAtIndexes: IndexedElements<ListenedElement>) {
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willRemove elementsFromIndexes: IndexedElements<ListenedElement>) {
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didRemove elementsFromIndexes: IndexedElements<ListenedElement>) {
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willMove element: ListenedElement, from fromIndex: Int, to toIndex: Int) {
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didMove element: ListenedElement, from fromIndex: Int, to toIndex: Int) {
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, willReplace replacees: IndexedElements<ListenedElement>, with replacements: IndexedElements<ListenedElement>) {
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<ListenedElement>, didReplace replacees: IndexedElements<ListenedElement>, with replacements: IndexedElements<ListenedElement>) {
    }
}
