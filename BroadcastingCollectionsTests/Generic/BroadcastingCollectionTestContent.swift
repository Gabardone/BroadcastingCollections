//
//  BroadcastingCollectionTestContent.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


//  Need to make it a subclass of NSObject or NSOrderedSet gets confused by it.
class BroadcastingCollectionTestContent: NSObject {
    //  The standard sample content set during setup for tests.
    static let sampleContent = [BroadcastingCollectionTestContent(number: 1, string: "Tina"),
                                BroadcastingCollectionTestContent(number: 2, string: "Locke"),
                                BroadcastingCollectionTestContent(number: 3, string: "Mog"),
                                BroadcastingCollectionTestContent(number: 4, string: "Edgar"),
                                BroadcastingCollectionTestContent(number: 5, string: "Sabin"),
                                BroadcastingCollectionTestContent(number: 6, string: "Celes"),
                                BroadcastingCollectionTestContent(number: 7, string: "Cayenne"),
                                BroadcastingCollectionTestContent(number: 8, string: "Clyde"),
                                BroadcastingCollectionTestContent(number: 9, string: "Gau"),
                                BroadcastingCollectionTestContent(number: 10, string: "Setzer"),
                                BroadcastingCollectionTestContent(number: 11, string: "Relm"),
                                BroadcastingCollectionTestContent(number: 12, string: "Stragus"),
                                BroadcastingCollectionTestContent(number: 13, string: "Umaro"),
                                BroadcastingCollectionTestContent(number: 14, string: "Gogo")]

    //  Use these in tests where we want elements that are not initially in sampleContent
    static let sampleLeo = BroadcastingCollectionTestContent(number: 15, string: "Leo")
    static let sampleBanon = BroadcastingCollectionTestContent(number: 16, string: "Banon")
    static let sampleKefka = BroadcastingCollectionTestContent(number: 17, string: "Kefka")
    static let sampleGestalt = BroadcastingCollectionTestContent(number: 18, string: "Gestalt")


    var number: Int = 0
    let string: String  //  We make the string constant and make it the source of hashability.

    override func isEqual(_ element: Any?) -> Bool {
        if let b = element as? BroadcastingCollectionTestContent {
            return b.number == number && b.string == string
        }

        return false
    }


    //  NSOrderedSet isn't catching up on hashValue.
    override var hash: Int {
        return hashValue
    }


    override var hashValue: Int {
        return self.string.hashValue
    }


    init(number: Int, string: String) {
        self.number = number;
        self.string = string;
    }


    override public var description: String {
        return "Number: \(number), String: \(string)"
    }


    func clone() -> BroadcastingCollectionTestContent {
        //  Return another one with the same data.
        return BroadcastingCollectionTestContent(number: number, string: string)
    }
}
