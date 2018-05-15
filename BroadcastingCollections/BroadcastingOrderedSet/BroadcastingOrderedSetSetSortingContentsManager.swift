//
//  BroadcastingOrderedSetSetSortingContentsManager.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import os
import Foundation


/**
 BroadcastingOrderedSetSetSortingContentsManager takes a broadcasting set as its contents source and manages an
 editable broadcasting ordered set, keeping it sorted according to the criteria set in its areInIncreasingOrder method
 implementation.

 It's the preferred (only) way to move from a broadcasting set to a broadcasting ordered set.
 */
open class BroadcastingOrderedSetSetSortingContentsManager<Element: Hashable & AnyObject>: BroadcastingOrderedSetContentsManager<Element>, BroadcastingCollectionSourcedContentsManager, BroadcastingSetFullListener {

    /**
     Starts up suspended due to having neither managed contents (as its superclass) nor contents source set.

     Superclass sets up the lack of managed contents suspension reason.
     */
    public override init() {
        super.init()

        //  We start suspended because we have no contents source set.
        suspendUpdating(for: .nilContentsSource)
    }


    /**
     This is a utility that returns a block that can be used to sort other collections with the same criteria used by
     this contents manager.
     */
    open var sortingComparator: (Element, Element) -> Bool {
        //  Default to a simple block that calls our comparator method. Uses [weak self] since we don't know what
        //  the caller will do with it.
        return { [weak self] (left, right) -> Bool in self?.areInIncreasingOrder(left, right) ?? false }
    }


    ///  The sorting criteria used. Override this
    open func areInIncreasingOrder(_ left: Element, _ right: Element) -> Bool {
        //  This would make things not really sorted. Override.
        return false
    }


    open func reevaluate(_ element: Element) {
        guard let contentsSource = self.contentsSource else {
            preconditionFailure("Attempted to reevaluate an element \(element) with no contents source set.")
        }

        //  Make sure the element is actually one we know about.
        guard contentsSource.contains(element: element) else {
            preconditionFailure("Attempted to reevaluate an element \(element) that isn't in contents source \(contentsSource)")
        }

        guard let managedContents = (self as BroadcastingOrderedSetContentsManager).managedContents else {
            return
        }

        let currentIndex = managedContents.contents.index(of: element)

        guard currentIndex != NSNotFound else {
            preconditionFailure("Evaluating element not in managedContents")
        }

        //  For a single element, we're assuming everything else is sorted and we move to the new correct position, if different.
        //  Look first back. Try moving it as little as possible.
        let contentsManaged = managedContents.array
        var destinationIndex = contentsManaged.insertionIndex(for: element, in: contentsManaged.startIndex ..< currentIndex, arraySortedUsing: sortingComparator)
        if destinationIndex == currentIndex {
            //  We ain't moving back, let's see if we move forwards.
            destinationIndex = contentsManaged.insertionIndex(for: element, in: currentIndex + 1 ..< contentsManaged.endIndex, arraySortedUsing: sortingComparator) - 1
        }

        //  Call the move, worst that happens is nothing.
        managedContents.move(from: currentIndex, to: destinationIndex)
    }


    open func reevaluate(_ elements: Set<Element>) {
        switch elements.count {
        case 0:
            //  Nothing to do here.
            break

        case 1:
            //  Let's use the one element version as it's a lot less work.
            reevaluate(elements.first!)

        default:
            //  We don't have any real guarantees that we'll do any better than resorting the whole thing. So we do that.
            //  NOTE: We may want to revisit that assumption later. Even if we minimize the amount of moves with the
            //  current implementation, we would still end up spending too much time/memory for large collections
            //  setting things up and verifying. At least for reevaluations much smaller than the whole collection it
            //  may make sense to presume all non-reevaluated items as the longest sorted subsequence, although
            //  EditableBroadcastingOrderedSet._reallySort(with:by:) would need to be modified to guarantee that no spurious moves
            //  happen (it right now presumes everything outside the longest sorted subsequence HAS to be moved around.
            (self as BroadcastingOrderedSetContentsManager).managedContents!.sort(by: sortingComparator)
        }
    }

    //  MARK: - BroadcastingCollectionSourcedContentsManager Implementation.

    public var _contentsSource: BroadcastingSet<Element>?


    open func startUpdating(_ element: ListenedElement) {
        //  For subclasses to override.
    }


    open func stopUpdating(_ element: ListenedElement) {
        //  For subclasses to override.
    }

    //  MARK: - BroadcastingCollectionContentsManager Overrides

    override open func calculateContents() -> NSOrderedSet {
        //  Just resort the source contents using our sorting criteria.
        if let sourceContents = contentsSource?.contents {
            return NSOrderedSet(array: sourceContents.sorted(by: sortingComparator))
        } else {
            return []
        }
    }

    //  MARK: - BroadcastingSetListener Implementation

    public typealias ListenedCollectionTypes = SetTypesWrapper<Element>


