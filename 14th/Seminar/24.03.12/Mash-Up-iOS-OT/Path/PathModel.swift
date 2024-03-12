//
//  PathModel.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import Foundation

class PathModel: ObservableObject {
  @Published var paths: [PathType]
  
  init(paths: [PathType] = []) {
    self.paths = paths
  }
}
