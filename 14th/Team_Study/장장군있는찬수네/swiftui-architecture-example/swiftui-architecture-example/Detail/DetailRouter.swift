//
//  DetailRouter.swift
//  swiftui-architecture-example
//
//  Created by kimchansoo on 6/25/24.
//

import UIKit

final class DetailRouter: Router {
    
    var delegate: (any RouterDelegate)?
    
    var navigationController: UINavigationController
    
    var childRouters: [any Router] = []
    let title: String
    
    init(_ navigationController: UINavigationController, title: String) {
        navigationController.isNavigationBarHidden = true
        self.title = title
        self.navigationController = navigationController
    }
    
    func start() {
        self.pushView(DetailView(title: title))
    }
}
