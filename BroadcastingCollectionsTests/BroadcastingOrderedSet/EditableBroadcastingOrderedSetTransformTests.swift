//
//  EditableBroadcastingOrderedSetTransformTests.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import BroadcastingCollections
import XCTest


class EditableBroadcastingOrderedSetTransformTests: EditableBroadcastingOrderedSetTestCase {

    func testNoChanges() {
        editableBroadcastingOrderedSet.contents = NSOrderedSet(array: sampleContent)

        XCTAssertTrue(testListener.listenerLog.isEmpty)
    }


    func testTransformOnlyRemoves() {
        let destinationContent = NSMutableOrderedSet(array: sampleContent)
        let removedIndexes: IndexSet = [1, 3, 5, 7, 9, 11, 13]
        let removedElements = destinationContent.objects(at: removedIndexes) as! [BroadcastingCollectionTestContent]
        destinationContent.removeObjects(at: removedIndexes)

        editableBroadcastingOrderedSet.contents = destinationContent

        //  The basic test for any transform test is that it transformed into the destination content.
        XCTAssertEqual(editableBroadcastingOrderedSet.contents, destinationContent)

        //  Test that the steps followed and broadcast are the expected ones.
        let removedElementsAtIndexes = IndexedElements(indexes: removedIndexes, elements: removedElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willRemove: removedElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didRemove: removedElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testTransformOnlyInserts() {
        let destinationContent = NSMutableOrderedSet(array: sampleContent)
        let insertedIndexes: IndexSet = [5, 13]
        let insertedElements = [BroadcastingCollectionTestContent.sampleBanon, BroadcastingCollectionTestContent.sampleLeo]
        destinationContent.insert(insertedElements, at: insertedIndexes)

        editableBroadcastingOrderedSet.contents = destinationContent

        //  The basic test for any transform test is that it transformed into the destination content.
        XCTAssertEqual(editableBroadcastingOrderedSet.contents, destinationContent)

        //  Test that the steps followed and broadcast are the expected ones.
        let insertedElementsAtIndexes = IndexedElements(indexes: insertedIndexes, elements: insertedElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willInsert: insertedElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didInsert: insertedElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testTransformOnlyRemovesAndInserts() {
        let destinationContent = NSMutableOrderedSet(array: sampleContent)
        let removedIndexes: IndexSet = [1, 3, 5, 7, 9, 11, 13]
        let removedElements = destinationContent.objects(at: removedIndexes) as! [BroadcastingCollectionTestContent]
        destinationContent.removeObjects(at: removedIndexes)

        let insertedIndexes: IndexSet = [3, 7]
        let insertedElements = [BroadcastingCollectionTestContent.sampleBanon, BroadcastingCollectionTestContent.sampleLeo]
        destinationContent.insert(insertedElements, at: insertedIndexes)

        editableBroadcastingOrderedSet.contents = destinationContent

        //  The basic test for any transform test is that it transformed into the destination content.
        XCTAssertEqual(editableBroadcastingOrderedSet.contents, destinationContent)

        //  Test that the steps followed and broadcast are the expected ones.
        sampleListener.broadcastingOrderedSetWillBeginTransactions(editableBroadcastingOrderedSet)

        let removedElementsAtIndexes = IndexedElements(indexes: removedIndexes, elements: removedElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willRemove: removedElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didRemove: removedElementsAtIndexes)

        let insertedElementsAtIndexes = IndexedElements(indexes: insertedIndexes, elements: insertedElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willInsert: insertedElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didInsert: insertedElementsAtIndexes)

        sampleListener.broadcastingOrderedSetDidEndTransactions(editableBroadcastingOrderedSet)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testTransformResortsElements() {
        let destinationContent = NSMutableOrderedSet(array: sampleContent)
        destinationContent.sort(comparator: { (leftAny, rightAny) -> ComparisonResult in
            let leftContent = leftAny as! BroadcastingCollectionTestContent
            let rightContent = rightAny as! BroadcastingCollectionTestContent
            if leftContent.string < rightContent.string {
                return .orderedAscending
            } else if rightContent.string < leftContent.string {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        })

        editableBroadcastingOrderedSet.contents = destinationContent

        //  The basic test for any transform test is that it transformed into the destination content.
        XCTAssertEqual(editableBroadcastingOrderedSet.contents, destinationContent)

        //  Test that the steps followed and broadcast are the expected ones.
        sampleListener.broadcastingOrderedSetWillBeginTransactions(editableBroadcastingOrderedSet)
        XCTAssertTrue(testListener.listenerLog.hasPrefix(sampleListener.listenerLog))

        //  Test amount of moves (the exact moves depend on the algorithm so no need to go into detail, but in this case
        //  the longest sorted subsequence is 6 so we'll need 8 moves).
        XCTAssertEqual(testListener.listenerLog.count(of: "WILL MOVE"), 8)

        sampleListener.listenerLog = ""
        sampleListener.broadcastingOrderedSetDidEndTransactions(editableBroadcastingOrderedSet)
        XCTAssertTrue(testListener.listenerLog.hasSuffix(sampleListener.listenerLog))
    }


    func testTransfromWithReplacementsNoChanges() {
        editableBroadcastingOrderedSet.set(NSOrderedSet(array: sampleContent), replacing: IndexSet(), with: NSOrderedSet())

        XCTAssert(testListener.listenerLog == "")
    }


    func testTransformOnlyReplaces() {
        //  Prepare the replacement elements.
        let replacementElements = [BroadcastingCollectionTestContent(number: 1, string: "Terra"),
                                   BroadcastingCollectionTestContent(number: 7, string: "Cyan"),
                                   BroadcastingCollectionTestContent(number: 8, string: "Shadow"),
                                   BroadcastingCollectionTestContent(number: 12, string: "Strago")]

        let replacementIndexes = IndexSet(arrayLiteral: 0, 6, 7, 11)

        let replacedElements = sampleContent[replacementIndexes]

        //  Prepare the final contents.
        let destinationContent = NSMutableOrderedSet(array: sampleContent)
        destinationContent.replaceObjects(at: replacementIndexes, with: replacementElements)

        //  Do the actual transform.
        editableBroadcastingOrderedSet.set(destinationContent, replacing: replacementIndexes, with: NSOrderedSet(array: replacementElements))

        //  The basic test for any transform test is that it transformed into the destination content.
        XCTAssertEqual(editableBroadcastingOrderedSet.contents, destinationContent)

        //  Test that the steps followed and broadcast are the expected ones. In this case just a simple replacement.
        let replaceeElementsAtIndexes = IndexedElements(indexes: replacementIndexes, elements: replacedElements)
        let replacementElementsAtIndexes = IndexedElements(indexes: replacementIndexes, elements: replacementElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testTransformOnlyReplacesWithReplacementFinder() {
        //  Prepare the replacement elements.
        let replacementElements = [BroadcastingCollectionTestContent(number: 1, string: "Terra"),
                                   BroadcastingCollectionTestContent(number: 7, string: "Cyan"),
                                   BroadcastingCollectionTestContent(number: 8, string: "Shadow"),
                                   BroadcastingCollectionTestContent(number: 12, string: "Strago")]

        let replacementIndexes = IndexSet(arrayLiteral: 0, 6, 7, 11)

        let replacedElements = sampleContent[replacementIndexes]

        //  Prepare the final contents.
        let destinationContent = NSMutableOrderedSet(array: sampleContent)
        destinationContent.replaceObjects(at: replacementIndexes, with: replacementElements)

        //  Do the actual transform.
        editableBroadcastingOrderedSet.set(destinationContent) { (replacee: BroadcastingCollectionTestContent, indexSet: IndexSet) -> BroadcastingCollectionTestContent? in
            let replacementIndex = destinationContent.index(ofObjectAt: indexSet, options: [], passingTest: { (candidate: Any, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
                let candidateContent = candidate as! BroadcastingCollectionTestContent
                return replacee.number == candidateContent.number
            })

            if replacementIndex != NSNotFound {
                return destinationContent[replacementIndex] as? BroadcastingCollectionTestContent
            } else {
                return nil
            }
        }

        //  The basic test for any transform test is that it transformed into the destination content.
        XCTAssertEqual(editableBroadcastingOrderedSet.contents, destinationContent)

        //  Test that the steps followed and broadcast are the expected ones. In this case just a simple replacement.
        let replaceeElementsAtIndexes = IndexedElements(indexes: replacementIndexes, elements: replacedElements)
        let replacementElementsAtIndexes = IndexedElements(indexes: replacementIndexes, elements: replacementElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)

        XCTAssertEqual(testListener.listenerLog, sampleListener.listenerLog)
    }


    func testTransformWithReplacementAndResortingWithReplacementFinder() {
        //  Prepare the replacement elements.
        let replacementElements = [BroadcastingCollectionTestContent(number: 7, string: "Cyan"),
                                   BroadcastingCollectionTestContent(number: 8, string: "Shadow"),
                                   BroadcastingCollectionTestContent(number: 12, string: "Strago")]

        let replacementIndexes = IndexSet(arrayLiteral: 6, 7, 11)

        let replacedElements = sampleContent[replacementIndexes]

        //  Prepare the final contents.
        let destinationContent = NSMutableOrderedSet(array: sampleContent)
        destinationContent.replaceObjects(at: replacementIndexes, with: replacementElements)

        //  Calculate the amount of moves needed.
        let sortCriteria = { (left: Any, right: Any) -> ComparisonResult in
            return (left as! BroadcastingCollectionTestContent).string.compare((right as! BroadcastingCollectionTestContent).string)
        }

        //  Finally sort by name.
        destinationContent.sort(comparator: sortCriteria)

        //  Do the actual transform.
        editableBroadcastingOrderedSet.set(destinationContent) { (replacee, indexSet) -> BroadcastingCollectionTestContent? in
            if let replacementIndex = indexSet.firstIndex(where: { (index) -> Bool in
                let candidateContent = destinationContent[index] as! BroadcastingCollectionTestContent
                return replacee.number == candidateContent.number
            }) {
                return destinationContent[indexSet[replacementIndex]] as? BroadcastingCollectionTestContent
            } else {
                return nil
            }
        }

        //  The basic test for any transform test is that it transformed into the destination content.
        XCTAssertEqual(editableBroadcastingOrderedSet.contents, destinationContent)

        //  Test that the steps followed and broadcast are the expected ones. We don't care what the moves are exactly
        //  but only how many happened, so we only test prefix, suffix and number of moves.
        sampleListener.broadcastingOrderedSetWillBeginTransactions(editableBroadcastingOrderedSet)
        let replaceeElementsAtIndexes = IndexedElements(indexes: replacementIndexes, elements: replacedElements)
        let replacementElementsAtIndexes = IndexedElements(indexes: replacementIndexes, elements: replacementElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)

        XCTAssertTrue(testListener.listenerLog.hasPrefix(sampleListener.listenerLog))

        //  Test that the amount of moves is the expected one (longest sorted subsequence in this case is 6, with 14 final content size)
        XCTAssertEqual(testListener.listenerLog.count(of: "WILL MOVE"), 8)

        //  Test that suffix is the same:
        sampleListener.listenerLog = ""
        sampleListener.broadcastingOrderedSetDidEndTransactions(editableBroadcastingOrderedSet)

        XCTAssertTrue(testListener.listenerLog.hasSuffix(sampleListener.listenerLog))
    }


    func testTransformWithRemovalReplacementAndResortingWithReplacementFinder() {
        //  Prepare the replacement elements.
        let replacementElements = [BroadcastingCollectionTestContent(number: 7, string: "Cyan"),
                                   BroadcastingCollectionTestContent(number: 8, string: "Shadow"),
                                   BroadcastingCollectionTestContent(number: 12, string: "Strago")]

        let replacementIndexes = IndexSet(arrayLiteral: 6, 7, 11)

        let replacedElements = sampleContent[replacementIndexes]

        //  Prepare the final contents.
        let destinationContent = NSMutableOrderedSet(array: sampleContent)
        destinationContent.replaceObjects(at: replacementIndexes, with: replacementElements)

        //  Remove the girls
        let removedElementIndexes = IndexSet(arrayLiteral: 0, 5, 10)
        let removedElements = sampleContent[removedElementIndexes]
        destinationContent.removeObjects(at: removedElementIndexes)

        let adjustedReplacementIndexes = IndexSet(arrayLiteral: 4, 5, 8)    //  Adjusted from prior removal.

        //  Calculate the amount of moves needed.
        let sortCriteria = { (left: Any, right: Any) -> ComparisonResult in
            return (left as! BroadcastingCollectionTestContent).string.compare((right as! BroadcastingCollectionTestContent).string)
        }

        //  Finally sort by name.
        destinationContent.sort(comparator: sortCriteria)

        //  Do the actual transform.
        editableBroadcastingOrderedSet.set(destinationContent) { (replacee, indexSet) -> BroadcastingCollectionTestContent? in
            if let replacementIndex = indexSet.firstIndex(where: { (index) -> Bool in
                let candidateContent = destinationContent[index] as! BroadcastingCollectionTestContent
                return replacee.number == candidateContent.number
            }) {
                return destinationContent[indexSet[replacementIndex]] as? BroadcastingCollectionTestContent
            } else {
                return nil
            }
        }

        //  The basic test for any transform test is that it transformed into the destination content.
        XCTAssertEqual(editableBroadcastingOrderedSet.contents, destinationContent)

        //  Test that the steps followed and broadcast are the expected ones. We don't care what the moves are exactly
        //  but only how many happened, so we only test prefix, suffix and number of moves.
        sampleListener.broadcastingOrderedSetWillBeginTransactions(editableBroadcastingOrderedSet)

        let removedElementsAtIndexes = IndexedElements(indexes: removedElementIndexes, elements: removedElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willRemove: removedElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didRemove: removedElementsAtIndexes)

        let replaceeElementsAtIndexes = IndexedElements(indexes: adjustedReplacementIndexes, elements: replacedElements)
        let replacementElementsAtIndexes = IndexedElements(indexes: adjustedReplacementIndexes, elements: replacementElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)

        XCTAssertTrue(testListener.listenerLog.hasPrefix(sampleListener.listenerLog))

        //  Test that the amount of moves is the expected one (longest sorted subsequence in this case is 6, with 11 final content size)
        XCTAssertEqual(testListener.listenerLog.count(of: "WILL MOVE"), 5)

        //  Test that suffix is the same:
        sampleListener.listenerLog = ""
        sampleListener.broadcastingOrderedSetDidEndTransactions(editableBroadcastingOrderedSet)

        XCTAssertTrue(testListener.listenerLog.hasSuffix(sampleListener.listenerLog))
    }


    func testTransformWithReplacementResortingAndInsertionWithReplacementFinder() {
        //  Prepare the replacement elements.
        let replacementElements = [BroadcastingCollectionTestContent(number: 7, string: "Cyan"),
                                   BroadcastingCollectionTestContent(number: 8, string: "Shadow"),
                                   BroadcastingCollectionTestContent(number: 12, string: "Strago")]

        let replacementIndexes = IndexSet(arrayLiteral: 6, 7, 11)

        let replacedElements = sampleContent[replacementIndexes]

        //  Prepare the final contents.
        let destinationContent = NSMutableOrderedSet(array: sampleContent)
        destinationContent.replaceObjects(at: replacementIndexes, with: replacementElements)

        //  Insert some extra dudes.
        let insertedElements = [BroadcastingCollectionTestContent(number: 16, string: "Banon"), BroadcastingCollectionTestContent(number: 15, string: "Leo")]
        destinationContent.addObjects(from: insertedElements)
        let insertionIndexes = IndexSet(arrayLiteral: 0, 6)

        //  Calculate the amount of moves needed.
        let sortCriteria = { (left: Any, right: Any) -> ComparisonResult in
            return (left as! BroadcastingCollectionTestContent).string.compare((right as! BroadcastingCollectionTestContent).string)
        }

        //  Finally sort by name.
        destinationContent.sort(comparator: sortCriteria)

        //  Do the actual transform.
        editableBroadcastingOrderedSet.set(destinationContent) { (replacee, indexSet) -> BroadcastingCollectionTestContent? in
            if let replacementIndex = indexSet.firstIndex(where: { (index) -> Bool in
                let candidateContent = destinationContent[index] as! BroadcastingCollectionTestContent
                return replacee.number == candidateContent.number
            }) {
                return destinationContent[indexSet[replacementIndex]] as? BroadcastingCollectionTestContent
            } else {
                return nil
            }
        }

        //  The basic test for any transform test is that it transformed into the destination content.
        XCTAssertEqual(editableBroadcastingOrderedSet.contents, destinationContent)

        //  Test that the steps followed and broadcast are the expected ones. We don't care what the moves are exactly
        //  but only how many happened, so we only test prefix, suffix and number of moves.
        sampleListener.broadcastingOrderedSetWillBeginTransactions(editableBroadcastingOrderedSet)

        let replaceeElementsAtIndexes = IndexedElements(indexes: replacementIndexes, elements: replacedElements)
        let replacementElementsAtIndexes = IndexedElements(indexes: replacementIndexes, elements: replacementElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)

        XCTAssertTrue(testListener.listenerLog.hasPrefix(sampleListener.listenerLog))

        //  Test that the amount of moves is the expected one (longest sorted subsequence in this case is 6, with 14 final content size)
        XCTAssertEqual(testListener.listenerLog.count(of: "WILL MOVE"), 8)

        //  Test that suffix is the same:
        sampleListener.listenerLog = ""

        let insertedElementsAtIndexes = IndexedElements(indexes: insertionIndexes, elements: insertedElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willInsert: insertedElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didInsert: insertedElementsAtIndexes)

        sampleListener.broadcastingOrderedSetDidEndTransactions(editableBroadcastingOrderedSet)

        XCTAssertTrue(testListener.listenerLog.hasSuffix(sampleListener.listenerLog))
    }


    func testTransformWithRemovalReplacementResortingAndInsertionWithReplacementFinder() {
        //  Prepare the replacement elements.
        let replacementElements = [BroadcastingCollectionTestContent(number: 7, string: "Cyan"),
                                   BroadcastingCollectionTestContent(number: 8, string: "Shadow"),
                                   BroadcastingCollectionTestContent(number: 12, string: "Strago")]

        let replacementIndexes = IndexSet(arrayLiteral: 6, 7, 11)

        let replacedElements = sampleContent[replacementIndexes]

        //  Prepare the final contents.
        let destinationContent = NSMutableOrderedSet(array: sampleContent)
        destinationContent.replaceObjects(at: replacementIndexes, with: replacementElements)

        //  Remove the girls
        let removedElementIndexes = IndexSet(arrayLiteral: 0, 5, 10)
        let removedElements = sampleContent[removedElementIndexes]
        destinationContent.removeObjects(at: removedElementIndexes)

        //  Insert some extra dudes.
        let insertedElements = [BroadcastingCollectionTestContent(number: 16, string: "Banon"), BroadcastingCollectionTestContent(number: 15, string: "Leo")]
        destinationContent.addObjects(from: insertedElements)
        let insertionIndexes = IndexSet(arrayLiteral: 0, 5)

        let adjustedReplacementIndexes = IndexSet(arrayLiteral: 4, 5, 8)    //  Adjusted from prior removal.

        //  Calculate the amount of moves needed.
        let sortCriteria = { (left: Any, right: Any) -> ComparisonResult in
            return (left as! BroadcastingCollectionTestContent).string.compare((right as! BroadcastingCollectionTestContent).string)
        }

        //  Finally sort by name.
        destinationContent.sort(comparator: sortCriteria)

        //  Do the actual transform.
        editableBroadcastingOrderedSet.set(destinationContent) { (replacee, indexSet) -> BroadcastingCollectionTestContent? in
            if let replacementIndex = indexSet.firstIndex(where: { (index) -> Bool in
                let candidateContent = destinationContent[index] as! BroadcastingCollectionTestContent
                return replacee.number == candidateContent.number
            }) {
                return destinationContent[indexSet[replacementIndex]] as? BroadcastingCollectionTestContent
            } else {
                return nil
            }
        }

        //  The basic test for any transform test is that it transformed into the destination content.
        XCTAssertEqual(editableBroadcastingOrderedSet.contents, destinationContent)

        //  Test that the steps followed and broadcast are the expected ones. We don't care what the moves are exactly
        //  but only how many happened, so we only test prefix, suffix and number of moves.
        sampleListener.broadcastingOrderedSetWillBeginTransactions(editableBroadcastingOrderedSet)

        let removedElementsAtIndexes = IndexedElements(indexes: removedElementIndexes, elements: removedElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willRemove: removedElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didRemove: removedElementsAtIndexes)

        let replaceeElementsAtIndexes = IndexedElements(indexes: adjustedReplacementIndexes, elements: replacedElements)
        let replacementElementsAtIndexes = IndexedElements(indexes: adjustedReplacementIndexes, elements: replacementElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didReplace: replaceeElementsAtIndexes, with: replacementElementsAtIndexes)

        XCTAssert(testListener.listenerLog.hasPrefix(sampleListener.listenerLog))

        //  Test that the amount of moves is the expected one (longest sorted subsequence in this case is 6, with 11 final content size)
        XCTAssert(testListener.listenerLog.count(of: "WILL MOVE") == 5)

        //  Test that suffix is the same:
        sampleListener.listenerLog = ""

        let insertedElementsAtIndexes = IndexedElements(indexes: insertionIndexes, elements: insertedElements)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, willInsert: insertedElementsAtIndexes)
        sampleListener.broadcastingOrderedSet(editableBroadcastingOrderedSet, didInsert: insertedElementsAtIndexes)

        sampleListener.broadcastingOrderedSetDidEndTransactions(editableBroadcastingOrderedSet)
        
        XCTAssert(testListener.listenerLog.hasSuffix(sampleListener.listenerLog))
    }
}
