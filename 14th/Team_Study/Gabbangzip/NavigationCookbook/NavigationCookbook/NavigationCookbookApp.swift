/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The main app, which creates a scene that contains a window group, displaying
 the root content view.
 */

import SwiftUI
import ComposableArchitecture

@main
struct NavigationCookbookApp: App {
  var body: some Scene {
    WindowGroup {
      let mock = Recipe.mock
      
      NavigationView(
        store: Store(
          initialState: NavigationFeature.State(
            path: StackState([]),
            stackContent: StackContentFeature.State()
          )
        ) {
          NavigationFeature()
        }
      )
    }
  }
}
