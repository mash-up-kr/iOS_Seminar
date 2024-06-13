//
//  StackContentFeature.swift
//  NavigationCookbook
//
//  Created by Hyun A Song on 6/8/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct StackContentFeature: Reducer {
  @ObservableState
  struct State: Equatable {
		var recipes: [Recipe]
		
		init(recipes: [Recipe] = BuiltInRecipes.examples) {
			self.recipes = recipes
		}
  }
  enum Action {
    case showRecipeOfTheDay
    case showCategories
    case recipeButtonDidTap(Recipe)
    case delegate(Delegate)
    
    enum Delegate {
      case recipeSelected(Recipe)
    }
  }
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .showRecipeOfTheDay:
        return .none
      case .showCategories:
        return.none
      case let .recipeButtonDidTap(recipe):
        return .send(.delegate(.recipeSelected(recipe)))
      case .delegate:
        return .none
      }
    }
  }
}
