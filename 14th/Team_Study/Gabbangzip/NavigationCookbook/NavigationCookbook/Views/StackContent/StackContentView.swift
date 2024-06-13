//
//  StackContentView.swift
//  NavigationCookbook
//
//  Created by Hyun A Song on 6/8/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct StackContentView: View {
  var store: StoreOf<StackContentFeature>
  
  var body: some View {
    List(Category.allCases) { category in
      Section {
				ForEach(getRecipes(recipes: store.recipes, for: category)) { recipe in
          Button(
            recipe.name
          ) {
            store.send(.delegate(.recipeSelected(recipe)))
          }
          .tint(.black)
        }
      } header: {
        Text(category.localizedName)
      }
    }
    .navigationTitle("Categories")
  }
  /* NavigationLink ver.
     var body: some View {
       List(Category.allCases) { category in
         Section {
           ForEach(getRecipes(recipes: store.recipes, for: category)) { recipe in
             NavigationLink(recipe.name, state: NavigationFeature.Path.State.recipeDetail(.init(recipe: recipe)))
           }
         } header: {
           Text(category.localizedName)
         }
       }
       .navigationTitle("Categories")
     }
   */
	
	func getRecipes(recipes: [Recipe], for category: Category) -> [Recipe] {
		recipes
			.filter { $0.category == category }
			.sorted { $0.name < $1.name }
	}
}

#Preview {
  StackContentView(store: Store(initialState: StackContentFeature.State(), reducer: {
    StackContentFeature()
  }))
}
