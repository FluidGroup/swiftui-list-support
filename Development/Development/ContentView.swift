//
//  ContentView.swift
//  Development
//
//  Created by Muukii on 2023/06/09.
//

import SwiftUI
@testable import DynamicList

struct ContentView: View {
  var body: some View {
    NavigationView {

      List {
        NavigationLink("Chat") {
          MessageListPreviewContainer()
        }
        
        NavigationLink("Variadic") {
          BookVariadicView()
        }

        NavigationLink("UIKit Compositinal") {
          BookUIKitBasedCompositional()
        }

        NavigationLink("UIKit Flow") {
          BookUIKitBasedFlow()
        }

        NavigationLink("UICollectionView Lab") {
          BookPlainCollectionView()
        }
        
        NavigationLink("CollectionView") {
          BookCollectionViewSingleSection()
        }
        
        NavigationLink("ScrollView") {
          OnAdditionalLoading_Previews()
        }
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
