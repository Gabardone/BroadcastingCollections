//
//  BroadcastingOrderedSetSelectionController.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


public protocol BroadcastingOrderedSetSelectionControllerProtocol {
    //  Declare all the notification/userInfo keys here so they are shared between all templated instances of
    //  OrderedSetSelectionController
    //  We don't declare more of the API here as the gains from doing so are unclear. If swift ever lets easy inheriting
    //  from protocol implementations happen it may be worthwhile revisiting as it would simplify the generated logic.

    static var outgoingSelectedElements: String { get }  //  Value is Set<Element>
    static var incomingSelectedElements: String { get }  //  Value is Set<Element>

    static var selectedIndexesWillChange: Notification.Name { get }
    static var selectedIndexesDidChange: Notification.Name { get }

    static var outgoingSelectedIndexes: String { get }  //  Value is IndexSet
    static var incomingSelectedIndexes: String { get }  //  Value is IndexSet
}


extension BroadcastingOrderedSetSelectionControllerProtocol {

    public static var outgoingSelectedElements: String {
        get {
            return "outgoingSelectedElements"
        }
    }


    public static var incomingSelectedElements: String {
        get {
            return "incomingSelectedElements"
        }
    }


    public static var selectedIndexesWillChange: Notification.Name {
        get {
            return Notification.Name("OrderedSetSelectedIndexesWillChange")
        }
    }


    public static var selectedIndexesDidChange: Notification.Name {
        get {
            return Notification.Name("OrderedSetSelectedIndexesDidChange")
        }
    }


    public static var outgoingSelectedIndexes: String {
        get {
            return "outgoingSelectedIndexes"
        }
    }


    public static var incomingSelectedIndexes: String {
        get {
            return "incomingSelectedIndexes"
        }
    }
}


/**
 Manages selection for a broadcasting ordered set. Sets itself as a listener, then updates selection after changes in
 the broadcaster's contents. Being a BroadcastingCollectionRepublisher guarantees that the selection updates will
 happen after the listeners have had the chance to deal with the updated contents.

 Selection changes happen after broadcaster's changes as a matter of policy since there's no other way to guarantee
 otherwise that the new selection will be available. As such any logic which simultaneously updates based on the changes
 it listenst to and also keeps track of the selection needs to be able to deal with the fact that between both calls
 the selection may not reflect what's in the contents.
 */
public class BroadcastingOrderedSetSelectionController<Element: Hashable & AnyObject>: BroadcastingOrderedSetRepublisher<Element, Element>, BroadcastingOrderedSetSelectionControllerProtocol, BroadcastingOrderedSetFullListener {

    //  MARK: _ Selection management

    private let editableBroadcastingSelectedElements = EditableBroadcastingSet<Element>() //  Here's where we keep the value, we manage it elsewhere.

    public var broadcastingSelectedElements: BroadcastingSet<Element> {
        return editableBroadcastingSelectedElements
    }

    public var selectedElements: Set<Element> {
        get {
            return editableBroadcastingSelectedElements.contents
        }

        set {
            if editableBroadcastingSelectedElements.contents != newValue {
                let newSelectedIndexes: IndexSet
                if newValue.count > 0 {
                    guard let sourceContents = republishedBroadcastingOrderedSet?.contents else {
                        ErrorReporter.report("Attempted to select elements while no republished broadcasting ordered set in place")
                        return
                    }

                    newSelectedIndexes = IndexSet(newValue.map({ (element) -> Int in
                        let selectedIndex = sourceContents.index(of: element)
                        guard selectedIndex != NSNotFound else {
                            //  FUBAR!
                            ErrorReporter.report("Attempted to select element not present in the republished broadcasting ordered set: %@", element)
                            return -1   //  This is just to keep testing happy. On regular running fatalError will happen.
                        }

                        return selectedIndex
                    }))
                } else {
                    newSelectedIndexes = IndexSet()
                }

                _updateSelection(elements: newValue, indexes: newSelectedIndexes)
            }
        }
    }


