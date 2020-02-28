//
//  TransactionSupport.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/**
 Extensible String enum for a transaction's identifier name.

 These are stored in a contents set together with the object responsible for them, so a broadcasting collection being
 performing transactions can be tracked in a more sophisticated way than just a counter.
 */
public struct TransactionIdentifier : RawRepresentable, Equatable, Hashable {

    public typealias RawValue = String


    public let rawValue: RawValue


    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }


    public var hashValue: Int {
        return rawValue.hashValue
    }


    public static func ==(lhs: TransactionIdentifier, rhs: TransactionIdentifier) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}


public struct TransactionInfo: Hashable {

    init(identifier: TransactionIdentifier, originator: TransactionSupport) {
        self.identifier = identifier
        self.originator = originator
    }

    var identifier: TransactionIdentifier

    var originator: TransactionSupport

    //  MARK: Hashable Implementation

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier.hashValue)
        hasher.combine(ObjectIdentifier(originator).hashValue)
    }


    public static func == (lhs: TransactionInfo, rhs: TransactionInfo) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.originator === rhs.originator
    }
}


public protocol TransactionSupport: class {

    /**
     Returns true when the called variable knows its performing a transaction, a succession of various changes to all
     be grouped as a while. For broadcasting collections, an easy example would be  when applying a non-trivial diff.
     Can be consulted by determine whether to pay attention to fine-grained changes or wait until the transactions are
     over before reacting to changes.
     */
    var isExecutingTransactions: Bool { get }

    /**
     The currently ongoing transactions.

     Transactions all have an UID that can be used to identify them when inherited across various objects. It is
     related to a tuple of a name (for debugging identification purposes) and the object that originated the transaction
     to begin with.
     */
    var ongoingTransactions: CountedSet<TransactionInfo> { get }
}


extension TransactionSupport {

    /// Default implementation. Just checks the ongoingTransactions dictionary.
    public var isExecutingTransactions: Bool {
        return !ongoingTransactions.isEmpty
    }
}
