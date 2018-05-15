//
//  MultiBroadcastingSetSourced.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


extension TransactionIdentifier {
    static let contentsSourcesAreChanging = TransactionIdentifier(rawValue: "The contents sources are being changed")
}


/**
 Protocol for a contents manager that takes as its source a set of broadcasting sets.
 */
public protocol MultiBroadcastingSetSourced: BroadcastingSetListener {

    /**
     The broadcasting sets we're sourcing our managed contents from.

     Setting nil will suspend updates. Setting a different value for the property will cause the managed contents to
     diff on the new calculatedContents as long as there was no other suspension reason in effect.
     */
    var contentsSources: Set<BroadcastingSet<ListenedElement>> { get set }


    /**
     Utility for checking that our listener calls are received from the right broadcasting set (one contained in
     contentsSources).

     - Parameter broadcastingSet: The calling broadcasting set. We check if it's the same as broadcastingSetSource.
     - Parameter function: The calling function for logging purposes.
     */
    func validateContentsSource(forBroadcasting broadcastingSet: BroadcastingSet<ListenedElement>, called function: String)
}


extension MultiBroadcastingSetSourced {

    public func validateContentsSource(forBroadcasting broadcastingSet: BroadcastingSet<ListenedElement>, called function: String) {
        guard contentsSources.contains(broadcastingSet) else {
            //  We got nothing to do with broadcasting sets other than those in contentsSources.
            preconditionFailure("Received broadcast change \(#function) from broadcasting set \(broadcastingSet) not contained in contents sources \(contentsSources)")
        }
    }
}
