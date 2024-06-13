//
//  SubtractFeature.swift
//  Counter
//
//  Created by 김영균 on 6/12/24.
//

import ComposableArchitecture
import SwiftUI

// MARK: - Reducer
@Reducer
struct SubtractFeature {
	@ObservableState
	struct State: Equatable {
		var count: Int
		
		init(count: Int) {
			self.count = count
		}
	}
	
	enum Action {
		case decrementButtonTapped
	}
	
	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .decrementButtonTapped:
				state.count -= 1
				return .none
			}
		}
	}
}


// MARK: - View
struct SubtractView: View {
	let store: StoreOf<SubtractFeature>
	
	var body: some View {
		VStack {
			Text("\(store.count)")
				.bold()
			
			Button("decrement") { store.send(.decrementButtonTapped) }
		}
		.padding()
		.border(Color.blue)
	}
}
