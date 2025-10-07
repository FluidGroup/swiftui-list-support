import SwiftUI

public enum SelectAction {
  case selected
  case deselected
}

public protocol SelectionState<Identifier> {
  
  associatedtype Identifier: Hashable
  
  /// Returns whether the item is selected or not
  func isSelected(for identifier: Identifier) -> Bool
  
  /// Returns whether the item is enabled to be selected or not
  func isEnabled(for identifier: Identifier) -> Bool
  
  /// Update the selection state
  func update(isSelected: Bool, for identifier: Identifier)
}

extension SelectionState {
  
  public func applyEnvironments<Body: View>(for body: Body, identifier: Identifier) -> some View {
    
    let isSelected: Bool = isSelected(for: identifier)
    let isDisabled: Bool = !isEnabled(for: identifier)

    return body
      .disabled(isDisabled)
      .environment(\.collectionView_isSelected, isSelected)
      .environment(
        \.collectionView_updateSelection,
         .init(handler: { isSelected in
           self.update(isSelected: isSelected, for: identifier)
         })
      )
  }
  
}

extension SelectionState {
  
  public static func single<Identifier: Hashable>(
    selected: Identifier?,
    onChange: @escaping (_ selected: Identifier?) -> Void
  ) -> Self where Self == SelectionStateContainers.Single<Identifier> {
    .init(
      selected: selected,
      onChange: onChange
    )
  }
  
  public static func multiple<Identifier: Hashable>(
    selected: Set<Identifier>,
    canSelectMore: Bool,
    onChange: @escaping (_ selected: Identifier, _ selection: SelectAction) -> Void
  ) -> Self where Self == SelectionStateContainers.Multiple<Identifier> {
    .init(
      selected: selected,
      canSelectMore: canSelectMore,
      onChange: onChange
    )
  }
  
  public static func disabled<Identifier: Hashable>() -> Self where Self == SelectionStateContainers.Disabled<Identifier> {
    .init()    
  }
  
}

/**
 A namespace for selection state containers. 
 */
public enum SelectionStateContainers {
  
  public struct Disabled<Identifier: Hashable>: SelectionState {
    
    public init() {
      
    }
    
    public func isSelected(for id: Identifier) -> Bool {
      false
    }
    
    public func isEnabled(for id: Identifier) -> Bool {
      true
    }    
    
    public func update(isSelected: Bool, for identifier: Identifier) {
      
    }
  }
  
  public struct Single<Identifier: Hashable>: SelectionState {
    
    public let selected: Identifier?
    
    private let onChange: (_ selected: Identifier?) -> Void
    
    public init(
      selected: Identifier?,
      onChange: @escaping (_ selected: Identifier?) -> Void
    ) {
      self.selected = selected
      self.onChange = onChange
    }
    
    public func isSelected(for id: Identifier) -> Bool {
      self.selected == id
    }
    
    public func isEnabled(for id: Identifier) -> Bool {
      return true
    }
    
    public func update(isSelected: Bool, for item: Identifier) {
      if isSelected {
        onChange(item)
      } else {
        onChange(nil)
      }
    }
    
  }
  
  public struct Multiple<Identifier: Hashable>: SelectionState {
    
    public let selected: Set<Identifier>
    
    public let canSelectMore: Bool
    
    private let onChange: (_ selected: Identifier, _ action: SelectAction) -> Void
    
    public init(
      selected: Set<Identifier>,
      canSelectMore: Bool,
      onChange: @escaping (_ selected: Identifier, _ action: SelectAction) -> Void
    ) {
      self.selected = selected
      self.canSelectMore = canSelectMore
      self.onChange = onChange                  
    }
    
    public func isSelected(for id: Identifier) -> Bool {
      self.selected.contains(id)
    }
    
    public func isEnabled(for id: Identifier) -> Bool {
      if isSelected(for: id) {
        return true
      }
      return canSelectMore
    }
    
    public func update(isSelected: Bool, for identifier: Identifier) {
      if isSelected {
        onChange(identifier, .selected)
      } else {
        onChange(identifier, .deselected)
      }
    }
  }
  
}
