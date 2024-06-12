//
//  AddFeature.swift
//  Counter
//
//  Created by 김영균 on 6/11/24.
//

import ComposableArchitecture
import SwiftUI

// MARK: - Reducer
@Reducer
struct AddFeature {
	@ObservableState
	struct State: Equatable {
		var count: Int
		
		init(count: Int) {
			self.count = count
		}
	}
	
	enum Action {
		case incrementButtonTapped
	}
	
	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .incrementButtonTapped:
				state.count += 1
				return .none
			}
		}
	}
}


// MARK: - View
struct AddView: View {
	let store: StoreOf<AddFeature>
	
	var body: some View {
		VStack {
			Text("\(store.count)")
				.bold()
			
			Button("increment") { store.send(.incrementButtonTapped) }
		}
		.padding()
		.border(Color.red)
	}
}
