import SwiftUI
@testable import SelectableForEach

private struct _Cell: View {
  @Environment(\.collectionView_updateSelection) var update

  var body: some View {
    let _ = Self._printChanges()
    Text("Cell")
  }
}

#Preview {

  ScrollView {
    LazyVStack {
      ForEach(
        Item.mock(1000)
      ) { item in
        Control {
          print("hit")
        } content: {
          _Cell()
            .environment(\.collectionView_updateSelection,.init(handler: { _ in
              print("Update")
            }))
        }
      }
    }
  }

}
