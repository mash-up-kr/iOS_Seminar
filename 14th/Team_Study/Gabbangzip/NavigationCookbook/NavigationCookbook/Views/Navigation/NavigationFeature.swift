//
//  NavigationFeature.swift
//  NavigationCookbook
//
//  Created by Hyun A Song on 6/8/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct NavigationFeature: Reducer {
	@ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
    var stackContent = StackContentFeature.State()
  }
  enum Action {
    case path(StackAction<Path.State, Path.Action>)
    case stackContent(StackContentFeature.Action)
  }
  
	@Reducer
  struct Path: Reducer {
		@ObservableState
    enum State: Equatable {
      case recipeDetail(RecipeDetailFeature.State)
    }
    enum Action {
      case recipeDetail(RecipeDetailFeature.Action)
    }
    var body: some ReducerOf<Self> {
      Scope(state: /State.recipeDetail, action: /Action.recipeDetail) {
        RecipeDetailFeature()
      }
    }
  }
  
  var body: some ReducerOf<Self> {
    Scope(state: \.stackContent, action: /Action.stackContent) {
      StackContentFeature()
    }
    
    Reduce { state, action in
      switch action {
      case let .stackContent(.delegate(.recipeSelected(recipe))):
        state.path.append(.recipeDetail(.init(recipe: recipe)))
        return .none
      case .path:
        return .none
      case .stackContent:
        return .none
      }
    }
		.forEach(\.path, action: \.path) {
			Path()
		}
  }
}
