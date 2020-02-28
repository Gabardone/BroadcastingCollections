//
//  Array+LongestSortedSubsequence.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


public extension Collection where Self.Index == Int {

    /** Returns an array with the element at the given indexes.
    - Parameter indexes: The indexes of the elements to retrieve.
     */
    subscript(indexes: IndexSet) -> [Element] {
        let indexCount = indexes.count
        switch indexCount {
        case 0:
            return []

        case 1:
            return [self[indexes[indexes.startIndex]]]

        default:
            var result: [Element] = []
            result.reserveCapacity(indexCount)   //  Minimize the amount of allocations.
            indexes.rangeView.forEach { (indexRange) in
                //  Do the array construction in range chunks. At worse it will take as long as doing it one by one.
                result.append(contentsOf: self[indexRange])
            }
            return result
        }
    }
}


private class LSNode {
    var index: Int
    var backPointer: LSNode? = nil

    init(index: Int) {
        self.index = index
    }
}


public extension Array {

    /** Returns the index at which the given element would be inserted in the array.
    - Precondition: The array is already sorted with the same criteria used in the comparator parameter.
    - Result: The index where we would insert element to maintain comparator sort.
    - Parameter element: The element whose insertion index we want to find.
    - Parameter comparator: The comparator block the array is already sorted with.
    - Note: If the given element is already present in the array the result will be correct but no further guarantees
     are made about it.
     */
    func insertionIndex(for element: Element, arraySortedUsing comparator: (Element, Element) -> Bool) -> Index {
        return insertionIndex(for: element, in: startIndex ..< endIndex, arraySortedUsing: comparator)
    }


    /** Returns the index at which the given element would be inserted in the given range of the array.
    - Precondition: The give range in the array is already sorted with the same criteria used in the comparator parameter.
    - Note: If the given element is already present in the array the result will be correct but no further guarantees
     are made about it.
    - Result: The index where we would insert element to maintain comparator sort.
    - Parameter element: The element whose insertion index we want to find.
    - Parameter range: The sorted range within the array where we want to find the insertion index for element.
    - Parameter comparator: The comparator block the range in the array is already sorted with.
     */
    func insertionIndex(for element: Element, in range: Range<Int>, arraySortedUsing comparator: (Element, Element) -> Bool) -> Index {
        return _binarySearch(in: range, sortingCriteria: { (otherElement) -> Bool in
            return comparator(otherElement, element)
        })
    }

    
    //  Not offered in the swift standard library for some reason.
    private func _binarySearch(in range: Range<Int>, sortingCriteria: (Element) -> Bool) -> Index {
        var low = range.lowerBound
        var high = range.upperBound
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high)/2)
            if sortingCriteria(self[mid]) {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }
}


public extension Array {

    /** Returns an index set pointing to a longest sorted subsequence (there may be more than one) in the calling array.
    - Precondition: The array is already sorted with the same criteria used in the comparator parameter.
    - Result: An index set pointing to the indexes of a longest sorted subsequence in the calling array.
    - Parameter comparator: The sorting criteria expressed as a block.
     */
    func indexesOfLongestSortedSubsequence(sortedBy comparator: (Element, Element) -> Bool) -> IndexSet {
        return indexesOfLongestSortedSubsequence(from: IndexSet(integersIn: indices), sortedBy: comparator)
    }


    /** Returns an index set pointing to a longest sorted subsequence (there may be more than one) within the given
    indexes of the calling array.
    - Precondition: The elements pointed at by indexes within array are already sorted with the same criteria used in
     the comparator parameter.
    - Result: An index set pointing to the indexes of a longest sorted subsequence within the elements at indexes in the
    calling array.
    - Parameter indexes: The indexes of the array whose longest sorted subsequence we aim to find.
    - Parameter comparator: The sorting criteria expressed as a block.
     */
    func indexesOfLongestSortedSubsequence(from indexes: IndexSet, sortedBy comparator: (Element, Element) -> Bool) -> IndexSet {
        var pileTops: [LSNode] = []

        //  Sort into piles.
        for index in indexes {
            let node = LSNode(index: index)

            //  Find its best insertion index in the already found nodes in pileTops.
            let insertionIndex = pileTops.insertionIndex(for: node, arraySortedUsing: { (left, right) -> Bool in
                return comparator(self[left.index], self[right.index])
            })

            if insertionIndex != 0 {
                node.backPointer = pileTops[insertionIndex - 1]
            }

            if insertionIndex != pileTops.count {
                pileTops[insertionIndex] = node
            } else {
                pileTops.append(node)
            }
        }

        //  Now retrieve the resulting index set by backfilling from last node.
        var result = IndexSet()
        var node = pileTops.last
        while node != nil {
            let trueNode = node!
            result.insert(trueNode.index)
            node = trueNode.backPointer
        }

        return result
    }
}
