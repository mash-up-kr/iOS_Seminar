//
//  ListBuildable.swift
//  swiftui-architecture-example
//
//  Created by kimchansoo on 6/23/24.
//

//protocol ListInteractable: AnyObject {
//    var router: ListRouting? { get set }
//    var listener: ListListener? { get set }
//}
//
//final class ListRouter: ListRouting {
//    
//    
//    
//    func showDetail(title: String) {
//    }
//}

import UIKit

final class ListRouter: Router {
    
    
    var delegate: (any RouterDelegate)?
    
    var navigationController: UINavigationController
    
    var childRouters: [any Router] = []
    
    init(_ navigationController: UINavigationController) {
        navigationController.isNavigationBarHidden = true
        self.navigationController = navigationController
    }
    
    func start() {
        self.pushView(ListView(viewModel: ListTempViewModel(router: self)))
    }
}

extension ListRouter: ListRouting {
    func showDetail(title: String) {
        print("\(#function)")
        let detailRouter = DetailRouter(navigationController, title: title)
        self.childRouters.append(detailRouter)
        detailRouter.start()
    }
}
