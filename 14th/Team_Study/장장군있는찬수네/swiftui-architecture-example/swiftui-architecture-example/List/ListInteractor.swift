//
//  ListInteractor.swift
//  swiftui-architecture-example
//
//  Created by kimchansoo on 6/23/24.
//

import SwiftUI
import Dependencies

protocol ListRouting: AnyObject {
    func showDetail(title: String)
}

protocol ViewModelType {
    associatedtype Action
    associatedtype State
    
    var state: State { get }
    
    func dispatch(type: Action)
    
}


final class ListTempViewModel: ViewModelType, ObservableObject {

    enum Action {
        case viewOnAppeared
        case detailTapped(title: String)
        case detailAdded(title: String)
    }
    
    struct State {
        var listString: [String] = []
    }
    
    weak var router: ListRouting?
    @Published var state = State()
    
    @Dependency(FetchListUseCaseKey.self) private var fetchListUsecase
    
    init(router: ListRouting?) {
        self.router = router
    }
    
    func dispatch(type: Action) {
        print("\(#function), type: \(type)")
        switch type {
        case .viewOnAppeared:
            state.listString = fetchListUsecase.execute()
        case .detailTapped(let title):
            router?.showDetail(title: title)
        case .detailAdded(let title):
            state.listString.append(title)
            print(state.listString)
        }
        
        
    }
    
}
