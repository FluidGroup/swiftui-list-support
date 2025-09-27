# SwiftUI List Support

A comprehensive collection of essential components for building advanced list-based UIs in SwiftUI, with high-performance UIKit bridges when needed.

## Requirements

- iOS 17.0+
- macOS 15.0+
- Swift 6.0

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/FluidGroup/swiftui-list-support.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. Go to File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/FluidGroup/swiftui-list-support.git`
3. Select the modules you need

## Modules

### 1. DynamicList - UIKit UICollectionView Bridge

A UIKit-based `UICollectionView` implementation wrapped for SwiftUI, providing maximum performance for large datasets with SwiftUI cell hosting.

#### Key Components:
- **DynamicListView**: UIKit UICollectionView with NSDiffableDataSource
- **VersatileCell**: Flexible cell supporting SwiftUI content via hosting
- **ContentPagingTrigger**: Automatic content loading as user scrolls
- **CellState**: Custom state storage for cells

#### SwiftUI Usage:

```swift
import DynamicList
import SwiftUI

struct MyListView: View {
  var body: some View {
    DynamicList(
      snapshot: snapshot,
      layout: {
        UICollectionViewCompositionalLayout.list(
          using: .init(appearance: .plain)
        )
      },
      scrollDirection: .vertical
    ) { context in
      context.cell { state in
        // SwiftUI content in cell
        Text("Item: \(context.data.title)")
          .padding()
      }
    }
    .incrementalContentLoading {
      await loadMoreData()
    }
  }
}
```


#### Custom Cell States:

```swift
// Define custom state key
enum IsArchivedKey: CustomStateKey {
  typealias Value = Bool
  static var defaultValue: Bool { false }
}

// Extend CellState
extension CellState {
  var isArchived: Bool {
    get { self[IsArchivedKey.self] }
    set { self[IsArchivedKey.self] = newValue }
  }
}
```

### 2. CollectionView - Pure SwiftUI Layouts

Pure SwiftUI implementation using native components like ScrollView with Lazy stacks. **Not** based on UICollectionView.

#### Layout Options:
- `.list`: ScrollView with LazyVStack/LazyHStack
- `.grid(...)`: ScrollView with LazyVGrid/LazyHGrid
- `.platformList`: Native SwiftUI List

#### Basic List Layout:

```swift
import CollectionView
import SwiftUI

struct ContentView: View {
  var body: some View {
    CollectionView(layout: .list) {
      ForEach(items) { item in
        ItemView(item: item)
      }
    }
  }
}
```

#### Grid Layout:

```swift
CollectionView(
  layout: .grid(
    gridItems: [
      GridItem(.flexible()),
      GridItem(.flexible()),
      GridItem(.flexible())
    ],
    direction: .vertical,
    spacing: 8
  )
) {
  ForEach(items) { item in
    GridItemView(item: item)
  }
}
```

#### Infinite Scrolling with ScrollTracking:

```swift
struct InfiniteFeedView: View {
  @State private var items: [FeedItem] = []
  @State private var isLoading = false
  @State private var hasError = false
  @State private var currentPage = 1

  var body: some View {
    CollectionView(layout: .list) {
      ForEach(items) { item in
        FeedItemView(item: item)
      }
      
      // Loading indicator at the bottom
      if isLoading {
        HStack {
          ProgressView()
          Text("Loading more...")
        }
        .frame(maxWidth: .infinity)
        .padding()
      }
    }
    .onAdditionalLoading(
      isEnabled: !hasError, // Disable when there's an error
      leadingScreens: 1.5,   // Trigger 1.5 screens before the end
      isLoading: $isLoading,
      onLoad: {
        await loadMoreItems()
      }
    )
    .onAppear {
      if items.isEmpty {
        Task {
          await loadMoreItems()
        }
      }
    }
  }
  
  private func loadMoreItems() async {
    do {
      let newItems = try await APIClient.fetchFeedItems(page: currentPage)
      if !newItems.isEmpty {
        items.append(contentsOf: newItems)
        currentPage += 1
        hasError = false
      }
    } catch {
      hasError = true
      print("Failed to load items: \(error)")
    }
  }
}
```

#### Advanced Integration Example:

```swift
struct AdvancedCollectionView: View {
  @State private var items: [Item] = []
  @State private var selectedItems: Set<Item.ID> = []
  @State private var isLoading = false

