import SwiftUI
import IndexedCollection

/**
 A structure that computes views on demand from an underlying collection of identified data with selection funtion.
 The contents that produced by ForEach have environment values that indicate the selection state.
 
 ```
 @Environment(\.selectableForEach_isSelected) var isSelected: Bool
 @Environment(\.selectableForEach_updateSelection) var updateSelection: (Bool) -> Void
 ```
 */
public struct SelectableForEach<
  Data: RandomAccessCollection,
  Cell: View,
  Selection: SelectionState
>: View where Data.Element: Identifiable {
  
  public let data: Data
  public let selection: Selection
  public let selectionIdentifier: KeyPath<Data.Element, Selection.Identifier>
  private let cell: (Data.Index, Data.Element) -> Cell
  
  public init(
    data: Data,
    selection: Selection,
    selectionIdentifier: KeyPath<Data.Element, Selection.Identifier>,
    @ViewBuilder cell: @escaping (Data.Index, Data.Element) -> Cell
  ) {
    self.data = data
    self.cell = cell
    self.selectionIdentifier = selectionIdentifier
    self.selection = selection
  }
  
  public init(
    data: Data,
    selection: Selection,
    @ViewBuilder cell: @escaping (Data.Index, Data.Element) -> Cell
  ) where Selection.Identifier == Data.Element.ID {
    self.data = data
    self.cell = cell
    self.selectionIdentifier = \.id
    self.selection = selection
  }
        
  public var body: some View {
    ForEach(IndexedCollection(data)) { element in
            
      selection.applyEnvironments(
        for: cell(element.index, element.value), 
        identifier: element.value[keyPath: selectionIdentifier]
      )      
    }
  }
  
}

extension EnvironmentValues {
  /**
   A boolean value that indicates whether the cell is selected.
   Provided by the ``SelectableForEach`` view.
   */
  @available(*, deprecated, renamed: "selectableForEach_isSelected")
  @Entry public var collectionView_isSelected: Bool = false
  
  public var selectableForEach_isSelected: Bool {
    get { self.collectionView_isSelected }
    set { self.collectionView_isSelected = newValue }
  }
}

extension EnvironmentValues {
  /**
   A closure that updates the selection state of the cell.
   Provided by the ``SelectableForEach`` view.
   */
  @available(*, deprecated, renamed: "selectableForEach_updateSelection")
  @Entry public var collectionView_updateSelection: UpdateSelectionAction = .init { _ in }
  
  public var selectableForEach_updateSelection: UpdateSelectionAction {
    get { self.collectionView_updateSelection }
    set { self.collectionView_updateSelection = newValue }
  }
}

public struct UpdateSelectionAction {

  private let handler: (Bool) -> Void

  nonisolated public init(handler: @escaping (Bool) -> Void) {
    self.handler = handler
  }

  public func callAsFunction(_ value: Bool) {
    handler(value)
  }

}
