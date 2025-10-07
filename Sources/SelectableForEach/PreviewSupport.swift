
#if DEBUG

import SwiftUI

struct Item: Identifiable, Hashable {
  var id: Int
  var title: String
  
  static func mock(_ count: Int = 1000) -> [Item] {
    return (0..<count).map { index in
      Item(id: index, title: "Item \(index)")
    }
  }
}

struct Cell: View {
  
  @Environment(\.isEnabled) var isEnabled
  @Environment(\.collectionView_isSelected) var isSelected
  @Environment(\.collectionView_updateSelection) var updateSelection
  
  let index: Int
  let item: Item
  
  init(index: Int, item: Item) {

    self.index = index
    self.item = item
  }
  
  var body: some View {

    let _ = Self._printChanges()

    HStack {
      Circle()
        .fill(.purple)
        .frame(width: 20, height: 20)
        .opacity(isSelected ? 1 : 0.2)
      Text(item.title)
      Spacer()
    }
    .padding(.horizontal, 20)
    .opacity(isEnabled ? 1 : 0.2)   
    ._onButtonGesture(
      pressing: { _ in },
      perform: {
        updateSelection(!isSelected)
      })
  }
}
#endif
