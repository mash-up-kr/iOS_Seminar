//
//  Interactor.swift
//  swiftui-architecture-example
//
//  Created by kimchansoo on 6/23/24.
//

import Foundation

open class Interactor<DataHavable: ObservableObject> {

    public weak var dataModel: DataHavable?

    public init(dataModel: DataHavable) {
        self.dataModel = dataModel
    }
}
