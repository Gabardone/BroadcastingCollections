//
//  BroadcastingSetMixer.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


open class BroadcastingSetMixer<Element: Hashable>: BroadcastingSet<Element>, MultiBroadcastingSetSourced, TransactionEditable {

    /**
     Override this method to return the expected contents. Normally you don't call this method, it'll be called by the
     implementation whenever the totality of the managed contents needs to be up to date.

     - Returns: The expected contents for the caller.
     */
    open func calculatedContents(for sources: Set<BroadcastingSet<Element>>) -> Set<Element> {
        preconditionFailure("Attempted to call abstract function \(#function)")
    }


    open func appliedElements(for elements: Set<Element>, against contentsSources: Set<BroadcastingSet<Element>>) -> Set<Element> {
        preconditionFailure("Attempted to call abstract function \(#function)")
    }

    /**
     Calculates the change to apply for a given incoming change from a broadcasting set.

     - Precondition: broadcasingSet is contained within contentsSources
     - Parameter change: The incoming change.
     - Parameter broadcastingSet: The broadcasting set that broadcast change.
     - Returns: The change we should broadcast to our own listeners, or nil if no change should be broadcast.
     */
    final public func appliedChange(for change: SetChange<Element>, comingFrom broadcastingSet: BroadcastingSet<Element>) -> SetChange<Element>? {
        //  If the element is in any other broadcasting set it won't affect our calculated contents.
        let otherContentsSources = contentsSources.subtracting([broadcastingSet])

        switch change {
        case .insertion(let insertedElements, let associatedRemoval):
            let appliedInsertion = appliedElements(for: insertedElements, against: otherContentsSources)
            if !appliedInsertion.isEmpty {
                let appliedAssociatedRemoval: Set<Element>?
                if let removal = associatedRemoval {
                    appliedAssociatedRemoval = appliedElements(for: removal, against: otherContentsSources)
                } else {
                    appliedAssociatedRemoval = nil
                }

                return .insertion(appliedInsertion, associatedRemoval: appliedAssociatedRemoval)
            }

        case .removal(let removedElements, let associatedInsertion):
            let appliedRemoval = appliedElements(for: removedElements, against: otherContentsSources)
            if !appliedRemoval.isEmpty {
                let appliedAssociatedInsertion: Set<Element>?
                if let insertion = associatedInsertion {
                    appliedAssociatedInsertion = appliedElements(for: insertion, against: otherContentsSources)
                } else {
                    appliedAssociatedInsertion = nil
                }

                return .removal(appliedRemoval, associatedInsertion: appliedAssociatedInsertion)
            }
        }

        return nil
    }

    //  MARK: - MultiBroadcastingSetSourced Implementation

    /// Actual storage.
    private var _contentsSources: Set<BroadcastingSet<Element>> = []


