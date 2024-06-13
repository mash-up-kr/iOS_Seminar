//
//  NavigationView.swift
//  NavigationCookbook
//
//  Created by Hyun A Song on 6/8/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct NavigationView: View {
  @Bindable var store: StoreOf<NavigationFeature>
  
  var body: some View {
		NavigationStack(
			path: $store.scope(state: \.path, action: \.path),
			root: {
				StackContentView(store: store.scope(state: \.stackContent, action: \.stackContent))
			},
			destination: { store in
				switch store.state {
				case .recipeDetail:
					if let store = store.scope(state: \.recipeDetail, action: \.recipeDetail) {
						RecipeDetailView(store: store)
					}
				}
			}
		)
	}
}

#Preview {
  NavigationView(store: Store(initialState: NavigationFeature.State(), reducer: {
    NavigationFeature()
  }))
}
