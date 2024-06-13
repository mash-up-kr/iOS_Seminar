//
//  RecipeDetailTests.swift
//  NavigationCookbookTests
//
//  Created by YangJoonHyeok on 6/9/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
import ComposableArchitecture
@testable import NavigationCookbook

@MainActor
final class RecipeDetailTests: XCTestCase {
	func testRecipeTileTapped() async {
		let store = TestStore(
			initialState: RecipeDetailFeature.State(
				recipe: .mock
			),
			reducer: { RecipeDetailFeature() }
		)
		let recipe = Recipe(name: "Cake", category: .dessert, ingredients: [])
		
		await store.send(.recipeTileTapped(recipe))
    // TODO: 수정 필요 ..
//		await store.receive(\.delegate.moveToRecipeDetail)
	}
	
	func testGetRecipeImageSuccess() async {
		let store = TestStore(
			initialState: RecipeDetailFeature.State(
				recipe: .mock
			),
			reducer: { RecipeDetailFeature() },
			withDependencies: {
				$0.imageSearchClient.getImage = { @Sendable query in
					return ""
				}
			}
		)
		
		store.exhaustivity = .off
		
		await store.send(.onAppear)
		await store.receive(\.getImage.success) {
			$0.recipe.imageURLString = ""
		}
	}
	
	func testGetRecipeImageFailure() async {
		struct ImageSearchError: Equatable, Error {}
		
		let store = TestStore(
			initialState: RecipeDetailFeature.State(
				recipe: .mock
			),
			reducer: { RecipeDetailFeature() },
			withDependencies: {
				$0.imageSearchClient.getImage = { @Sendable _ in
					throw ImageSearchError()
				}
			}
		)
		
		store.exhaustivity = .off
		
		await store.send(.onAppear)
		await store.receive(\.getImage.failure) {
			$0.recipe.imageURLString = nil
		}
	}
}
