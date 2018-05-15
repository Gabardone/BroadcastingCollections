//
//  EditableBroadcastingCollection.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/**
 Base protocol for all editable broadcasting collection types.

 Editable collection types are built one by one and set as the EditableBroadcastingCollection type in their respective
 CollectionTypes type wrapper as they are custom-built to the semantics of each collection type. This base protocol
 declares all the functionality common to them and allows for common behaviors to be defined.
 */
public protocol EditableBroadcastingCollection: BroadcastingCollection, TransactionEditable {

    /// The actual storage of the contents manager, should be held weakly. An implementation detail.
    var _contentsManager: BroadcastCollectionTypes.BroadcastingCollectionContentsManagerType? { get set }

    /**
     The optional contents manager, should be held weakly.

     This is cross-referenced with the contents manager managedContents property. However this property is what should
     be always set, and the cross-linked property should only ever be set by the implementation here.

     The behavior of an EditableBroadcastingCollection if edited manually while contentsManager is set and is not
     suspended is undefined.
     */
    var contentsManager: BroadcastCollectionTypes.BroadcastingCollectionContentsManagerType? { get set }

    /**
     contents is settable in an editable broadcasting collection. The default implementation will just call
     transformContents(into:) with the new value.
     */
    var contents: BroadcastCollectionTypes.CollectionType { get set }

    /**
     Applies a generic change. Useful for recording changesets and applying them with a delay.
     - Parameter change: The change to apply to the collection. It is up to the caller to make sure the change is valid
     for the contents at the time of calling.
     */
    func apply(change: CollectionChange<BroadcastCollectionTypes.ChangeDescription>)

    /**
     Transforms the broadcasting collection's contents into the given value. The editable broadcasting collection will
     calculate the most efficient set of changes to transform the current contents into the given ones and apply those
     changes consecutively.
     - Parameter newContents: The collection value to transform into.
     */
    func transformContents(into newContents: BroadcastCollectionTypes.CollectionType)
}


extension EditableBroadcastingCollection where BroadcastCollectionTypes.BroadcastingCollectionContentsManagerType.ManagedCollectionTypes.EditableBroadcastingCollectionType == Self {

    public weak var contentsManager: BroadcastCollectionTypes.BroadcastingCollectionContentsManagerType? {
        get {
            return _contentsManager
        }

        set {
            guard _contentsManager !== newValue else {
                return
            }

            if let outgoingContentsManager = _contentsManager {
                //  Clear out the outgoing contents manager managed content (yay mouthful).
                outgoingContentsManager.managedContents = nil
            }

            _contentsManager = newValue

            if let newContentsManager = _contentsManager {
                newContentsManager.managedContents = self
            }
        }
    }
}