  var body: some View {
    CollectionView(
      layout: .grid(
        gridItems: Array(repeating: GridItem(.flexible()), count: 2),
        direction: .vertical,
        spacing: 8
      )
    ) {
      // Header with refresh control
      RefreshControl(
        threshold: 60,
        action: {
          await refreshAllItems()
        }
      ) { context in
        // Custom refresh indicator
      }
      
      // Selectable items with infinite scrolling
      SelectableForEach(
        data: items,
        selection: .multiple(
          selected: selectedItems,
          canSelectMore: selectedItems.count < 10,
          onChange: handleSelection
        )
      ) { index, item in
        GridItemView(item: item)
      }
    }
    .onAdditionalLoading(
      isLoading: $isLoading,
      onLoad: {
        await loadMoreItems()
      }
    )
  }
  
  private func handleSelection(_ item: Item.ID, _ action: SelectAction) {
    switch action {
    case .selected:
      selectedItems.insert(item)
    case .deselected:
      selectedItems.remove(item)
    }
  }
}

### 3. SelectableForEach

A ForEach alternative that adds selection capabilities with environment values for selection state. Works with any container view - List, ScrollView, VStack, or custom containers.

#### Single Selection:

```swift
import SelectableForEach

struct SelectableListView: View {
  @State private var selectedItem: Item.ID?

  var body: some View {
    List {
      SelectableForEach(
        data: items,
        selection: .single(
          selected: selectedItem,
          onChange: { newSelection in
            selectedItem = newSelection
          }
        )
      ) { index, item in
        ItemCell(item: item)
      }
    }
  }
}
```

#### Multiple Selection:

```swift
struct MultiSelectListView: View {
  @State private var selectedItems = Set<Item.ID>()

  var body: some View {
    ScrollView {
      LazyVStack {
        SelectableForEach(
          data: items,
          selection: .multiple(
            selected: selectedItems,
            canSelectMore: true,
            onChange: { selectedItem, action in
              switch action {
              case .selected:
                selectedItems.insert(selectedItem)
              case .deselected:
                selectedItems.remove(selectedItem)
              }
            }
          )
        ) { index, item in
          ItemCell(item: item)
        }
      }
    }
  }
}
```

#### Accessing Selection State in Child Views:

```swift
struct ItemCell: View {
  let item: Item
  @Environment(\.selectableForEach_isSelected) var isSelected
  @Environment(\.selectableForEach_updateSelection) var updateSelection

  var body: some View {
    HStack {
      Text(item.title)
      Spacer()
      if isSelected {
        Image(systemName: "checkmark")
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      updateSelection(!isSelected)
    }
    .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
  }
}
```

#### Usage with Any Container:

```swift
// With native SwiftUI List
List {
  SelectableForEach(data: items, selection: selection) { index, item in
    ItemRow(item: item)
  }
}

// With VStack
VStack {
  SelectableForEach(data: items, selection: selection) { index, item in
    ItemCard(item: item)
  }
}

// With CollectionView
CollectionView(layout: .grid(...)) {
  SelectableForEach(data: items, selection: selection) { index, item in
    GridItem(item: item)
  }
}
```

### 4. ScrollTracking

Provides infinite scrolling (additional loading) functionality for SwiftUI ScrollView and List views. Automatically triggers loading when the user approaches the end of scrollable content.