    public func canSelect(_ elements: Set<Element>) -> Bool {
        let selectionCount = elements.count
        if selectionCount > 0 {
            if selectionCount > 1 && !allowsMultipleSelection {
                //  Running afoul of multiple selection restrictions.
                return false
            }

            if !elements.isSubset(of: republishedBroadcastingOrderedSet!.set) {
                //  We're trying to select elements that ain't there.
                return false
            }
        } else if !allowsEmptySelection {
            //  We're trying to empty the selection while not allowed.
            return false
        }

        return true
    }


    public func addElementsToSelection(_ elements: Set<Element>) {
        //  Just set selectedElements as the union of current ones and the given ones. Validation will happen later.
        selectedElements = elements.union(selectedElements)
    }


    public func removeElementsFromSelection(_ elements: Set<Element>) {
        //  Just set selectedElements as current ones minus the ones in elements. Validation will happen later.
        selectedElements = selectedElements.subtracting(elements)
    }


    private var _cachedSelectedIndexes: IndexSet? = IndexSet()

    public var selectedIndexes: IndexSet {
        get {
            if let cachedSelectedIndexes = _cachedSelectedIndexes {
                return cachedSelectedIndexes
            } else {
                return _indexSet(for: selectedElements)
            }
        }

        set {
            if let sourceContents = republishedBroadcastingOrderedSet?.array {
                let newlySelectedElements = Set(newValue.map { (index) -> Element in
                    return sourceContents[index]
                })
                selectedElements = newlySelectedElements
            } else if !newValue.isEmpty {
                ErrorReporter.report("Attempted to set selected indexes on a selection controller with no republished broadcasting ordered set")
            }
        }
    }


    public func canSelect(indexes: IndexSet) -> Bool {
        let selectionCount = indexes.count
        if selectionCount > 0 {
            if selectionCount > 1 && !allowsMultipleSelection {
                //  Running afoul of multiple selection restrictions.
                return false
            }

            if indexes[indexes.startIndex] < 0 || indexes.last! >= republishedBroadcastingOrderedSet!.contents.count {
                //  Indexes off range.
                return false
            }
        } else if !allowsEmptySelection {
            //  Trying to empty the selection and not allowed.
            return false
        }

        return true;
    }


    public func addIndexesToSelection(_ indexes: IndexSet) {
        selectedIndexes = selectedIndexes.union(indexes)
    }


    public func removeIndexesFromSelection(_ indexes: IndexSet) {
        selectedIndexes = selectedIndexes.subtracting(indexes)
    }

    //  MARK: - Selection behavior.

    public var allowsEmptySelection = false {
        didSet {
            //  If we're disallowing empty selection and we'd end up in an invalid state, select something.
            if allowsEmptySelection != oldValue && !allowsEmptySelection && (republishedBroadcastingOrderedSet?.contents.count ?? 0) > 0 && selectedIndexes.count == 0 {
                //  We need to select something, we'll select the first item.
                selectedIndexes = IndexSet(integer: 0)
            }
        }
    }


    public var allowsMultipleSelection = false {
        didSet {
            if allowsMultipleSelection != oldValue && !allowsMultipleSelection && selectedIndexes.count > 1 {
                //  We got multiple selection but don't allow it. deselect everything but the first item.
                selectedIndexes = IndexSet(integer: selectedIndexes[selectedIndexes.startIndex])
            }
        }
    }


    public var selectsPriorOnRemoval = false

    //  MARK: - Selection Looping support.

    public var loopsSelection = false


    public var canSelectPrevious: Bool {
        get {
            let selectedIndexes = self.selectedIndexes
            let selectedIndexCount = selectedIndexes.count
            return selectedIndexCount <= 1 && (selectedIndexCount == 0 || (loopsSelection && republishedBroadcastingOrderedSet?.contents.count ?? 0 > 1) || selectedIndexes[selectedIndexes.startIndex] > 0)
        }
    }