    public var contentsSources: Set<BroadcastingSet<ListenedElement>> {
        get {
            return _contentsSources
        }

        set {
            if _contentsSources != newValue {
                let outgoingBroadcastingSets = _contentsSources.subtracting(newValue)
                let incomingBroadcastingSets = newValue.subtracting(_contentsSources)

                //  Only need to clean up if we were doing something.
                let wasExecutingTransactions = isExecutingTransactions

                //  Wrap it all in a transaction.
                let contentsSourcesChangeTransaction = TransactionInfo(identifier: .contentsSourcesAreChanging, originator: self)
                beginTransaction(withInfo: contentsSourcesChangeTransaction)

                //  Remove inherited transactions from outgoing.
                if wasExecutingTransactions {
                    for outgoingSource in outgoingBroadcastingSets {
                        let inheritedTransaction = TransactionInfo(identifier: .inheritedTransaction, originator: outgoingSource)
                        if ongoingTransactions.contains(inheritedTransaction) {
                            endTransaction(withInfo: inheritedTransaction)
                        }
                    }
                }

                //  Stop listening to outgoing sources.
                for outgoingBroadcastingSet in outgoingBroadcastingSets {
                    outgoingBroadcastingSet.remove(listener: self)
                }

                if hasListeners {
                    //  Calculate the differences and retransmit them.
                    let outgoingContents = calculatedContents(for: _contentsSources)
                    let incomingContents = calculatedContents(for: newValue)
                    let changes = outgoingContents.changes(toBecome: incomingContents)
                    let listeners = self.listeners

                    for change in changes {
                        for listener in listeners {
                            listener.broadcastingSet(self, willApply: change)
                        }
                    }

                    _contentsSources = newValue

                    for change in changes {
                        for listener in listeners {
                            listener.broadcastingSet(self, didApply: change)
                        }
                    }
                } else {
                    //  Keep it simple.
                    _contentsSources = newValue
                }

                //  Start listening to any incoming broadcasting sets.
                for incomingBroadcastingSet in incomingBroadcastingSets {
                    incomingBroadcastingSet.add(listener: self)
                }

                //  Add any inherited transaction for anything incoming that is in the middle of something.
                for incomingSource in incomingBroadcastingSets {
                    if incomingSource.isExecutingTransactions {
                        beginTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: incomingSource))
                    }
                }

                endTransaction(withInfo: contentsSourcesChangeTransaction)
            }
        }
    }

    //  MARK: - BroadcastingSet Overrides

    var _cachedContents: Set<Element>?

    public override var contents: Set<Element> {
        if let cachedContents = _cachedContents {
            return cachedContents
        } else {
            _cachedContents = calculatedContents(for: contentsSources)
            return _cachedContents!
        }
    }

    //  MARK: - BroadcastingSetListener implementation

    public typealias ListenedElement = Element

    public typealias ListenedCollectionTypes = SetTypesWrapper<Element>

    public func broadcastingSetWillBeginTransactions(_ broadcastingSet: BroadcastingSet<Element>) {
        validateContentsSource(forBroadcasting: broadcastingSet, called: #function)

        let inheritedTransactionInfo = TransactionInfo(identifier: .inheritedTransaction, originator: broadcastingSet)

        //  We don't want this transaction to happen more than once.
        guard !ongoingTransactions.contains(inheritedTransactionInfo) else {
            preconditionFailure("Broadcasting set source \(broadcastingSet) has somehow started transactions more than once.")
        }

        //  Carry our own transaction management.
        beginTransaction(withInfo: inheritedTransactionInfo)
    }


    public func broadcastingSetDidEndTransactions(_ broadcastingSet: BroadcastingSet<Element>) {
        validateContentsSource(forBroadcasting: broadcastingSet, called: #function)

        endTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: broadcastingSet))
    }


    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<Element>, willApply change: SetChange<Element>) {
        //  Other than validation it's a nop. Call super from inherited!
        validateContentsSource(forBroadcasting: broadcastingSet, called: #function)

        if let appliedChange = appliedChange(for: change, comingFrom: broadcastingSet) {
            //  Cache is no longer good.
            _cachedContents = nil

            //  Broadcast to our own listeners.
            makeListeners { (listener) in
                listener.broadcastingSet(self, willApply: appliedChange)
            }
        }
    }


    public func broadcastingSet(_ broadcastingSet: BroadcastingSet<Element>, didApply change: SetChange<Element>) {
        //  Other than validation it's a nop. Call super from inherited!
        validateContentsSource(forBroadcasting: broadcastingSet, called: #function)

        if let appliedChange = appliedChange(for: change, comingFrom: broadcastingSet) {
            //  Cache is no longer good.
            _cachedContents = nil

            //  Broadcast to our own listeners.
            makeListeners { (listener) in
                listener.broadcastingSet(self, didApply: appliedChange)
            }
        }
    }

    //  MARK: - TransactionEditable Implementation

    public func setupTransactionEnvironment() {
        //  A nop
    }

    public func tearDownTransactionEnvironment() {
        //  A nop
    }

    //  MARK: - TransactionSupport Overrides

    private var _ongoingTransactions = CountedSet<TransactionInfo>()

    override public var ongoingTransactions: CountedSet<TransactionInfo> {
        get {
            return _ongoingTransactions
        }

        set {
            _ongoingTransactions = newValue
        }
    }
}
