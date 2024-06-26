//
//  ListView.swift
//  swiftui-architecture-example
//
//  Created by kimchansoo on 6/23/24.
//

import SwiftUI
import Dependencies

struct ListView: View {
    
    @ObservedObject private var viewModel: ListTempViewModel
    
    init(viewModel: ListTempViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        List {
            ForEach(viewModel.state.listString, id: \.self) { title in
                Button(title) {
                    viewModel.dispatch(type: .detailTapped(title: title))
                }
            }
            Button("더하기") {
                viewModel.dispatch(type: .detailAdded(title: String(Int.random(in: 0...100000))))
            }
        }
        .onAppear(perform: {
            viewModel.dispatch(type: .viewOnAppeared)
        })
    }
}

#Preview {
    ListView(viewModel: ListTempViewModel(router: nil))
}