    public func selectPrevious() {
        let sourceContents = republishedBroadcastingOrderedSet?.array ?? []
        let sourceContentsCount = sourceContents.count
        if sourceContentsCount > 0 {
            switch selectedIndexes.count {
            case 0:
                //  Select the last one if there's no selection.
                selectedIndexes = IndexSet(integer: sourceContentsCount - 1)

            case 1:
                //  Verify that selection is valid and calculate the next one.
                var selectedIndex = selectedIndexes[selectedIndexes.startIndex]
                if selectedIndex < sourceContentsCount && (selectedIndex > 0 || (selectedIndex == 0 && loopsSelection)) {
                    selectedIndex -= 1
                    if loopsSelection && selectedIndex < 0 {
                        selectedIndex += sourceContentsCount  //  Swift's modulo isn't really modulo for negative numbers...
                    }
                } else {
                    ErrorReporter.report("Existing selection %d invalid or attempted to select previous on selected first item with looping off", selectedIndex)
                    return
                }

                selectedIndexes = IndexSet(integer: selectedIndex)

            default:
                //  We're trying to selectNext with multiple selection. Undefined behavior.
                ErrorReporter.report("Attempted to select next while having multiple selection: %@", selectedIndexes)
                return
            }
        }
    }


    public var canSelectNext: Bool {
        get {
            let selectedIndexes = self.selectedIndexes
            let selectedIndexCount = selectedIndexes.count
            let sourceContentsCount = republishedBroadcastingOrderedSet?.contents.count ?? 0
            return sourceContentsCount > 0 && selectedIndexCount <= 1 && (selectedIndexCount == 0 || (loopsSelection && sourceContentsCount > 1) || selectedIndexes.last! < sourceContentsCount - 1)
        }
    }


    public func selectNext() {
        let sourceContents = republishedBroadcastingOrderedSet?.array ?? []
        let sourceContentsCount = sourceContents.count
        if sourceContentsCount > 0 {
            switch selectedIndexes.count {
            case 0:
                //  Select the first one if there's no selection.
                selectedIndexes = IndexSet(integer: 0)

            case 1:
                //  Verify that selection is valid and calculate the next one.
                var selectedIndex = selectedIndexes[selectedIndexes.startIndex]
                let lastValidIndex = sourceContentsCount - 1
                if selectedIndex >= 0 && (selectedIndex < lastValidIndex || (selectedIndex == lastValidIndex && loopsSelection)) {
                    selectedIndex += 1
                    if loopsSelection {
                        selectedIndex = selectedIndex % sourceContentsCount
                    }
                } else {
                    ErrorReporter.report("Existing selection %d invalid or attempted to select next on selected last item with looping off", selectedIndex)
                    return
                }

                selectedIndexes = IndexSet(integer: selectedIndex)

            default:
                //  We're trying to selectNext with multiple selection. Undefined behavior.
                ErrorReporter.report("Attempted to select next while having multiple selection: %@", selectedIndexes)
                return
            }
        }
    }

    //  MARK: - Utilities

