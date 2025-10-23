import SwiftUI

public struct StickyHeaderContext {

  public enum Phase {
    case idle
    case stretching
  }

  public let topMargin: CGFloat
  public let stretchingValue: CGFloat
  public let phase: Phase

  init(
    topMargin: CGFloat,
    stretchingValue: CGFloat,
    phase: Phase
  ) {
    self.topMargin = topMargin
    self.stretchingValue = stretchingValue
    self.phase = phase
  }
}

/// A view that sticks to the top of the screen in a ScrollView.
/// When it's bouncing, it stretches the content.
public struct StickyHeader<Content: View>: View {

  /**
   The option to determine how to size the header.
   */
  public enum Sizing {
    /// Uses the given content's intrinsic size.
    case content
    /// Uses the fixed height.
    case fixed(CGFloat)
  }

  public let sizing: Sizing
  public let content: (StickyHeaderContext) -> Content

  @State var baseContentHeight: CGFloat?
  @State var stretchingValue: CGFloat = 0
  @State var topMargin: CGFloat = 0

  public init(
    sizing: Sizing,
    @ViewBuilder content: @escaping (StickyHeaderContext) -> Content
  ) {
    self.sizing = sizing
    self.content = content
  }

  public var body: some View {


    let context = StickyHeaderContext(
      topMargin: topMargin,
      stretchingValue: stretchingValue,
      phase: stretchingValue > 0 ? .stretching : .idle
    )

    Group {
      switch sizing {
      case .content:
        
        let height = stretchingValue > 0
        ? baseContentHeight.map { $0 + stretchingValue }
        : nil
        
        let baseContentHeight = stretchingValue > 0 ? self.baseContentHeight ?? 0 : nil
                
        content(context)
          .onGeometryChange(for: CGSize.self, of: \.size) { size in
            if stretchingValue == 0 {
              self.baseContentHeight = size.height
            }
          }
          .frame(
            height: height
          )
          .offset(y: stretchingValue > 0 ? -stretchingValue : 0)
          // container
          .frame(height: baseContentHeight, alignment: .top)

      case .fixed(let height):
        
        let offsetY: CGFloat = 0

        content(context)
          .frame(height: height + stretchingValue + offsetY)
          .offset(y: -offsetY)
          .offset(y: -stretchingValue)
          // container
          .frame(height: height, alignment: .top)
      }
    }
    .onGeometryChange(
      for: Pair.self,
      of: {
        Pair(
          minYInGlobal: $0.frame(in: .global).minY,
          minYInCoordinateSpace: $0.frame(in: .scrollView).minY
        )
      },
      action: { pair in

        self.stretchingValue = max(0, pair.minYInCoordinateSpace)

        let minY = pair.minYInGlobal
        if minY >= 0, topMargin != minY {
          topMargin = minY - stretchingValue
        }
      }
    )

  }
}

private struct Pair: Equatable {
  let minYInGlobal: CGFloat
  let minYInCoordinateSpace: CGFloat
}

#Preview("dynamic") {
  ScrollView {

    Section {

      ForEach(0..<100, id: \.self) { _ in
        Text("Hello World!")
          .frame(maxWidth: .infinity)
      }

    } header: {

      StickyHeader(sizing: .content) { context in

        ZStack {

          Rectangle()
            .stroke(lineWidth: 10)
            .padding(.top, -context.topMargin)
          //

          VStack {
            Text("StickyHeader")
            Text("StickyHeader")
            Text("StickyHeader")
          }
          .border(Color.red)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          //        .background(.yellow)
          //        .background(
          //          Color.green
          //            .padding(.top, -context.topMargin)
          //
          //        )
        }
      }
    }

  }
}

#Preview("dynamic full") {
  ScrollView {

    StickyHeader(sizing: .content) { context in

      ZStack {

        Color.red

        VStack {
          Text("StickyHeader")
          Text("StickyHeader")
          Text("StickyHeader")
        }
        .border(Color.red)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.yellow)
        .background(
          Color.green
            .padding(.top, -100)

        )
      }

    }

    ForEach(0..<100, id: \.self) { _ in
      Text("Hello World!")
        .frame(maxWidth: .infinity)
    }
  }
}

#Preview("fixed") {
  ScrollView {

    StickyHeader(sizing: .fixed(300)) { context in

      Rectangle()
        .stroke(lineWidth: 10)
        .overlay(
          VStack {
            Text("StickyHeader")
            Text("StickyHeader")
            Text("StickyHeader")
          }
        )
    }

    ForEach(0..<100, id: \.self) { _ in
      Text("Hello World!")
        .frame(maxWidth: .infinity)
    }
  }
  .padding(.vertical, 100)
}

#Preview("fixed full") {
  ScrollView {

    Section {

      ForEach(0..<100, id: \.self) { _ in
        Text("Hello World!")
          .frame(maxWidth: .infinity)
      }
    } header: {

      StickyHeader(sizing: .fixed(300)) { context in

        ZStack {

          Color.red
            .padding(.top, -context.topMargin)
          //

          VStack {
            Text("StickyHeader")
            Text("StickyHeader")
            Text("StickyHeader")
          }
          .border(Color.red)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          //        .background(.yellow)
          //        .background(
          //          Color.green
          //            .padding(.top, -context.topMargin)
          //
          //        )
        }
      }
    }
    .padding(.top, 20)

  }
}


#Preview("dynamic height change") {
  @Previewable @State var itemCount: Int = 3

  return ScrollView {

    StickyHeader(sizing: .content) { context in

      ZStack {

        Color.red

        VStack(spacing: 8) {
          ForEach(0..<itemCount, id: \.self) { index in
            Text("StickyHeader \(index + 1)")
              .font(.headline)
          }
        }
        .padding()
        .border(Color.red)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.yellow)
        .background(
          Color.green
            .padding(.top, -context.topMargin)
        )
      }

    }

    VStack(spacing: 0) {
      HStack(spacing: 16) {
        Button("Small (1)") {
          itemCount = 1
        }
        .buttonStyle(.borderedProminent)

        Button("Medium (3)") {
          itemCount = 3
        }
        .buttonStyle(.borderedProminent)

        Button("Large (5)") {
          itemCount = 5
        }
        .buttonStyle(.borderedProminent)
      }
      .padding()
      .background(Color.white)

      ForEach(0..<100, id: \.self) { index in
        Text("Content \(index + 1)")
          .frame(maxWidth: .infinity)
          .padding()
      }
    }
  }
}

