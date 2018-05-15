//
//  NSArray+LongestSortedSubsequenceTests.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections

import XCTest

class Array_LongestSortedSubsequenceTests: XCTestCase {

    static let intComparator: (Int, Int) -> Bool = { (left: Int, right: Int) in
        return left < right
    }


    func testShortSequence() {
        let numberArray = [3, 2, 6, 4, 5, 1]

        let longestSortedSubsequenceIndexes = numberArray.indexesOfLongestSortedSubsequence(sortedBy: Array_LongestSortedSubsequenceTests.intComparator)

        XCTAssertEqual(longestSortedSubsequenceIndexes.count, 3)
        XCTAssertEqual(numberArray[longestSortedSubsequenceIndexes], [2, 4, 5])
    }


    func testLongishSequence() {
        let numberArray = [ 0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15]

        let longestSortedSubsequenceIndexes = numberArray.indexesOfLongestSortedSubsequence(sortedBy: Array_LongestSortedSubsequenceTests.intComparator)

        XCTAssertEqual(longestSortedSubsequenceIndexes.count, 6)
        XCTAssertEqual(longestSortedSubsequenceIndexes.map({ (index: Int) -> Int in return numberArray[index] }), [0, 2, 6, 9, 11, 15])
    }


    func testReversedSequence() {
        let numberArray = [ 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 ]

        let longestSortedSubsequenceIndexes = numberArray.indexesOfLongestSortedSubsequence(sortedBy: Array_LongestSortedSubsequenceTests.intComparator)

        XCTAssertEqual(longestSortedSubsequenceIndexes.count, 1)
        XCTAssertEqual(longestSortedSubsequenceIndexes.map({ (index: Int) -> Int in return numberArray[index] }), [0])   //  Algorithm returns the latest sequence if several of the same length exist.
    }


    func testSequenceWithSeveralSubsequencesOfTheSameLength() {
        let numberArray = [ 2, 4, 6, 1, 3, 5 ]

        let longestSortedSubsequenceIndexes = numberArray.indexesOfLongestSortedSubsequence(sortedBy: Array_LongestSortedSubsequenceTests.intComparator)

        XCTAssertEqual(longestSortedSubsequenceIndexes.count, 3)
        XCTAssertEqual(longestSortedSubsequenceIndexes.map({ (index: Int) -> Int in return numberArray[index] }), [1, 3, 5])   //  Algorithm returns the latest sequence if several of the same length exist.
    }
}
