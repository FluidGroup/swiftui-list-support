import CollectionView
import SwiftUI

@available(iOS 17.0, *)
public struct HoppingLayout<Selection: Hashable>: CollectionViewLayoutType {

  private let scrollPosition: Binding<Selection?>?

  public init(
    selection: Binding<Selection?>
  ) {
    self.scrollPosition = selection
  }

  public init() where Selection == Never {
    self.scrollPosition = nil
  }

  public func body(content: Content) -> some View {
    let view = ScrollView(.vertical, showsIndicators: false) {
      // In iOS17, scrollTargetLayout only works if its content is LazyVStack.
      UnaryViewReader(readingContent: content) { children in
        LazyVStack(spacing: 16) {
          ForEach(children, id: \.id) { child in
            child
              .containerRelativeFrame(.vertical)
          }
        }
        .scrollTargetLayout()
      }
    }
    .scrollTargetBehavior(.viewAligned)
    .safeAreaPadding(.vertical, 32)

    if let scrollPosition {
      ScrollViewReader { proxy in
        view
          .animation(
            .smooth,
            body: {
              $0.scrollPosition(id: scrollPosition)
            }
          )
          .onAppear {
            proxy.scrollTo(scrollPosition.wrappedValue)
          }
      }
    } else {
      view
    }
  }

}

// MARK: workaround

/// https://movingparts.io/variadic-views-in-swiftui
struct UnaryViewReader<ReadingContent: View, Content: View>: View {

  let readingContent: ReadingContent
  let content: (_VariadicView_Children) -> Content

  init(
    readingContent: ReadingContent,
    @ViewBuilder content: @escaping (_VariadicView_Children) -> Content
  ) {
    self.readingContent = readingContent
    self.content = content
  }

  // MARK: View

  var body: some View {
    _VariadicView.Tree(_UnaryView(content: content)) {
      readingContent
    }
  }

}

struct MultiViewReader<ReadingContent: View, Content: View>: View {

  let readingContent: ReadingContent
  let content: (_VariadicView_Children) -> Content

  init(
    readingContent: ReadingContent,
    @ViewBuilder content: @escaping (_VariadicView_Children) -> Content
  ) {
    self.readingContent = readingContent
    self.content = content
  }

  // MARK: View

  var body: some View {
    _VariadicView.Tree(_MultiView(content: content)) {
      readingContent
    }
  }

}

private struct _UnaryView<Content: View>: _VariadicView_UnaryViewRoot {

  let content: (_VariadicView_Children) -> Content

  init(@ViewBuilder content: @escaping (_VariadicView_Children) -> Content) {
    self.content = content
  }

  @ViewBuilder
  func body(children: _VariadicView.Children) -> some View {
    content(children)
  }
}

private struct _MultiView<Content: View>: _VariadicView_MultiViewRoot {

  let content: (_VariadicView_Children) -> Content

  init(@ViewBuilder content: @escaping (_VariadicView_Children) -> Content) {
    self.content = content
  }

  @ViewBuilder
  func body(children: _VariadicView.Children) -> some View {
    content(children)
  }
}

#Preview("Hopping 1") {

  @Previewable @State var scrollPosition: Int? = 3

  VStack {
    HStack {
      Button("One") {
        scrollPosition = 1
      }
      Button("Two") {
        scrollPosition = 2
      }
      Button("Three") {
        scrollPosition = 3
      }
    }
    .buttonStyle(.bordered)

    CollectionView(
      layout: HoppingLayout(selection: $scrollPosition)
    ) {
      ForEach(0..<30, id: \.self) { i in
        CardItem(
          title: "Item \(i)",
          color: .purple
        )
        .id(i)
      }
    }
  }
}

#Preview("Hopping 2") {

  @Previewable @State var scrollPosition: Int? = 3

  VStack {
    HStack {
      Button("One") {
        scrollPosition = 1
      }
      Button("Two") {
        scrollPosition = 2
      }
      Button("Three") {
        scrollPosition = 3
      }
    }
    .buttonStyle(.bordered)

    CollectionView(
      layout: HoppingLayout(selection: $scrollPosition)
    ) {
      ForEach(0..<30, id: \.self) { i in
        Text("Item \(i)")
          .background(.red.opacity(0.3))
          .id(i)
        .id(i)
      }
    }
  }
}

private struct CardItem: View {
  let title: String
  let color: Color

  var body: some View {
    ZStack {
      color
      Text(title)
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.white)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 24)
  }
}


public struct Hopping<Selection: Hashable, Content: View>: View {

  private let content: Content
  private let scrollPosition: Binding<Selection?>?

  public init(
    selection: Binding<Selection?>,
    @ViewBuilder content: () -> Content
  ) {
    self.scrollPosition = selection
    self.content = content()
  }

  public init(
    @ViewBuilder content: () -> Content
  ) where Selection == Never {
    self.scrollPosition = nil
    self.content = content()
  }

  public var body: some View {
  
    
//    let view = ScrollView(.vertical, showsIndicators: false) {
//      // In iOS17, scrollTargetLayout only works if its content is LazyVStack.
//      UnaryViewReader(readingContent: content) { children in
//        LazyVStack(spacing: 16) {
//          ForEach(children, id: \.id) { child in
//            child
//              .containerRelativeFrame(.vertical)
//          }
//        }
//        .scrollTargetLayout()
//      }
//    }
//    .scrollTargetBehavior(.viewAligned)
//    .safeAreaPadding(.vertical, 32)
//
//    if let scrollPosition {
//      ScrollViewReader { proxy in
//        view
//          .animation(
//            .smooth,
//            body: {
//              $0.scrollPosition(id: scrollPosition)
//            }
//          )
//          .onAppear {
//            proxy.scrollTo(scrollPosition.wrappedValue)
//          }
//      }
//    } else {
//      view
//    }
  }

}

#Preview("ScrollView") {

  @Previewable @State var selection: Int? = 1

  VStack {
    HStack {
      Button("One") {
        selection = 0
      }
      Button("Two") {
        selection = 1
      }
      Button("Three") {
        selection = 2
      }
      Button("Clear") {
        selection = nil
      }
    }
    Hopping(selection: $selection) {
      ForEach(0..<10, id: \.self) { i in
        Text("Item \(i)")
          .background(.red.opacity(0.3))
          .id(i)
      }
    }
    .onChange(of: selection, initial: true) {
      print(selection)
    }
  }
}
