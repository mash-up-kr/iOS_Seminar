# Chap2 TCA의 기본개념

> `@Published` 속성들에 대한 엄격한 캡슐화를 지향하는 사람들도 있으나, 이에 대한 일관적인 가이드라인은 없었습니다. 즉, 팀과의 협업 중 코드 작성 시에 유의하지 않는다면, 나중에 언제 어디서 상태가 바뀌는지 알기 파악하기 어려운 문제를 야기합니다.
이와 달리 TCA는 상태 변화에 대한 일관적인 가이드라인을 컴파일 단계에서부터 확보합니다. 어떤 개발자든 TCA를 적용한다면 상태 변화를 일으키는 `Action` 정의, `Action`에 대한 `View`에서의 `.send()` 를 거쳐야 하는 것이죠
> 

## Reducer와 View연결

```swift
public init<State, Action>(
    _ store: Store<State, Action>,
    observe toViewState: @escaping (_ state: State) -> ViewState,
    send fromViewAction: @escaping (_ viewAction: ViewAction) -> Action,
    @ViewBuilder content: @escaping (_ viewStore: ViewStore<ViewState, ViewAction>) -> Content,
    file: StaticString = #fileID,
    line: UInt = #line
  ) {
/*
enum Action {
  case a
  case b
  case other(OtherAction)
}
*/
// WithViewStore(store, observe: { $0 }, send: { .other($0) }) { viewStore in }

public init<State>(
    _ store: Store<State, ViewAction>,
    observe toViewState: @escaping (_ state: State) -> ViewState,
    @ViewBuilder content: @escaping (_ viewStore: ViewStore<ViewState, ViewAction>) -> Content,
    file: StaticString = #fileID,
    line: UInt = #line
  ) {
```

observe: 관찰할 State의 범위 지정(하위뷰, 컴포지셔널 뷰)

send: 사용할 Action 지정

send방식 검색중 발견한 블로그

[Swift Composable Architecture 를 도입하며 겪었던 문제와 해결법](https://channel.io/ko/blog/swift_composable_architecture)

## Reducer

```swift
// Reducer
struct Feature: Reducer {
    struct State: Equatable {
				var count = 0
    }
    
    enum Action: Equatable {
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
//    위 body 클로저나 아래 reduce 함수 둘 중 한 가지 방법으로 구현.
//    func reduce(into state: inout State, action: Action) -> Effect<Action> {
//        switch action {
//        case .decrementButtonTapped:
//            state.count -= 1
//            return .none
//        }
//    }

}
```

### body 방식

- 더 **고수준**적인 방법으로, ****`body` 속성 내에서 직접 상태 변경 또는 효과 로직을 수행하지 않고, 여러 다른 리듀서를 조합하는 방식으로 주로 사용됩니다
- 앱의 복잡도가 증가했을 때 더욱 이점

### function 방식

- 다른 리듀서와의 결합이 필요 없는 경우에 추천되는 방법입니다.