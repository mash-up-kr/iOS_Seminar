//
//  swiftui_architecture_exampleApp.swift
//  swiftui-architecture-example
//
//  Created by kimchansoo on 6/23/24.
//

import SwiftUI
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
        
    var window: UIWindow?
    let navi = UINavigationController()
    var router: Router?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navi
        router = ListRouter(navi)
        router?.start()
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }
}
