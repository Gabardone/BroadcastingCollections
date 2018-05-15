//
//  EditableBroadcastingDictionary.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


public final class EditableBroadcastingDictionary<Key: Hashable, Value: Equatable> : BroadcastingDictionary<Key, Value>, TransactionEditable {

    private var _mutableContents: Dictionary<Key, Value> = [:]

    //  Content Access
    //  Contents is settable. The broadcasting dictionary will transform the existing contents into the given ones following these steps:
    //  - Remove key/value pairs not present in the incoming contents
    //  - Replace values for keys already present where the new value is different.
    //  - Insert key/value pairs not present in original contents.
    public override var contents: Dictionary<Key, Value> {
        get {
            return super.contents
        }

        set {
            if _mutableContents != newValue {
                //  Find out which ones we remove and replace.
                var removalDictionary = Dictionary<Key, Value>()
                var outgoingReplacementDictionary = Dictionary<Key, Value>()
                var incomingReplacementDictionary = Dictionary<Key, Value>()

                _mutableContents.forEach({ (key, value) in
                    if let newValueForKey = newValue[key] {
                        if newValueForKey != value {
                            //  It's a replacement
                            outgoingReplacementDictionary[key] = value
                            incomingReplacementDictionary[key] = newValueForKey
                        }
                    } else {
                        //  It's a removal.
                        removalDictionary[key] = value
                    }
                })

                let insertionDictionary = (newValue.count - incomingReplacementDictionary.count) > 0 ? newValue.filter({ (key, _) -> Bool in
                    return _mutableContents[key] == nil
                }) : [:]

                let doesRemoval = !removalDictionary.isEmpty
                let doesReplacement = !outgoingReplacementDictionary.isEmpty
                let doesInsertion = !insertionDictionary.isEmpty

                //  Check if it's going to involve more than one type of operation.
                let isComplexOperation = ((doesRemoval ? 0 : 1) + (doesReplacement ? 0 : 1) + (doesInsertion ? 0 : 1)) > 1
                if isComplexOperation {
                    makeListeners(perform: { (listener) in
                        listener.broadcastingDictionaryWillBeginTransactions(self)
                    })
                }

                if doesRemoval {
                    _reallyRemove(removalDictionary)
                }

                if doesReplacement {

                }

                if doesInsertion {

                }

                if isComplexOperation {
                    makeListeners(perform: { (listener) in
                        listener.broadcastingDictionaryDidEndTransactions(self)
                    })
                }
            }
        }
    }

    //  MARK: TransactionEditable Implementation

    public var transactionStackCount: Int = 0
}


extension EditableBroadcastingDictionary {

    func _reallyInsert(_ keyValues: Dictionary<Key, Value>) {
        //  This is the one that does the stuff with no validation whatsoever.

        let listeners = self.listeners
        let changeSet = DictionaryChange.insertion(keyValues, associatedRemoval: nil)

        listeners.forEach({ (listener) in
            listener.broadcastingDictionary(self, willApply: changeSet)
        })

        //  We merge knowing that all the incoming keys don't already exist in the dictionary.
        _mutableContents.merge(keyValues, uniquingKeysWith: { (_, incomingValue) -> Value in
            return incomingValue
        })

        listeners.forEach({ (listener) in
            listener.broadcastingDictionary(self, didApply: changeSet)
        })
    }


    public func remove(_ keys: Set<Key>) {
        var actuallyRemovedPairs = Dictionary<Key, Value>()
        keys.forEach { (key) in
            if let value = _mutableContents[key] {
                actuallyRemovedPairs[key] = value
            }
        }

        if !actuallyRemovedPairs.isEmpty {
            _reallyRemove(actuallyRemovedPairs)
        }
    }


    func _reallyRemove(_ keyValues: Dictionary<Key, Value>) {
        //  This is the one that does the stuff with no validation whatsoever.

        let listeners = self.listeners
        let changeSet = DictionaryChange.removal(keyValues, associatedInsertion: nil)

        listeners.forEach({ (listener) in
            listener.broadcastingDictionary(self, willApply: changeSet)
        })

        //  Interestingly enough there's no API to remove a bunch of keys at once from a dictionary.
        for (key, _) in keyValues {
            _mutableContents.removeValue(forKey: key)
        }

        listeners.forEach({ (listener) in
            listener.broadcastingDictionary(self, didApply: changeSet)
        })
    }


    func _reallyReplace(_ replacements: Dictionary<Key, Value>) {
        //  This is the one that does the stuff with no validation whatsoever.

        //  Let's calculate the change set (a bit overwrought due to associated interdependency.
        var replacees = Dictionary<Key, Value>()
        replacements.forEach { (key, value) in
            replacees[key] = value
        }

        let removalChange = DictionaryChange<Key, Value>.removal(replacees, associatedInsertion: replacements)
        let insertionChange = DictionaryChange<Key, Value>.insertion(replacements, associatedRemoval: replacees)

        let listeners = self.listeners
        listeners.forEach { (listener) in
            listener.broadcastingDictionary(self, willApply: removalChange)
            listener.broadcastingDictionary(self, willApply: insertionChange)
        }

        //  We merge knowing that all the incoming keys don't already exist in the dictionary.
        _mutableContents.merge(replacements, uniquingKeysWith: { (_, incomingValue) -> Value in
            return incomingValue
        })

        listeners.forEach { (listener) in
            listener.broadcastingDictionary(self, didApply: removalChange)
            listener.broadcastingDictionary(self, didApply: insertionChange)
        }
    }
}

//  MARK: TransactionEditable Implementation

extension EditableBroadcastingDictionary {

    public func setupTransactionEnvironment() {
        makeListeners(perform: { (listener) in
            listener.broadcastingDictionaryWillBeginTransactions(self)
        })
    }


    public func tearDownTransactionEnvironment() {
        makeListeners(perform: { (listener) in
            listener.broadcastingDictionaryDidEndTransactions(self)
        })
    }
}
