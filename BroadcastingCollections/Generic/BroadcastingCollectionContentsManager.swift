//
//  BroadcastingCollectionContentsManager.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/**
 Extensible String enum for detailing an contents manager suspension reason.

 A contents manager stores these when suspended and allows for the same reason value to be used several times (balanced
 with suspension resuming the same amount). The reason being a string enum helps with debugging if the suspend/resume
 calls end up unbalanced or it's unclear why a contents manager is suspended.
 */
public struct BroadcastingCollectionContentsManagerSuspensionReason : RawRepresentable, Equatable, Hashable {

    public typealias RawValue = String


    public let rawValue: RawValue


    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }


    public var hashValue: Int {
        return rawValue.hashValue
    }


    public static func ==(lhs: BroadcastingCollectionContentsManagerSuspensionReason, rhs: BroadcastingCollectionContentsManagerSuspensionReason) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}


extension BroadcastingCollectionContentsManagerSuspensionReason {
    /**
     Broadcasting collection contents managers are automatically suspended if not attached to an editable broadcasting
     collection.

     This suspension reason is automatically set on a broadcasting collection contents manager on creation.
     */
    public static let nilManagedContents = BroadcastingCollectionContentsManagerSuspensionReason(rawValue: "BroadcastingCollectionContentsManager: managedContents is nil")

    /**
     Broadcasting collection contents managers should be suspended during deallocation to avoid spurious change
     broadcasting or other glitches.
     */
    public static let deallocating = BroadcastingCollectionContentsManagerSuspensionReason(rawValue: "BroadcastingCollectionContentsManager: deallocating")
}


/**  Broadcasting Collection Contents Managers ("contents manager/s" for short) are set on an editable broadcasting
 collection. Once set they manage the contents of the editable broadcasting collection as their name implies.

 A contents manager can be temporarily suspended through a call to suspendUpdating(forReason:). While suspended, the
 contents manager will not affect the contents of its set editable broadcasting collection. Once updates are resumed
 through balanced calls to resumeUpdating(forReason:) the contents manager will ensure that the contents of the managed
 contents editable broadcasting collection are as expected, usually applying a diff to those contents. This allows for
 dealing with situations where momentarily we can't trust automated contents management to properly keep the contents
 we want as we, for example, need to perform async operations and wait for delayed callbacks to bring us back to a state
 where we can trust the contents manager to do its job correctly.

 The base protocol just declares the methods required to implement suspension behavior and offers default behavior for
 most of those. Actual implementations are expected to offer a named managedContents optional property
 of the right type, and should implement the parts of the protocol where default behavior isn't offered.

 A number of basic contents managers are offered through the library. Most of them are meant to be built upon through
 quick subclassing or composition. They are also a good model for how to build a custom one if needed.
 */
public protocol BroadcastingCollectionContentsManager: class where Self.ManagedCollectionTypes.EditableBroadcastingCollectionType.BroadcastCollectionTypes.CollectionType == Self.ManagedCollectionTypes.CollectionType {

    associatedtype ManagedCollectionTypes: CollectionTypesWrapper

    /// Implementation detail, but allows us to define the setter/getter logic for all possible types of contents managers.
    var _managedContents: ManagedCollectionTypes.EditableBroadcastingCollectionType? { get set }

    /**
     The managed contents, held strongly. An optional so the contents manager can be easily reused and held onto.

     Do NOT set this property, only the EditableBroadcastingContentManager should set it. It is declared settable due
     to limitations in the Swift type system.
     */
    var managedContents: ManagedCollectionTypes.EditableBroadcastingCollectionType? { get set }

    /**
     Storage for the current suspension reasons.

     The property is declared settable for implementation reasons. Do not set outside of the internals of the
     default protocol implementation.
     */
    var suspensionReasons: CountedSet<BroadcastingCollectionContentsManagerSuspensionReason> { get set }

    /** Returns true if the contents manager is currently not suspended. By default turns to YES if the managed contents
     editable broadcasting collection is set and no one has called suspendUpdates.

     - Note: When created, a contents manager is suspended (isUpdating == false). Setting it up properly will make it
     start updating, unless extra calls to suspendUpdating are made for whatever reason or the initial setup involves
     more reasons for its suspension.
     */
    var isUpdating: Bool { get }

    /**
     Call this to suspend automatic updates of the managed contents broadcasting collection.

     - Note: Resuming updates can be a relatively costly operation as it involves a full diff of the managed contents
     against calculatedContents, so it's best to avoid too frequent suspensions.

     - Parameter reason: The reason for the suspension. The same value can be used multiple times, and they will stack,
     needing an equal number of calls to resumeUpdating for the same reason.
     */
    func suspendUpdating(for reason: BroadcastingCollectionContentsManagerSuspensionReason)

