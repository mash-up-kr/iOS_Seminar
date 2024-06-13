/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 A data model for a recipe and its metadata, including its related recipes.
 */

import SwiftUI

struct Recipe: Hashable, Identifiable {
	let id = UUID()
	var name: String
	var category: Category
	var ingredients: [Ingredient]
	var related: [Recipe.ID] = []
	var imageName: String? = nil
	var imageURLString: String? = nil
	
	mutating func setImageURLString(_ imageURLString: String) {
		self.imageURLString = imageURLString
	}
}

extension Recipe {
	static var mock: Recipe {
    BuiltInRecipes.examples.first!
	}
}
