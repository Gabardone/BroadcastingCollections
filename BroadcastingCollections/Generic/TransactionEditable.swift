//
//  TransactionEditable.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


public protocol TransactionEditable: TransactionSupport {

    /**
     The currently ongoing transactions.

     The ongoing transactions of a TransactionEditable implementer can be modified. Generally avoid setting this property
     outside the transaction management of the type.
     */
    var ongoingTransactions: CountedSet<TransactionInfo> { get set }


    /**
     Starts a transaction with the given name.

     This method will mark the beginning of a transaction originated in the calling object. It will get its own UUID
     and its originator will be set as the caller.

     - Parameter identifier: The identifier for the transaction. Doesn't need to be unique, the same transaction can
     be started more than once.
     - Parameter originator: The object actually originating the transaction.
     */
    func beginTransaction(withInfo transactionInfo: TransactionInfo)


    /// Sets up the caller when going from not running any transaction to running transactions.
    func setupTransactionEnvironment()


    /**
     Manually ends a transaction.

     This method marks the end of the transaction for the given uuid, no matter whether it was initiated in this object
     or inherited from elsewhere.
     - Precondition: At least one transaction with the same identifier and originator has been started on this object
     before.
     - Parameter identifier: The identifier for the transaction we want to end
     - Parameter originator: The object actually originating the transaction we want to end.
     */
    func endTransaction(withInfo transactionInfo: TransactionInfo)


    /// Sets up the caller when going from running any transaction to not running any.
    func tearDownTransactionEnvironment()


    /**
     Utility to perform a transaction within a block.

     This is an easy wrapper to perform a transaction within a given block. It begins a transaction with the given
     name, performs the logic in the work block, and the ends the transaction.
     - Parameter named: The name to give the transaction to keep track of it.
     - Parameter work: The work that the transaction actually performs.
     */
    func perform(transactionWithIdentifier identifier: TransactionIdentifier, performing work: () -> (Void))
}


/**
 Default implementation of most transaction management properties and methods.
 */
extension TransactionEditable {

    public func beginTransaction(withInfo transactionInfo: TransactionInfo) {
        if !isExecutingTransactions {
            setupTransactionEnvironment()
        }

        ongoingTransactions.insert(transactionInfo)
    }


    public func endTransaction(withInfo transactionInfo: TransactionInfo) {
        guard ongoingTransactions.contains(transactionInfo) else {
            //  Let's blow up.
            preconditionFailure("Attempted to end transaction with info \(transactionInfo) not ongoing on \(self)")
        }

        ongoingTransactions.remove(transactionInfo)

        if !isExecutingTransactions {
            tearDownTransactionEnvironment()
        }
    }


    public func perform(transactionWithIdentifier identifier: TransactionIdentifier, performing work: () -> (Void)) {
        let transactionToPerform = TransactionInfo(identifier: identifier, originator: self)
        beginTransaction(withInfo: transactionToPerform)
        work()
        endTransaction(withInfo: transactionToPerform)
    }
}
