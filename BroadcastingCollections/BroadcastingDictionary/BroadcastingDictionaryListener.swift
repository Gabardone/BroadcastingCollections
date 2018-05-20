//
//  BroadcastingDictionaryListener.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/**
 A protocol for types who subscribe to BroadcastingDictionary changes.
 */
public protocol BroadcastingDictionaryListener: BroadcastingCollectionListener where ListenedCollectionTypes == DictionaryTypesWrapper<ListenedKeyType, ListenedValueType> {

    /// Key type for the broadcasting dictionaries this listener can listen to.
    associatedtype ListenedKeyType: Hashable

    /// Value type for the broadcasting dictionaries this listener can listen to.
    associatedtype ListenedValueType: Equatable


    /**
     Called by a listened broadcasting dictionary right before starting transactions.

     You can implement this method to make any preparations to record or otherwise deal with the fact that the listened
     broadcasting dictionary will be performing transactions. For example if you don't plan on reacting to changes
     during transactions but still expect to be able to refer to the original values, you may want to store a copy of
     the current contents.

     - Note: At the point of the call broadcaster.isExecutingTransactions will still be false.
     - Parameter broadcastingDictionary: The broadcasting dictionary about to begin performing transactions.
     */
    func broadcastingDictionaryWillBeginTransactions(_ broadcastingDictionary: BroadcastingDictionary<ListenedKeyType, ListenedValueType>)


    /**
     Called by a broadcasting dictionary right after transactions are all done.

     A good opportunity to update your layer if you didn't want to reflect every single change happening within the
     transactions, or to close out any logic intended to deal with them.

     - Note: At the point of the call broadcaster.isExecutingTransactions will be back to false.
     - Parameter broadcastingDictionary: The broadcasting dictionary that just ended performing transactions.
     */
    func broadcastingDictionaryDidEndTransactions(_ broadcastingDictionary: BroadcastingDictionary<ListenedKeyType, ListenedValueType>)


    /**
     Broadcast by the broadcasting dictionary right before applying a change.

     Implement this method to prepare for the upcoming changes. For example it's the perfect time to stop caring about
     anything in the collection that is about to be removed from it.

     - Note: At the point of the call broadcaster.contents is guaranteed to not have the given change applied to it.

     - Parameter broadcastingDictionary: The broadcasting dictionary about to apply the given change.
     - Parameter change: The change about to be applied. Refer to the dictionary type's change documentation for
     further details.
     */
    func broadcastingDictionary(_ broadcastingDictionary: BroadcastingDictionary<ListenedKeyType, ListenedValueType>, willApply change: DictionaryChange<ListenedKeyType, ListenedValueType>)


    /**
     Broadcast by the broadcasting dictionary right after applying a change.

     Implement this method to deal with the changes that have just happened in the dictionary. Update your UI, deal with
     newly inserted objects etc.

     - Note: At the point of the call broadcaster.contents is guaranteed to have the given change already applied to it.

     - Parameter broadcastingDictionary: The broadcasting dictionary that has just applied the given change.
     - Parameter change: The change that has just been applied. Refer to the dictionary type's change documentation for
     further details.
     */
    func broadcastingDictionary(_ broadcastingDictionary: BroadcastingDictionary<ListenedKeyType, ListenedValueType>, didApply change: DictionaryChange<ListenedKeyType, ListenedValueType>)
}
