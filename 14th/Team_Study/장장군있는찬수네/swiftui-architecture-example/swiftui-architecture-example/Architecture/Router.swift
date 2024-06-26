//
//  Router.swift
//  swiftui-architecture-example
//
//  Created by kimchansoo on 6/24/24.
//

import UIKit
import SwiftUI

protocol RouterDelegate: AnyObject {
    
    func didFinish(childRouter: Router)
}

protocol Router: AnyObject {
    
    var delegate: RouterDelegate? { get set }
    var navigationController: UINavigationController { get set }
    var childRouters: [Router] { get set }
    
//    init(_ navigationController: UINavigationController)

    func start()
    func finish()
    func popView()
    func dismissView()
}

extension Router {
    
    func finish() {
        childRouters.removeAll()
        delegate?.didFinish(childRouter: self)
    }
    
    func popView() {
        self.navigationController.popViewController(animated: true)
    }
    
    func dismissView() {
        navigationController.dismiss(animated: true)
    }
    
    func pushView<V: View>(_ view: V, animated: Bool = true) {
        let viewController = UIHostingController(rootView: view)
        navigationController.pushViewController(viewController, animated: animated)
    }
    
    func presentModallyView<V: View>(_ view: V, animated: Bool = true) {
        let viewController = UIHostingController(rootView: view)
        viewController.modalPresentationStyle = .formSheet
        navigationController.present(viewController, animated: animated)
    }
    
    func presentFullscreenView<V: View>(_ view: V, animated: Bool = true) {
        let viewController = UIHostingController(rootView: view)
        viewController.modalPresentationStyle = .fullScreen
        navigationController.present(viewController, animated: animated)
    }

}
