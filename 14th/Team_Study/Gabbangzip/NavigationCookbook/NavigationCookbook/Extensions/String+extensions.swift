//
//  String+extensions.swift
//  NavigationCookbook
//
//  Created by Hyun A Song on 6/8/24.
//  Copyright © 2024 Apple. All rights reserved.
//

extension String {
  var ingredients: [Ingredient] {
    split(separator: "\n", omittingEmptySubsequences: true)
      .map { Ingredient(description: String($0)) }
  }
}
