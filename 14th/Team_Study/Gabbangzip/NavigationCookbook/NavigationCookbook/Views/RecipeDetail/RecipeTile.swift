/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 A recipe tile, displaying the recipe's photo and name.
 */

import SwiftUI

struct RecipeTile: View {
	var name: String
  var imageURLString: String?
	
	var body: some View {
		VStack {
      RecipePhoto(imageURLString: imageURLString)
				.frame(maxWidth: 100, maxHeight: 100)
				.aspectRatio(contentMode: .fill)
			Text(name)
				.lineLimit(2, reservesSpace: true)
				.font(.headline)
		}
		.tint(.primary)
	}
}

struct RecipeTile_Previews: PreviewProvider {
	static var previews: some View {
    RecipeTile(name: "ApplePie", imageURLString: nil)
	}
}