    private func _updateSelection(elements: Set<Element>, indexes: IndexSet) {
        //  Verify elements and indexes have the same count.
        let selectionCount = elements.count
        guard selectionCount == indexes.count else {
            //  This should never happen but better blow up...
            ErrorReporter.report("Attempted to set a different count of selected elements %lu and selected indexes %lu", selectionCount, indexes.count)
            return
        }

        //  Verify we're not attempting to set an empty selection while not allowed.
        let contentsCount = republishedBroadcastingOrderedSet?.contents.count ?? 0 //  If sourceContents has been cleared we treat as empty.
        guard allowsEmptySelection || selectionCount != 0 || contentsCount == 0 else {
            ErrorReporter.report("Attempted to set empty selection while not allowed")
            return
        }

        //  Verify we're not attempting to set multiple selection while not allowed.
        guard allowsMultipleSelection || selectionCount <= 1 else {
            ErrorReporter.report("Attempted to set multiple selection when not allowed: %@", elements)
            return
        }

        //  Keep the cache around for notification purposes and clear it so callers during changes don't get wrong data.
        //  We may end up with a nil _cachedSelectedIndexes during cleanup.
        let outgoingSelectedIndexes = _cachedSelectedIndexes ?? (republishedBroadcastingOrderedSet != nil ? _indexSet(for: selectedElements) : IndexSet())
        _cachedSelectedIndexes = nil

        let selectedElementsChange = elements != editableBroadcastingSelectedElements.contents
        let selectedIndexesChange = indexes != outgoingSelectedIndexes

        let userInfo: [String:Any]
        switch (selectedElementsChange, selectedIndexesChange) {
        case (false, false):
            //  Nothing to do, let's just leave.
            return

        case (true, false):
            userInfo = [BroadcastingOrderedSetSelectionController.outgoingSelectedElements: editableBroadcastingSelectedElements.contents,
                        BroadcastingOrderedSetSelectionController.incomingSelectedElements: elements]

        case (false, true):
            userInfo = [BroadcastingOrderedSetSelectionController.outgoingSelectedIndexes: outgoingSelectedIndexes,
                        BroadcastingOrderedSetSelectionController.incomingSelectedIndexes: indexes]

        case (true, true):
            userInfo = [BroadcastingOrderedSetSelectionController.outgoingSelectedElements: editableBroadcastingSelectedElements.contents,
                        BroadcastingOrderedSetSelectionController.incomingSelectedElements: elements,
                        BroadcastingOrderedSetSelectionController.outgoingSelectedIndexes: outgoingSelectedIndexes,
                        BroadcastingOrderedSetSelectionController.incomingSelectedIndexes: indexes]
        }

        let notificationCenter = NotificationCenter.default

        //  We begin and end by posting selectedElements change notifications.
        if selectedIndexesChange {
            notificationCenter.post(name: BroadcastingOrderedSetSelectionController.selectedIndexesWillChange, object: self, userInfo: userInfo)
        }

        if selectedElementsChange {
            editableBroadcastingSelectedElements.contents = elements
        }

        if selectedIndexesChange {
            notificationCenter.post(name: BroadcastingOrderedSetSelectionController.selectedIndexesDidChange, object: self, userInfo: userInfo)
        }

        //  We can recache until next time.
        _cachedSelectedIndexes = _indexSet(for: selectedElements)
    }


    private func _indexSet(for elements: Set<Element>) -> IndexSet {
        switch elements.count {
        case 0:
            return IndexSet()

        case 1:
            return IndexSet(integer: republishedBroadcastingOrderedSet!.contents.index(of: elements[elements.startIndex]))

        default:
            let sourceContents = republishedBroadcastingOrderedSet!.contents
            return IndexSet(elements.map({ (element) -> Int in
                return sourceContents.index(of: element)
            }))
        }
    }

    //  MARK: - BroadcastingOrderedSetRepublisher Overrides

    public override var republishedBroadcastingOrderedSet: BroadcastingOrderedSet<Element>? {
        didSet {
            if republishedBroadcastingOrderedSet !== oldValue {
                if let republishedBroadcastingOrderedSet = self.republishedBroadcastingOrderedSet {
                    let selectedElements = self.selectedElements
                    if selectedElements.count > 0 {
                        //  Let's figure out if our selection is still valid.
                        let sourceContents = republishedBroadcastingOrderedSet.contents
                        var newSelectedElements = Set(selectedElements.filter({ (element) -> Bool in
                            return sourceContents.contains(element)
                        }))

                        if !allowsEmptySelection && newSelectedElements.count == 0 && sourceContents.count > 0 {
                            //  Just select the first one.
                            newSelectedElements.insert(sourceContents[0] as! Element)
                        }

                        self.selectedElements = newSelectedElements
                    }

                } else {
                    //  Nil republished broadcasting ordered set, just clear out the selection.
                    selectedElements = Set()
                }
            }
        }
    }