    final public func broadcastingSetWillBeginTransactions(_ broadcastingSet: BroadcastingSet<Element>) {
        validateContentsSource(forSource: broadcastingSet, called: #function)

        (self as BroadcastingOrderedSetContentsManager<Element>).managedContents?.beginTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: broadcastingSet))
    }


    final public func broadcastingSetDidEndTransactions(_ broadcastingSet: BroadcastingSet<Element>) {
        validateContentsSource(forSource: broadcastingSet, called: #function)

        (self as BroadcastingOrderedSetContentsManager<Element>).managedContents?.endTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: broadcastingSet))
    }


    final public func broadcastingSet(_ broadcastingSet: BroadcastingSet<Element>, willApply change: CollectionChange<Set<Element>>) {
        validateContentsSource(forSource: broadcastingSet, called: #function)

        switch change {
        case .removal(let changeDescription, _):
            //  Stop updating for the stuff that is leaving.
            for element in changeDescription {
                stopUpdating(element)
            }
        default:
            break
        }

        process(broadcastingSet: broadcastingSet, willApply: change)
    }


    final public func broadcastingSet(_ broadcastingSet: BroadcastingSet<Element>, didApply change: CollectionChange<Set<Element>>) {
        validateContentsSource(forSource: broadcastingSet, called: #function)

        process(broadcastingSet: broadcastingSet, didApply: change)

        switch change {
        case .insertion(let changeDescription, _):
            //  Stop updating for the stuff that is leaving.
            for element in changeDescription {
                startUpdating(element)
            }
        default:
            break
        }
    }

    //  MARK: - BroadcasingSetFullListener Implementation

    final public func broadcastingSet(_ broadcastingSet: BroadcastingSet<Element>, willAdd elements: Set<Element>) {
        //  Empty implementation.
    }


    final public func broadcastingSet(_ broadcastingSet: BroadcastingSet<Element>, didAdd elements: Set<Element>) {
        //  We enter this method with parameters and state already validated. broadcastingOrderedSet === contentsSource and we're updating.

        guard let managedContents = (self as BroadcastingOrderedSetContentsManager<Element>).managedContents else {
            preconditionFailure("Calling listener methods on sorting contents manager with no managed contents set")
        }

        let contentsManaged = managedContents.array
        if elements.count > 1 {
            //  Get the new items in the same order the'll be in updated contents.
            let sortedInsertion = elements.sorted(by: sortingComparator)

            //  Now figure out what indexes they go in.
            let sortedInsertionIndexes = IndexSet(sortedInsertion.enumerated().map({ (enumeration: (offset: Int, element: Element)) -> Int in
                return contentsManaged.insertionIndex(for: enumeration.element, arraySortedUsing: self.sortingComparator) + enumeration.offset
            }))

            managedContents.insert(NSOrderedSet(array: sortedInsertion), at: sortedInsertionIndexes)
        } else {
            //  Let's optimize the simpler case.
            let insertedElement = elements.first!
            let insertedElementIndex = contentsManaged.insertionIndex(for: insertedElement, arraySortedUsing: sortingComparator)

            managedContents.insert(insertedElement, at: insertedElementIndex)
        }
    }


    final public func broadcastingSet(_ broadcastingSet: BroadcastingSet<Element>, willRemove elements: Set<Element>) {
        //  Empty implementation
    }


    final public func broadcastingSet(_ broadcastingSet: BroadcastingSet<Element>, didRemove elements: Set<Element>) {
        guard contentsSource === broadcastingSet else {
            //  We got nothing to do with broadcasters other than contentsSource even if a subclass listens to others.
            return
        }

        //  This one is by far the most straightforward. Just call the removal method on the managed contents.
        (self as BroadcastingOrderedSetContentsManager).managedContents?.remove(elements)
    }

    //  MARK: - BroadcastingOrderedSetContentsManager Overrides

    override open func startUpdating() {
        //  Let super do its thing.
        super.startUpdating()

        guard let contentsSource = self.contentsSource else {
            preconditionFailure("Sorting contents manager \(self) started updating with no contents source set")
        }

        //  Add an inherited transaction if the contentsSource is executing transactions.
        if contentsSource.isExecutingTransactions {
            (self as BroadcastingOrderedSetContentsManager<Element>).managedContents?.beginTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: contentsSource))
        }

        //  Make sure we're being updated for any specific elements currently in contents.
        contentsSource.contents.forEach({ (element) -> Void in
            startUpdating(element)
        })

        //  Finally, start listening to further changes in basteBroadcaster.
        contentsSource.add(listener: self)
    }


    /** This override stops listening to contentsSource and calls stopUpdating(element:) for each element in the
     contents source's contents.

     It will also end an inherited transaction if the contentsSource was executing transactions.

     If contentsSource is being replaced or removed, this will be called before the change is effective.

     Always call super from any override of this method.
     */
    override open func stopUpdating() {
        guard let contentsSource = self.contentsSource else {
            //  Yup this is also a big problem, we should go through this before contentsSource is set to nil or whatever.
            preconditionFailure("Sorting contents manager \(self) stopped updating with no contents source set")
        }

        //  Stop listening!
        contentsSource.remove(listener: self)

        //  Stop updating as soon as possible.
        contentsSource.contents.forEach { (element) in
            stopUpdating(element)
        }

        //  Remove the inherited transaction if the contentsSource is executing transactions at the point we stop
        //  managing the contents.
        if contentsSource.isExecutingTransactions {
            (self as BroadcastingOrderedSetContentsManager<Element>).managedContents?.endTransaction(withInfo: TransactionInfo(identifier: .inheritedTransaction, originator: contentsSource))
        }

        //  Call super in case it ever does anything.
        super.stopUpdating()
    }

}
