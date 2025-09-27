# swiftui-list-support
Convenient component displaying elements in UICollectionView - Supports SwiftUI-based cell

## Requirements

- iOS 14 +
- iPhone Platform

## Instructions

> Works in UIKit

```swift
let list = DynamicListView<Section, Element>.init(...)
```

Setting how displays cells
    
```swift
list.setUp(
  cellProvider: { context in
    let data = context.data
    // return cell
  }
)
```

the context in cellProvider closure supports making SwiftUI based cells.

```swift
let cell = context.cell { state in
  Text("Hello")
}
return cell
```

setting how handles the events of selected or deselected

```swift
list.setSelectionHandler { action in
  switch action {
  case .didSelect(let item):
    print("Selected \(String(describing: item))")
  case .didDeselect(let item):
    print("Deselected \(String(describing: item))")
  }
}
```

basic configuration is completed.  
then set the content that displays.

```swift
list.setContents(contents, inSection: targetSection)
```

## Additional functions

it supports a trigger event when the scrolling will be reaching the tail.  
that will be good timing to trigger loading additional data.

```swift
list.setIncrementalContentLoader { 
  await loadMoreData()
}
```
