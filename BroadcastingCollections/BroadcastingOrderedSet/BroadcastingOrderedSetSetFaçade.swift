//
//  BroadcastingOrderedSetSetFaçade.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


final class BroadcastingOrderedSetSetFaçade<Element: Hashable & AnyObject>: BroadcastingSet<Element>, BroadcastingOrderedSetListener {

    typealias ListenedBroadcasterType = BroadcastingOrderedSet<Element>

    typealias ListenedCollectionTypes = OrderedSetTypesWrapper<Element>


    let originalBroadcaster: BroadcastingOrderedSet<Element>


    public init(for broadcaster: BroadcastingOrderedSet<Element>) {
        originalBroadcaster = broadcaster

        super.init()

        broadcaster.add(listener: self)
    }


    public override var contents: Set<Element> {
        return originalBroadcaster.contents.set as! Set<Element>
    }

    //  MARK: BroadcastingOrderedSet Implementation

    public func broadcastingOrderedSetWillBeginTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>) {
        makeListeners { (listener) in
            listener.broadcastingSetWillBeginTransactions(self)
        }
    }


    public func broadcastingOrderedSetDidEndTransactions(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>) {
        makeListeners { (listener) in
            listener.broadcastingSetDidEndTransactions(self)
        }
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willApply change: IndexedCollectionChange<Element>) {
        if hasListeners {
            //  Process the indexed changeset into a set changeset.
            //  We need to detect moves and ignore them.
            guard !change.isMove else {
                return
            }

            let setChange: SetChange<Element>
            switch change {
            case .insertion(let insertion, _):
                let insertedElements = Set(insertion.elements)
                setChange = SetChange.insertion(insertedElements, associatedRemoval: nil)

            case .removal(let removal, _):
                if change.isReplacement {
                    //  This change is the start of a replacement.
                    makeListeners(perform: { (listener) in
                        listener.broadcastingSetWillBeginTransactions(self)
                    })
                }

                let removedElements = Set(removal.elements)
                setChange = SetChange.removal(removedElements, associatedInsertion: nil)
            }

            makeListeners(perform: { (listener) in
                listener.broadcastingSet(self, willApply: setChange)
            })

        }
    }


    func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didApply change: IndexedCollectionChange<Element>) {
        if hasListeners {
            if change.isMove {
                //  We're skipping move changes.
                return
            }

            switch change {
            case .insertion(let insertion, _):
                let insertedElements = Set(insertion.elements)
                makeListeners(perform: { (listener) in
                    listener.broadcastingSet(self, didApply: SetChange.insertion(insertedElements, associatedRemoval: nil))
                })

                if change.isReplacement {
                    //  This change was the end of a replacement.
                    makeListeners(perform: { (listener) in
                        listener.broadcastingSetDidEndTransactions(self)
                    })
                }

            case .removal(let removal, _):
                let removedElements = Set(removal.elements)
                makeListeners(perform: { (listener) in
                    listener.broadcastingSet(self, didApply: SetChange.removal(removedElements, associatedInsertion: nil))
                })
            }
        }
    }
}
