//
//  BroadcastingSetContravariantFaçadeTests.swift
//  BroadcastingCollectionsTests
//
//  Created by Óscar Morales Vivó on 11/2/17.
//  Copyright © 2017 Óscar Morales Vivó. All rights reserved.
//

import BroadcastingCollections
import XCTest


class BroadcastingCollectionExtendedTestContent: BroadcastingCollectionTestContent {

    enum Genre {
        case male
        case female
        case unknown
    }

    let genre: Genre

    static let sampleExtendedContent = [BroadcastingCollectionExtendedTestContent(number: 1, string: "Tina", genre: .female),
                                        BroadcastingCollectionExtendedTestContent(number: 2, string: "Locke", genre: .male),
                                        BroadcastingCollectionExtendedTestContent(number: 3, string: "Mog", genre: .unknown),
                                        BroadcastingCollectionExtendedTestContent(number: 4, string: "Edgar", genre: .male),
                                        BroadcastingCollectionExtendedTestContent(number: 5, string: "Sabin", genre: .male),
                                        BroadcastingCollectionExtendedTestContent(number: 6, string: "Celes", genre: .female),
                                        BroadcastingCollectionExtendedTestContent(number: 7, string: "Cayenne", genre: .male),
                                        BroadcastingCollectionExtendedTestContent(number: 8, string: "Clyde", genre: .male),
                                        BroadcastingCollectionExtendedTestContent(number: 9, string: "Gau", genre: .male),
                                        BroadcastingCollectionExtendedTestContent(number: 10, string: "Setzer", genre: .male),
                                        BroadcastingCollectionExtendedTestContent(number: 11, string: "Relm", genre: .female),
                                        BroadcastingCollectionExtendedTestContent(number: 12, string: "Stragus", genre: .male),
                                        BroadcastingCollectionExtendedTestContent(number: 13, string: "Umaro", genre: .unknown),
                                        BroadcastingCollectionExtendedTestContent(number: 14, string: "Gogo", genre: .unknown)]

    init(number: Int, string: String, genre: Genre = .unknown) {
        self.genre = genre
        super.init(number: number, string: string)
    }


    override func isEqual(_ element: Any?) -> Bool {
        if super.isEqual(element) {
            //  See if it's the same type.
            if let b = element as? BroadcastingCollectionExtendedTestContent {
                //  Compare also genre.
                return b.genre == self.genre
            }
        }

        return false
    }


    override public var description: String {
        get {
            return super.description + "Genre: \(genre)"
        }
    }


    override func clone() -> BroadcastingCollectionExtendedTestContent {
        //  Return another one with the same data.
        return BroadcastingCollectionExtendedTestContent(number: number, string: string, genre: genre)
    }
}


//  TODO: Figure out a way of not having this be an almost complete redo of BroadcastingSetTestCase
class BroadcastingSetContravariantFaçadeTests: XCTestCase {

    var managedController: ManagedBroadcastingSet<BroadcastingCollectionExtendedTestContent>!

    var contravariantFaçade: BroadcastingSetContravariantFaçade<BroadcastingCollectionTestContent, BroadcastingCollectionExtendedTestContent>!

    var testListener: BroadcastingSetTestListener!

    var sampleListener: BroadcastingSetTestListener!


    override func setUp() {
        super.setUp()

        //  Create a new ordered set controller.
        managedController = ManagedBroadcastingSet<BroadcastingCollectionExtendedTestContent>()

        //  Set its data to a copy of the sample content (notice that we don't have listeners yet).
        managedController.editableBroadcastingCollection.contents = Set(BroadcastingCollectionExtendedTestContent.sampleExtendedContent.map({ (testContent) -> BroadcastingCollectionExtendedTestContent in
            return testContent.clone()
        }))

        contravariantFaçade = BroadcastingSetContravariantFaçade<BroadcastingCollectionTestContent, BroadcastingCollectionExtendedTestContent>(for: managedController.editableBroadcastingCollection)

        //  Create a new testListener and sest it to listen setController
        testListener = BroadcastingSetTestListener()
        contravariantFaçade.add(listener: testListener)

        //  Create a new sample listener.
        sampleListener = BroadcastingSetTestListener()
    }


    override func tearDown() {
        //  Clear out all the auxiliary test objects.
        managedController = nil
        contravariantFaçade = nil
        testListener = nil
        sampleListener = nil

        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    func testListenerHasBeenSetUp() {
        //  This is something that actually was a bug at some point ;)
        XCTAssertTrue(managedController.editableBroadcastingCollection.hasListeners)
    }
}