    /** Call this to lift out a reason for suspension of updates.

     If after this call there are no more suspension reasons stored, the managed contents broadcasting collection
     contents will be transformed into calculatedContents and after that automatic updates will resume.

     - Precondition: Updates have been suspended at least once due to the given reason.

     - Note: Resuming updates can be a relatively costly operation as it involves a full diff of the updated contents
     against calculatedContents, so it's best to avoid too frequent suspensions.

     - Parameter reason: The reason for the suspension lifted. The same value can be used multiple times, and they will
     stack, needing an equal number of calls to resumeUpdating for the same reason.
     */
    func resumeUpdating(for reason: BroadcastingCollectionContentsManagerSuspensionReason)


    /** Called when all suspension reasons are lifted and the contents manager should resume automatically managing the
     contents of its managedContents editable broadcasting collection.

     Do not call this directly, call resumeUpdating and this method will be called if there are no suspension reasons
     left.

     A base class implementation should set the managed contents to the result of calculateContents().

     - Note: When setting the managedContents, this will be called after the set operation itself has been performed so
     the new managedContents can be counted to already be in place.
     */
    func startUpdating()


    /** Called when we need to stop automatic contents management because a suspension reason was set.

     Do not call this directly, call suspendUpdating and this method will be called if there were no suspension reasons
     before.

     Always call super in your overrides so we don't run into trouble if we ever end up putting any functionality in
     here.

     - Note: When replacing or removing managedContents, this will be called before the actual set operation happens and
     so the managed contents editable broadcasting collection can still be counted to be in place.
     */
    func stopUpdating()

    /**
     Calculates the full of the contents collection. Used when initially set up and in other instances where we need
     to ensure the whole contents are what we expect.

     - Returns: The collection we'd expect our managedContents (whether we have any or not at the moment) to be.
     */
    func calculateContents() -> ManagedCollectionTypes.CollectionType
}


/// Default implementation for basic suspension functionality.
extension BroadcastingCollectionContentsManager {

    public var isUpdating: Bool {
        //  Will be updating if no suspension reasons are active.
        return suspensionReasons.isEmpty
    }


    public func suspendUpdating(for reason: BroadcastingCollectionContentsManagerSuspensionReason) {
        let wasNotSuspended = isUpdating

        suspensionReasons.insert(reason)

        if wasNotSuspended {
            stopUpdating()
        }
    }


    public func resumeUpdating(for reason: BroadcastingCollectionContentsManagerSuspensionReason) {
        guard suspensionReasons.contains(reason) else {
            //  No seriously, we are not going to remains silent while you mess up the suspend/resume balance.
            preconditionFailure("Attempted to resume updates for reason \(reason.rawValue), which had not been suspeneded")
        }

        suspensionReasons.remove(reason)

        if isUpdating {
            startUpdating()
        }
    }


    /**
     Basic behavior for startUpdating.

     The default behavior for startUpdating() checks that the managedContents are set and diffs the managed content
     into the expected content for the contents manager.

     Due to swift's inability to override or call extension-defined functions, this is offered as a utility for
     implementors to call.
     */
    public func basicStartUpdating() {
        guard let managedContents = self.managedContents else {
            preconditionFailure("Starting updates with no managedContents set.")
        }

        //  Need to make sure the contents are set back to what they should.
        //  This may be a bit expensive if many changes have happened during suspension.
        managedContents.contents = calculateContents()
    }


    public func startUpdating() {
        basicStartUpdating()
    }


    /**
     Basic behavior for startUpdating.

     The default behavior for stopUpdating() checks that the managedContents are still set and winds down any
     outstanding transactions in the managed contents, so behavior while suspended doesn't get out of sync with
     transaction count.

     Due to swift's inability to override or call extension-defined functions, this is offered as a utility for
     implementors to call.
     */
    public func basicStopUpdating() {
        guard let managedContents = self.managedContents else {
            preconditionFailure("Stopping updates with no managedContents set.")
        }

        //  Wind down any transactions we may have active.
        while let transaction = managedContents.ongoingTransactions.any {
            managedContents.endTransaction(withInfo: transaction)
        }
    }


    public func stopUpdating() {
        basicStopUpdating()
    }
}


/// Default implementation of managedContents property setup.
extension BroadcastingCollectionContentsManager where ManagedCollectionTypes.EditableBroadcastingCollectionType.BroadcastCollectionTypes.BroadcastingCollectionContentsManagerType == Self {

    public var managedContents: ManagedCollectionTypes.EditableBroadcastingCollectionType? {
        get {
            return _managedContents
        }

        set {
            guard _managedContents !== newValue else {
                return
            }

            let oldValueWasNil = _managedContents == nil
            if !oldValueWasNil && newValue == nil {
                if newValue == nil {
                    //  Suspend updates as there'll be nothing to update after we set nil.
                    suspendUpdating(for: .nilManagedContents)
                }
            }

            _managedContents = newValue

            if oldValueWasNil && _managedContents != nil {
                //  We used to be suspended for not having a set managedContents to manage.
                resumeUpdating(for: .nilManagedContents)
            }
        }
    }
}
