//
//  BroadcastingCollectionSourced.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


/**
 A protocol for classes that source their contents from a broadcasting collection.

 Implementers of this protocol have a settable contentsSource that they'll listen to.
 */
public protocol BroadcastingCollectionSourced: BroadcastingCollectionListener {

    /**
     The broadcasting set we're sourcing our contents from.

     Setting nil will suspend updates. Setting a different broadcasting set will cause the updated contents to diff on
     the new calculatedContents as long as there was no other suspension reason in effect.
     */
    var contentsSource: ListenedCollectionTypes.BroadcastingCollectionType? { get set }


    /**
     Utility for checking that our listener calls are received from the right broadcasting set.

     - Parameter source: The calling broadcasting set. We check if it's the same as broadcastingSetSource.
     - Parameter function: The calling function for logging purposes.
     */
    func validateContentsSource(forSource source: ListenedCollectionTypes.BroadcastingCollectionType, called function: String)
}


extension BroadcastingCollectionSourced {

    public func validateContentsSource(forSource source: ListenedCollectionTypes.BroadcastingCollectionType, called function: String) {
        guard source === contentsSource else {
            //  We got nothing to do with broadcasting sets other than contentsSource even if a subclass listens to others.
            preconditionFailure("Received broadcast \(#function) from source \(source) different from contentsSource \(String(describing: contentsSource))")
        }
    }
}
