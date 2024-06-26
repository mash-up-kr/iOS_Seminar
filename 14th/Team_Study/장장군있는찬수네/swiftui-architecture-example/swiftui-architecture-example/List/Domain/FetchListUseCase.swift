//
//  FetchListUseCase.swift
//  swiftui-architecture-example
//
//  Created by kimchansoo on 6/23/24.
//

import Foundation
import Dependencies

protocol FetchListUseCase {
    func execute() -> [String]
}

final class FetchListUsecaseImpl: FetchListUseCase {

    // MARK: - Properties
    
    // MARK: - Initializers
    
    // MARK: - Methods
    
    func execute() -> [String] {
        return ["titlea", "titleB", "titlec"]
    }
}

final class FetchListUsecaseStub: FetchListUseCase {

    // MARK: - Properties
    
    // MARK: - Initializers
    
    // MARK: - Methods
    
    func execute() -> [String] {
        return ["titleaaaaaaaaaaa", "titleaaaaaaaaaB", "titlaaaaaaaec"]
    }
}


enum FetchListUseCaseKey: DependencyKey, TestDependencyKey {
    static let liveValue: any FetchListUseCase = FetchListUsecaseImpl()
    static let testValue: any FetchListUseCase = FetchListUsecaseStub()
    static let previewValue: any FetchListUseCase = FetchListUsecaseStub()
}


