//
//  RecipeDetailView.swift
//  NavigationCookbook
//
//  Created by Hyun A Song on 6/8/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct RecipeDetailView: View {
  var store: StoreOf<RecipeDetailFeature>

  var body: some View {
    ScrollView {
      ViewThatFits(in: .horizontal) {
        wideDetails
        narrowDetails
      }
      .padding()
    }
    .navigationTitle(store.recipe.name)
    .onAppear {
      store.send(.onAppear)
    }
    .sheet(store: self.store.scope(state: \.$destination, action: \.destination), state: /RecipeDetailFeature.Destination.State.relatedRecipe, action: RecipeDetailFeature.Destination.Action.showRelatedRecipe) { store in
      NavigationStack {
        RecipeDetailView(store: store)
      }
    }
    .alert(
      store: self.store.scope(state: \.$destination, action: \.destination),
      state: /RecipeDetailFeature.Destination.State.alert,
      action: RecipeDetailFeature.Destination.Action.alert
    )
  }
  
  private var wideDetails: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        image
        ingredients
        Spacer()
      }
			relatedRecipes
    }
  }
  
  private var narrowDetails: some View {
		VStack(alignment: .center) {
			image
			ingredients
			relatedRecipes
		}
  }
  
  private var image: some View {
		RecipePhoto(imageURLString: store.recipe.imageURLString)
			.frame(width: 300, height: 300)
	}
  
  private var ingredients: some View {
		VStack(alignment: .leading) {
			Text("Ingredients")
				.font(.headline)
				.padding(EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0))
			VStack(alignment: .leading) {
				ForEach(store.recipe.ingredients) { ingredient in
					Text(ingredient.description)
				}
			}
		}
		.frame(minWidth: 300, alignment: .leading)
  }
  
  @ViewBuilder
  var relatedRecipes: some View {
		if !store.recipe.related.isEmpty {
      VStack(alignment: .leading) {
        Text("Related Recipes")
          .font(.headline)
          .padding(EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0))
				
        LazyVGrid(columns: columns, alignment: .leading) {
					ForEach(store.relatedRecipes) { relatedRecipe in
						Button(
							action: { store.send(.recipeTileTapped(relatedRecipe)) },
							label: {
								RecipeTile(name: relatedRecipe.name, imageURLString: relatedRecipe.imageURLString)
							}
						)
					}
        }
      }
    } else {
      EmptyView()
    }
  }
  
  private var columns: [GridItem] {
    [ GridItem(.adaptive(minimum: 120, maximum: 120)) ]
  }
}

// MARK: - Preview
#Preview {
  return Group {
		RecipeDetailView(store: Store(initialState: RecipeDetailFeature.State(recipe: .mock), reducer: {
      RecipeDetailFeature()
    }))
  }
}