    public override func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didApply change: IndexedCollectionChange<Element>) {
        guard broadcastingOrderedSet === republishedBroadcastingOrderedSet else {
            //  Dunno what to do with this. Conceivable for subclasses to have this happen though.
            return
        }

        //  Make sure we rebroadcast to our listeners before we change selection.
        super.broadcastingOrderedSet(broadcastingOrderedSet, didApply: change)

        //  Now do the fine-grained processing.
        process(broadcastingOrderedSet: broadcastingOrderedSet, didApply: change)
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willInsert elementsAtIndexes: IndexedElements<Element>) {
        //  Empty, just for protocol compliance.
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didInsert elementsAtindexes: IndexedElements<Element>) {
        let selectedIndexes = self.selectedIndexes
        let selectionCount = selectedIndexes.count
        if !allowsEmptySelection && selectionCount == 0 && broadcastingOrderedSet.contents.count > 0 {
            //  If we were empty and don't allow empty selection, select the first inserted item.
            self.selectedIndexes = IndexSet(integer: 0)
        } else if selectionCount > 0 && elementsAtindexes.indexes[elementsAtindexes.indexes.startIndex] <= selectedIndexes.last! {
            //  We have inserted items before selected elements so we need to recalculate the indexes.
            let selectedElements = self.selectedElements
            _updateSelection(elements: selectedElements, indexes: _indexSet(for: selectedElements))
        }
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willRemove elementsAtIndexes: IndexedElements<Element>) {
        //  Empty, just for protocol compliance.
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didRemove elementsAtIndexes: IndexedElements<Element>) {
        let selectedIndexes = self.selectedIndexes
        if selectedIndexes.count > 0 && selectedIndexes.last! >= elementsAtIndexes.indexes.first! {
            //  We're going to have to update the indexes, possibly the elements too.
            //  Let's calculate what selectedElements we end up with and then get the indexes from there.
            let selectedElements = self.selectedElements
            var updatedSelectedElements = selectedElements
            elementsAtIndexes.elements.forEach({ (removedElement) in
                updatedSelectedElements.remove(removedElement)
            })

            if updatedSelectedElements.count == 0 && !allowsEmptySelection && broadcastingOrderedSet.contents.count > 0 {
                //  Well now we need to figure out what to select...
                if let firstRemoved = elementsAtIndexes.indexes.enumerated().first(where: { (enumeration: (offset: Int, index: Int)) -> Bool in
                    return selectedElements.contains(elementsAtIndexes.elements[enumeration.offset])
                }) {
                    //  Now that we know which is the earliest removed, return the same resulting index or one less depending
                    //  on selectsPriorOnRemoval
                    var newlySelectedIndex = firstRemoved.element - firstRemoved.offset

                    //  We'll try to select the prior one if we're set that way and we can.
                    if selectsPriorOnRemoval && newlySelectedIndex > 0 {
                        newlySelectedIndex -= 1
                    }

                    updatedSelectedElements.insert(broadcastingOrderedSet.array[newlySelectedIndex])
                }
            }

            //  We're good to go.
            _updateSelection(elements: updatedSelectedElements, indexes: _indexSet(for: updatedSelectedElements))
        }
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willMove element: Element, from fromIndex: Int, to toIndex: Int) {
        //  Empty, just for protocol compliance.
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didMove element: Element, from fromIndex: Int, to toIndex: Int) {
        let selectedIndexes = self.selectedIndexes
        if selectedIndexes.count > 0 {
            //  Refresh the selection indexes as they may have changed.
            _updateSelection(elements: selectedElements, indexes: _indexSet(for: selectedElements))
        }
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, willReplace replacees: IndexedElements<Element>, with replacements: IndexedElements<Element>) {
    }


    public func broadcastingOrderedSet(_ broadcastingOrderedSet: BroadcastingOrderedSet<Element>, didReplace replacees: IndexedElements<Element>, with replacements: IndexedElements<Element>) {
        //  If we replaced any of the selected indexes, we'll want to update selected elements and keep selected indexes
        //  the same.
        let selectedIndexes = self.selectedIndexes
        if !selectedIndexes.isDisjoint(with: replacements.indexes) {
            let sourceContents = broadcastingOrderedSet.array
            _updateSelection(elements: Set(sourceContents[selectedIndexes]), indexes: selectedIndexes)
        }
    }
}
