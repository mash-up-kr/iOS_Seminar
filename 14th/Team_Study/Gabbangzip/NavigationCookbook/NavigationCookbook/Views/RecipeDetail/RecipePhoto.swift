/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 A photo view for a given recipe, displaying the recipe's image or a placeholder.
 */

import SwiftUI

struct RecipePhoto: View {
  var imageURLString: String?
  
  var body: some View {
    if let imageURLString {
			AsyncImage(
				url: URL(string: imageURLString),
				content: { image in
					image
						.resizable()
						.aspectRatio(contentMode: .fit)
				},
				placeholder: {
					placeholder
				}
			)
    } else {
			placeholder
    }
  }
	
	var placeholder: some View {
		ZStack {
			Rectangle()
				.fill(.tertiary)
			Image(systemName: "camera")
				.font(.system(size: 64))
				.foregroundStyle(.secondary)
		}
	}
}

#Preview {
  RecipePhoto(imageURLString: nil)
}
