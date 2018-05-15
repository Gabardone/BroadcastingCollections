//
//  EditableBroadcastingSet.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


extension TransactionIdentifier {
    static let editableBroadcastingSetComplexTransform = TransactionIdentifier(rawValue: "The editable broadcasting set is undergoing a complex transform")
}


public final class EditableBroadcastingSet<Element: Hashable>: BroadcastingSet<Element>, EditableBroadcastingCollection {

    /// Default intializer for an empty editable broadcasting set.
    public override init() {
    }

    //  MARK: - EditableBroadcastingCollection Implementation

    public var _contentsManager: BroadcastingSetContentsManager<Element>? = nil

    //  MARK: - EditableBroadcastingCollection Storage

    private var _mutableContents = Set<Element>()

    override public var contents: Set<Element> {
        get {
            return _mutableContents
        }

        set {
            transformContents(into: newValue)
        }
    }

    //  MARK: - TransactionEditable Storage

    private var _ongoingTransactions = CountedSet<TransactionInfo>()

    public override var ongoingTransactions: CountedSet<TransactionInfo> {
        get {
            return _ongoingTransactions
        }

        set {
            _ongoingTransactions = newValue
        }
    }
}

//  MARK: - EditableBroadcastingSet API

extension EditableBroadcastingSet {

    /**
     Adds an element to the contents set.

     - Parameter element: The elment to add. If element is already in the method will do nothing.
     */
    public func add(_ element: Element) {
        guard !_mutableContents.contains(element) else {
            return
        }

        let addedSet = Set([element])

        _reallyAdd(addedSet)
    }


    /**
     */
    public func add(_ elements: Set<Element>) {
        let actuallyAddedElements = elements.subtracting(_mutableContents)

        if actuallyAddedElements.count > 0 {
            _reallyAdd(actuallyAddedElements)
        }
    }


    private func _reallyAdd(_ elements: Set<Element>) {
        let listeners = self.listeners
        let change = SetChange.insertion(elements, associatedRemoval: nil)

        listeners.forEach({ (listener) in
            listener.broadcastingSet(self, willApply: change)
        })

        _mutableContents.formUnion(elements)

        listeners.forEach({ (listener) in
            listener.broadcastingSet(self, didApply: change)
        })
    }


    public func remove(_ element: Element) {
        guard _mutableContents.contains(element) else {
            return
        }

        let removedSet = Set([element])

        _reallyRemove(removedSet)
    }


    public func remove(_ elements: Set<Element>) {
        let actuallyRemovedElements = elements.intersection(_mutableContents)

        if actuallyRemovedElements.count > 0 {
            _reallyRemove(actuallyRemovedElements)
        }
    }


    private func _reallyRemove(_ elements: Set<Element>) {
        let listeners = self.listeners
        let changeSet = SetChange.removal(elements, associatedInsertion: nil)

        listeners.forEach({ (listener) in
            listener.broadcastingSet(self, willApply: changeSet)
        })

        _mutableContents.subtract(elements)

        listeners.forEach({ (listener) in
            listener.broadcastingSet(self, didApply: changeSet)
        })
    }
}

//  MARK: - EditableBroadcastingCollection Implementation

extension EditableBroadcastingSet {

    public func apply(change: SetChange<Element>) {
        //  For the time being there's no support for anything other than insert/remove, so we ignore associated.
        switch change {
        case .insertion(let inserted, associatedRemoval: _):
            add(inserted)

        case .removal(let removed, associatedInsertion: _):
            remove(removed)
        }
    }


    public func transformContents(into newContents: Set<Element>) {
        if _mutableContents != newContents {
            let removedElements = _mutableContents.subtracting(newContents)
            let addedElements = newContents.subtracting(_mutableContents)

            let doesRemoval = !removedElements.isEmpty
            let doesInsertion = !addedElements.isEmpty

            switch (doesRemoval, doesInsertion) {
            case (true, false):
                _reallyRemove(removedElements)

            case (false, true):
                _reallyAdd(addedElements)

            case (true, true):
                //  Wrap it all in a transaction.
                perform(transactionWithIdentifier: .editableBroadcastingSetComplexTransform) { () -> (Void) in
                    //  Remove first
                    _reallyRemove(removedElements)

                    //  Add second
                    _reallyAdd(addedElements)
                }

            case (false, false):
                preconditionFailure("Attempting to transform the contents with unequal source and destination but no insertions or removals found")
            }
        }
    }
}

//  MARK: - TransactionEditable Implementation

extension EditableBroadcastingSet {

    public func setupTransactionEnvironment() {
        makeListeners { (listener) in
            listener.broadcastingSetWillBeginTransactions(self)
        }
    }

    public func tearDownTransactionEnvironment() {
        makeListeners { (listener) in
            listener.broadcastingSetDidEndTransactions(self)
        }
    }
}
