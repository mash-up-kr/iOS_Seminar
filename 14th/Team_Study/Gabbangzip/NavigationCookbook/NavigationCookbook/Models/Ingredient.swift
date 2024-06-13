/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 A data model for an ingredient for a given recipe.
 */

import SwiftUI

struct Ingredient: Hashable, Identifiable {
	let id = UUID()
	var description: String
}
