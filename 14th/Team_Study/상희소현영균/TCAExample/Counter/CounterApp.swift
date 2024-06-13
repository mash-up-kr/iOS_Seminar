//
//  CounterApp.swift
//  Counter
//
//  Created by 김영균 on 6/11/24.
//

import SwiftUI
import ComposableArchitecture

@main
struct CounterApp: App {
	let store = Store(initialState: CounterFeature.State()) {
		CounterFeature()
	}
	var body: some Scene {
		WindowGroup {
			CounterView(store: store)
		}
	}
}
