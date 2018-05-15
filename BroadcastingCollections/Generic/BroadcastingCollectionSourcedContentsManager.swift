//
//  BroadcastingCollectionSourcedContentsManager.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


extension TransactionIdentifier {
    static let inheritedTransaction = TransactionIdentifier(rawValue: "Inherited transaction from originator")
}


extension BroadcastingCollectionContentsManagerSuspensionReason {
    /// A sourced contents manager is suspended as long as no contents source is set.
    public static let nilContentsSource = BroadcastingCollectionContentsManagerSuspensionReason(rawValue: "Contents source is nil")

    /// This is set as a suspension reason while a new contents source is being set up in the contentsSource setter.
    public static let contentsSourceIsChanging = BroadcastingCollectionContentsManagerSuspensionReason(rawValue: "Contents source is being changed")
}


/**
 The protocol for a contents manager that is also sourced by a broadcasting collection.

 Implementers of this protocol allow for easy chaining of broadcasting collections and their listeners to build up
 sophisticated collection logic, including its change management.
 */
public protocol BroadcastingCollectionSourcedContentsManager: BroadcastingCollectionSourced, BroadcastingCollectionContentsManager {

    /// Actual storage of the contents source. Implementation detail.
    var _contentsSource: ListenedCollectionTypes.BroadcastingCollectionType? { get set }

    /** Called for every single element added to the contents source broadcasting collection

     After receiving a broadcast change involving the addition of elements to the contents source broadcasting
     collection this method is called for each of the newly inserted elements so we can do run any logic needed to keep
     track of updates based on the state of them.
     - Parameter element: The element newly appeared in the contents source broadcasting collection.
     */
    func startUpdating(_ element: ListenedCollectionTypes.ElementType)


    /** Called for every single element about to be removed from the contents source broadcasting collection

     After being broadcast that elements will be removed from the contents source broadcasting collection this method is
     called for each of them so we can do run any logic needed to stop keeping track of updates based on the state of
     those elements.
     - Parameter element: The element about to be removed from the contents source broadcasting collection.
     */
    func stopUpdating(_ element: ListenedCollectionTypes.ElementType)
}


extension BroadcastingCollectionSourcedContentsManager {

    public func startUpdating(_ element: ListenedCollectionTypes.ElementType) {
        //  Default implementation does nothing.
    }


    public func stopUpdating(_ element: ListenedCollectionTypes.ElementType) {
        //  Default implementation does nothing.
    }

    //  MARK: BroadcastingCollectionSourced Implementation.

    public var contentsSource: ListenedCollectionTypes.BroadcastingCollectionType? {
        get {
            return _contentsSource
        }

        set {
            if _contentsSource !== newValue {
                //  We make sure updates are suspended for the duration of the setter.
                //  Will conveniently stop listening to the outgoing contents source if it was before and do transaction
                //  management.
                suspendUpdating(for: .contentsSourceIsChanging)

                let oldValue = _contentsSource
                if oldValue != nil && newValue == nil {
                    suspendUpdating(for: .nilContentsSource)
                }

                _contentsSource = newValue

                if _contentsSource != nil && oldValue == nil {
                    resumeUpdating(for: .nilContentsSource)
                }

                //  Now that everything is in place, we no longer need to keep this suspension reason.
                //  Will conveniently start listening to the incoming contents source if nothing else has it suspended.
                //  Will even more conveniently add inherited transactions for the contents source if warranted.
                //  Also conveniently will set the managedContents to calculatedContents
                resumeUpdating(for: .contentsSourceIsChanging)
            }
        }
    }


    public func validateContentsSource(forSource source: ListenedCollectionTypes.BroadcastingCollectionType, called function: String) {
        guard source === contentsSource else {
            //  We got nothing to do with broadcasting collections other than contentsSource even if a subclass listens to others.
            preconditionFailure("Received broadcast \(#function) from source \(source) different from contentsSource \(String(describing: contentsSource))")
        }

        guard isUpdating else {
            //  We shouldn't ever receive this if we're not updating.
            preconditionFailure("Received broadcast \(#function) from source \(source) despite being suspended due to \(suspensionReasons)")
        }
    }
}
