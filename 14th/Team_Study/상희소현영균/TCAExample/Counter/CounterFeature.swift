//
//  CounterFeature.swift
//  Counter
//
//  Created by 김영균 on 6/12/24.
//

import ComposableArchitecture
import SwiftUI

// MARK: - Reducer
@Reducer
struct CounterFeature {
	@ObservableState
	struct State: Equatable {
		var add: AddFeature.State
		var subtract: SubtractFeature.State
		var totalCount: Int
		
		init() {
			self.add = AddFeature.State(count: 0)
			self.subtract = SubtractFeature.State(count: 0)
			self.totalCount = 0
		}
	}
	
	enum Action {
		case add(AddFeature.Action)
		case subtract(SubtractFeature.Action)
	}
	
	var body: some ReducerOf<Self> {
		Scope(state: \.add, action: \.add) {
			AddFeature()
		}
		
		Scope(state: \.subtract, action: \.subtract) {
			SubtractFeature()
		}
		
		Reduce { state, action in
			switch action {
			case .add(.incrementButtonTapped):
				state.totalCount += 1
				return .none
				
			case .subtract(.decrementButtonTapped):
				state.totalCount -= 1
				return .none
			}
		}
	}
}

// MARK: - View
struct CounterView: View {
	let store: StoreOf<CounterFeature>
	
	var body: some View {
		HStack {
			Spacer()
			
			AddView(store: store.scope(state: \.add, action: \.add))
			
			Text("+")
			
			SubtractView(store: store.scope(state: \.subtract, action: \.subtract))
			
			Text("=")
			
			TotalCountView(totalCount: store.totalCount)
			
			Spacer()
		}
		
	}
}

struct TotalCountView: View {
	let totalCount: Int
	
	var body: some View {
		Text("\(totalCount)")
			.padding()
			.border(.green)
	}
}
