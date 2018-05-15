//
//  BroadcastingCollectionTestListener.swift
//  BroadcastingCollectionsTests
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import Foundation


extension IndexSet {

    var detailedDescription: String {
        if count == 0 {
            return "(empty)"
        } else {
            var result = "("
            for index in self {
                result += "\(index), "
            }

            result.removeSubrange(result.range(of: ", ", options: .backwards, range: nil, locale: nil)!)
            result += ")"

            return result
        }
    }
}


extension String {

    //  Use this to count occurrences of any of the particular listener commands.
    func count(of string: String) -> Int {
        var result = 0
        var stringRange = self.startIndex ..< self.endIndex
        while !stringRange.isEmpty {
            if let foundRange = self.range(of: string, options: String.CompareOptions(), range: stringRange, locale: nil) {
                result += 1
                stringRange = foundRange.upperBound ..< self.endIndex
            } else {
                break
            }
        }

        return result
    }
}


class BroadcastingCollectionTestListener<CollectionTypes: CollectionTypesWrapper>: BroadcastingCollectionListener {

    typealias ListenedCollectionTypes = CollectionTypes

    var ignoreBroadcastingCollectionIdentity = false

    func string(for broadcastingCollection: AnyObject) -> String {
        return ignoreBroadcastingCollectionIdentity ? "" : "\(ObjectIdentifier(broadcastingCollection))"
    }

    var listenerLog = ""
}