```swift
import ScrollTracking

struct InfiniteScrollView: View {
  @State private var items = Array(0..<20)
  @State private var isLoading = false

  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(items, id: \.self) { index in
          Text("Item \(index)")
            .frame(height: 50)
        }
        
        if isLoading {
          ProgressView()
            .frame(height: 50)
        }
      }
    }
    .onAdditionalLoading(
      leadingScreens: 2, // Trigger when 2 screen heights from bottom
      isLoading: $isLoading,
      onLoad: {
        // This runs automatically when user scrolls near the end
        let lastItem = items.last ?? -1
        let newItems = Array((lastItem + 1)..<(lastItem + 20))
        items.append(contentsOf: newItems)
      }
    )
  }
}

// Also works with List
struct InfiniteList: View {
  @State private var items = Array(0..<20)
  @State private var isLoading = false

  var body: some View {
    List(items, id: \.self) { index in
      Text("Item \(index)")
    }
    .onAdditionalLoading(
      isLoading: $isLoading,
      onLoad: {
        let lastItem = items.last ?? -1
        let newItems = Array((lastItem + 1)..<(lastItem + 20))
        items.append(contentsOf: newItems)
      }
    )
  }
}

// Manual loading state management variant
struct ManualInfiniteScrollView: View {
  @State private var items = Array(0..<20)
  @State private var isLoading = false

  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(items, id: \.self) { index in
          Text("Item \(index)")
            .frame(height: 50)
        }
      }
    }
    .onAdditionalLoading(
      isLoading: isLoading, // Pass current value (not binding)
      onLoad: {
        guard !isLoading else { return }
        isLoading = true
        Task {
          // Your async loading logic here
          defer { isLoading = false }
          let newItems = await fetchMoreItems()
          items.append(contentsOf: newItems)
        }
      }
    )
  }
}
```

#### Parameters:
- `isEnabled`: Toggles the behavior on/off (default: true)
- `leadingScreens`: Trigger threshold in multiples of screen height (default: 2)
- `isLoading`: Loading state binding or current value
- `onLoad`: Closure executed when loading should occur

#### Features:
- Works with both `ScrollView` and `List`
- Automatic loading state management with binding variant
- Manual loading state management with non-binding variant
- Configurable trigger threshold
- Prevents duplicate loads while one is in progress
- Handles small content (triggers immediately if content is smaller than viewport)

### 5. StickyHeader

Implements sticky header behavior with stretching effect for ScrollView.

```swift
import StickyHeader

struct StickyHeaderView: View {
  var body: some View {
    ScrollView {
      StickyHeader(sizing: .content) { context in
        VStack {
          Image("header-image")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 200 + context.stretchingValue)

          Text("Stretching: \(context.phase == .stretching ? "Yes" : "No")")
            .padding()
        }
      }

      LazyVStack {
        ForEach(items) { item in
          ItemView(item: item)
        }
      }
    }
  }
}
```

#### Fixed Height Header:

```swift
StickyHeader(sizing: .fixed(250)) { context in
  HeaderContent()
    .scaleEffect(1 + context.stretchingValue / 100)
}
```

### 6. RefreshControl

Custom pull-to-refresh control for ScrollView with customizable appearance.

```swift
import RefreshControl

struct RefreshableList: View {
  @State private var items: [Item] = []

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        RefreshControl(
          threshold: 80,
          action: {
            await refreshData()
          }
        ) { context in
          VStack {
            switch context.state {
            case .pulling(let progress):
              Image(systemName: "arrow.down")
                .rotationEffect(.degrees(progress * 180))
              if progress >= 1.0 {
                Text("Release to refresh")
              }
            case .refreshing:
              ProgressView()
              Text("Refreshing...")
            default:
              EmptyView()
            }
          }
          .padding()
        }

        LazyVStack {
          ForEach(items) { item in
            ItemView(item: item)
          }
        }
      }
    }
  }

  func refreshData() async {
    // Fetch new data
    try? await Task.sleep(for: .seconds(1))
    items = await fetchLatestItems()
  }
}
```

## Architecture Comparison

| Module | Implementation | Use Case |
|--------|---------------|----------|
| **DynamicList** | UIKit UICollectionView with SwiftUI hosting | Maximum performance, large datasets, complex layouts |
| **CollectionView** | Pure SwiftUI (ScrollView + Lazy stacks) | Simple layouts, moderate datasets, pure SwiftUI apps |
| **SelectableForEach** | Pure SwiftUI with environment values | Add selection to any container view |



## License

This library is available under the MIT license. See the LICENSE file for more info.

## Author

[FluidGroup](https://github.com/FluidGroup)