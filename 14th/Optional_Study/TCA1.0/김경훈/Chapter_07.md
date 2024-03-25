# Part 7

앱이 복잡해지고 커지면 하나의 Reducer로 상태관리를 하기 어려울 수 있다.

이럴때, Reducer를 특정 작업을 수행하도록 작게 분리할 수 있다.

MultiCore의 장점

- 자식 State의 부재를 UI에서 처리할 수 있다.

부모가 자식의 State를 옵셔널로 가지고 있어 자식 State가 없을 때에도 UI에서 적절하게 처리할 수 있다.

- 작게 나눈 자식 Reducer는 독립적으로 작동하고 관리될 수 있다.

Reducer를 작게 분리하는 것이 코드의 모듈성을 높이고 유지보수에 쉽다

- 특정 부분만 업데이트하고 싶을 때 작은 Reducer를 통해 성능 최적화

일부 상태만 업데이트할 때 유용하다

### ifLet

부모 state의 옵셔널 속성에서 작동하는 자식 reducer를 부모의 도메인에 포함한다.

부모의 기능이 자식 state를 옵셔널로 가지고 있는 경우 사용할 수 있다.

예제)

부모가 옵셔널한 자식의 state를 보유하고 있으며, 부모의 reducer에 ifLet을 달아 자식의 Action을 감지하고 있다가 자식의 State가 옵셔널이 아닐 때 자식의 Reducer를 실행한다.

```swift
struct Parent: Reducer {
  struct State {
    var child: Child.State?
       /* code */
  }
  enum Action {
    case child(Child.Action)
       /* code */
  }

  var body: some Reducer<State, Action> {
     Reduce { state, action in
     }
     .ifLet(\.child, action: /Action.child) {
       Child()
     }
  }
}
```

ifLet 살펴보기

```swift
@warn_unqualified_access func ifLet<WrappedState, WrappedAction, Wrapped>(
    _ toWrappedState: WritableKeyPath<Self.State, WrappedState?>,
    action toWrappedAction: CasePath<Self.Action, WrappedAction>, 
    @ReducerBuilder<WrappedState, WrappedAction> 
    then wrapped: () -> Wrapped,
    fileID: StaticString = #fileID,
    line: UInt = #line
) -> _IfLetReducer<Self, Wrapped> 
    where WrappedState == Wrapped.State, 
          WrappedAction == Wrapped.Action, 
          Wrapped : Reducer
```

- `toWrappedState`: 부모의 State 에서 optional 자식 State 를 포함하는 쓰기 가능한 키 경로입니다.
- `toWrappedAction`: 부모 Action에서 자식 Action을 포함하는 케이스 경로입니다.
- `wrapped`: non-optional인 자식 State 에 대해 자식 Action과 함께 호출될 Reducer입니다.

반환값 (_IfLetReducer<Self, Wrapped>)

- where절은 다음과 같이 작동하고 있다.
    1. 래핑된 상태값(WrappedState)이 (Wrapped.State)이면서
    2. 래핑된 액션값(WrappedAction)이 (Wrapped.Action)이고,
    3. 자식 Reducer(Wrapped) 는 Reducer Protocol을 따라야 함
    
    → 3 가지를 만족했을 때 부모 Reducer와 자식 Reducer를 조합한 새로운 Reducer를 반환한다.
    

ifLet 연산자의 작업

- 자식 및 부모 기능에 대해 특정 작업 순서를 강제한다.

자식 먼저 실행하고 부모를 실행하는 것으로 해결할 수 있다.

순서가 바뀌면 부모의 기능이 자식 State를 무효화할 수 있으며 자식 기능은 해당 동작에 반응할 수 없게 되고, 이로 인해 버그가 발생할 수 있다.

- 자식 state가 null out 된 것을 감지하면 모든 자식 효과를 자동으로 취소한다.
- 알림 및 확인 대화 상자에 대한 Action이 전송될 때 자동으로 자식 상태를 무효화한다.

### ifLetStore

2가지 뷰 중 하나를 표시하기 위해 옵셔널 상태의 store를 안전하게 unwrapping 하는 view

기본 상태가 nil이 아닌 경우 클로저는 옵셔널 상태가 아닌 Store로 수행된다

반대로 nil이면 else 클로저가 실행된다. 옵셔널에 따라 다른 2가지 뷰를 보여줄 수 있다.

```swift
IfLetStore(store.scope(state: \.results, action: Child.Action.results)) {
 SearchResultsView(store: $0)
} else: {
 Text("검색 결과 로딩 중...")
}

```

옵셔널이 아니면 SearchResultsView를 보여주고 옵셔널이면 Text를 보여주는 형식

IfLetStore 생성자

```swift
public struct IfLetStore<State, Action, Content: View>: View {
  private let content: (ViewStore<State?, Action>) -> Content
  private let store: Store<State?, Action>
...
}
```

- State: optional State 를 나타내는 형식입니다.
- Action: 액션을 나타내는 형식입니다.
- Content: 뷰를 생성하는 클로저를 나타내는 형식입니다.

```swift
public init<IfContent, ElseContent>(
    _ store: Store<State?, Action>,
    @ViewBuilder 
    then ifContent: @escaping (_ store: Store<State, Action>) -> IfContent,
    @ViewBuilder 
    else elseContent: () -> ElseContent
) where Content == _ConditionalContent<IfContent, ElseContent> {
```

- store: 옵셔널 상태를 가지는 Store입니다.
- then: 상태가 nil이 아닐 때 실행되는 클로저입니다.
- else: 상태가 nil일 때 실행되는 클로저입니다.

```swift
let store = store.invalidate { $0 == nil }
self.store = store
```

invalidate 함수를 통해 nil일때의 상태를 무시할 수 있는 새로운 store를 저장한다.

그리고 store에 할당해준다. 이로써 store는 앞으로 nil을 무시한다.

```swift
self.content = { viewStore in
      if var state = viewStore.state {
        return ViewBuilder.buildEither(
          first: ifContent(
            store
              .invalidate { $0 == nil }
              .scope(
                state: {
                  state = $0 ?? state
                  return state
                },
                action: { $0 }
              )
          )
        )
      } else {
        return ViewBuilder.buildEither(second: elseContent)
      }
}
```

if var state를 통해 옵셔널을 제거해주고 있고, nil이 아니면 아래의 ifContent를 보여준다.

nil이라면 else로 빠지게 된다.

```swift
public var body: some View {
    WithViewStore(
      self.store,
      observe: { $0 },
      removeDuplicates: { ($0 != nil) == ($1 != nil) },
      content: self.content
    )
  }
}
```

removeDeuplicates 클로저를 사용하여 State의 optional 여부에 따라 중복 제거를 수행할 수 있다.

### forEach

부모 도메인에 부모 State의 컬렉션 요소에 작동하는 자식 Reducer를 포함한다.

forEach는 부모 기능이 자식 State의 배열을 보유하는 경우 forEach 연산자를 사용하여 핵심 로직과 자식 로직을 수행할 수 있다.

부모가 자식의 State를 배열로 가지고 있는 예시

```swift
struct Parent: Reducer {
  struct State {
    var rows: IdentifiedArrayOf<Child.State>
    // ...
  }
  enum Action {
    case row(id: Child.State.ID, action: Child.Action)
    // ...
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
    }
    .forEach(\.rows, action: /Action.row) {
      Row()
    }
  }
}
```

안정적인 ID로 요소에 접근할 수 있도록 identifiedArray를 사용하고 있다.

forEach도 ifLet 연산자와 동일하게 자식 및 부모 기능에 대해 특정 작업 순서를 강제한다. 자식을 먼저 실행한 다음 부모를 실행한다. 순서가 뒤바뀌면 부모 기능이 배열에서 자식의 State를 제거할 수 있으며, 이 경우 자식 기능은 해당 동작에 반응할 수 없다. 이로 인해 버그가 발생할 수도 있다.

forEach 생성자

```swift
@warn_unqualified_access func forEach<ElementState, ElementAction, ID, Element>(
    _ toElementsState: 
      WritableKeyPath<Self.State, IdentifiedArray<ID, ElementState>>,
    action toElementAction: CasePath<Self.Action, (ID, ElementAction)>, 
    @ReducerBuilder<ElementState, ElementAction> element: () -> Element,
    fileID: StaticString = #fileID,
    line: UInt = #line
) -> _ForEachReducer<Self, ID, Element> 
    where ElementState == Element.State, 
    ElementAction == Element.Action, 
    ID : Hashable, Element : Reducer
```

매개변수

- toElementsState: 부모 State로부터 자식 상태의 식별된 배열에 대한 쓰기 가능한 키 경로다
- toElementAction: 부모 Action에서 자식 식별자 및 자식 액션으로의 케이스 경로다
- element: 자식 State의 엘리먼트에 대해 자식 Action과 함께 호출될 Reducer다

반환 값

1. ElementState가 Element.State와 동일해야 함
2. ElementAction이 Element.Action이어야 함
3. ID값이 Hashable Protocol을 따라야 함
4. Element가 Reducer Protocol을 따라야 함
- 1,2,3,4를 지켰다면 자식 Reducer와 부모 Reducer를 결합한 Reducer를 반환합니다.

### ForEachStore

상태의 배열 또는 컬렉션을 순회하고, 각 항목에 대한 뷰를 생성하는데 사용할 수 있다.

즉, 동적으로 UI를 생성하고 배열의 요소를 기반으로 사용자 인터페이스를 표시하거나 업데이트할 수 있다.

```swift
ForEachStore(
  self.store.scope(state: \.rows, action: { .row(id: $0, action: $1) })
) { childStore in
  ChildView(store: childStore)
}
```

ForEachStore 생성자

```swift
public struct ForEachStore<
  EachState, EachAction, Data: Collection, ID: Hashable, Content: View
>: DynamicViewContent {
  public let data: Data
  let content: Content
```

- EachState: 각 요소의 State를 나타낸다
- EachAction: 각 요소의 Action을 나타낸다
- Data: 순회할 데이터 컬렉션을 나타낸다
- ID: 데이터 요소의 고유 식별자를 나타낸다
- Content: 각 요소에 대한 뷰를 생성하는 클로저를 나타내는 형식이다.

```swift
public init<EachContent>(
    _ store: Store<IdentifiedArray<ID, EachState>, (ID, EachAction)>,
    @ViewBuilder 
    content: @escaping (_ store: Store<EachState, EachAction>) -> EachContent
  )
```

- store: 데이터 컬렉션 및 액션과 관련된 정보를 제공한다. ID를 사용하여 각 요소를 고유하게 식별하고 있다. 즉 IdentifiedArray로 식별되는 각각의 상태와 액션이 고유한 Store를 나타낸다.
- content: 각 요소에 대한 뷰를 생성하는 클로저 → Store<EachState, EachAction>를 인수로 받아 해당 요소에 대한 뷰를 반환한다.

```swift
where
    Data == IdentifiedArray<ID, EachState>,
    Content == WithViewStore<
      IdentifiedArray<ID, EachState>, (ID, EachAction),
      ForEach<IdentifiedArray<ID, EachState>, ID, EachContent>>
```

생성자의 제약조건을 정의하는 where절

- Data는 `IdentifiedArray<ID, EachState>`와 동일해야 한다.

```swift
struct WithViewStore<ViewState, ViewAction, Content> where Content : View
```

Content를 살펴보기 전 WithViewStore는 다음과 같이 생성된다.

1. ViewState에 대응되는 요소는 IdentifiedArray<ID, EachState>다. IdentifiedArray로 식별되는 고유한 State다
2. ViewAction 또한 (ID, EachAction)에 대응된다.
3. View Protocol을 따르는 Content는 ForEach<IdentifiedArray<ID, EachState>, ID, EachContent>에 대응된다. 고유한 식별자로 ForEach를 실행해 EachState, EachContent를 추출할 수 있다.

→ 즉 1,2,3 조건을 만족하는 Content는 WithViewStore 형식이어야 한다.

```swift
self.data = store.state.value
    self.content = WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: { areOrderedSetsDuplicates($0.ids, $1.ids) }
    ) { viewStore in
```

- data 프로퍼티는 저장소의 상태에서 데이터 컬렉선을 가져오게 된다.
- content 프로퍼티는 WitchViewStore 형식으로 설정된다. store를 관찰하고 중복을 제거하는 removeDuplicates와 함께 사용된다.

```swift
ForEach(viewStore.state, id: viewStore.state.id) { element in
  var element = element
  let id = element[keyPath: viewStore.state.id]
  content(
    store.scope(
      state: {
        element = $0[id: id] ?? element
        return element
      },
      action: { (id, $0) }
    )
  )
}
```

ForEach를 사용하여 viewStore.state를 순회한다. 이후 각 요소에 대해 다음 작업을 수행하게 된다.

1. 요소를 수정할 수 있도록 복사한다.
2. ID를 사용하여 고유한 식별자를 가져오게 된다.
3. content 클로저를 호출해 해당 요소에 대한 뷰를 생성한다.
    - store.scope를 사용하여 요소의 상태와 액션을 다루는 데 사용한다.

```swift
public var body: some View {
  self.content
}

```

마지막으로 생성된 content를 반환하게 된다.

### ifCaseLet

부모 열거형 상태의 경우에서 작동하는 자식 Reducer를 부모 도메인에 포함시킨다.

부모 기능의 State가 여러 자식 State의 열거형으로 표현되는 경우, ifCaseLet은 열거형의 특정 케이스에 대해 자식 Reducer를 실행할 수 있다.

```swift
struct Parent: Reducer {
  enum State {
    case loggedIn(Authenticated.State)
    case loggedOut(Unauthenticated.State)
  }
  enum Action {
    case loggedIn(Authenticated.Action)
    case loggedOut(Unauthenticated.Action)
    // ...
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      // Core logic for parent feature
    }
    .ifCaseLet(/State.loggedIn, action: /Action.loggedIn) {
      Authenticated()
    }
    .ifCaseLet(/State.loggedOut, action: /Action.loggedOut) {
      Unauthenticated()
    }
  }
}

```

ifCaseLet도 ifLet, ForEach처럼 자식, 부모 순서 등에 대해서 동일한 특성을 가지고 있다.

ifCaseLet 생성자

```swift
@warn_unqualified_access func ifCaseLet<CaseState, CaseAction, Case>(
    _ toCaseState: CasePath<Self.State, CaseState>,
    action toCaseAction: CasePath<Self.Action, CaseAction>, @ReducerBuilder<CaseState, CaseAction> then case: () -> Case,
    fileID: StaticString = #fileID,
    line: UInt = #line
) -> _IfCaseLetReducer<Self, Case> 
    where CaseState == Case.State, CaseAction == Case.Action, Case : Reducer
```

매개변수

- toCaseState: 부모 State에서 자식 State를 포함하는 케이스로의 케이스 경로다.
- toCaseAction: 부모 Action에서 자식 Action을 포함하는 케이스로의 케이스 경로다.
- case: 자식 Action이 존재할 때 자식 State에 대해 자식 Action과 함께 호출될 Reducer다.

반환값

- 자식 Reducer와 부모 Reducer를 `결합하는 Reducer`를 반환한다.

### SwitchStore

enum 형식의 State를 관찰하고 해당 상태의 각 경우에 대해 CaseLet으로 전환하기 위해 사용한다.

열거형의 State에 대해 로그인 상태, 로그아웃 상태를 관찰하고 이에 알맞는 상태를 CaseLet으로 전환하고 해당되는 컨텐츠가 실행된다.  이렇게 특정 케이스에 대한 뷰를 동적으로 제어할 수 있다. 

다음은 로그아웃과 로그인 상태에 따른 뷰 전환 하는 예제

```swift
public struct AppView: View {
  let store: StoreOf<Parent>

  public init(store: StoreOf<Parent>) {
    self.store = store
  }

  public var body: some View {
    SwitchStore(self.store) { state in
      switch state {
      case .loggedIn:
        CaseLet(/Parent.State.loggedIn, action: Parent.Action.loggedIn) { store in
          NavigationStack { LoginView(store: store) }
        }
      case .loggedOut:
        CaseLet(/Parent.State.loggedOut, action: Parent.Action.loggedOut) { store in
          NavigationStack { LogoutView(store: store) }
        }
      }
    }
  }
}
```

SwitchStore 생성자

```swift
public struct SwitchStore<State, Action, Content: View>: View {
  public let store: Store<State, Action>
  public let content: (State) -> Content

  public init(
    _ store: Store<State, Action>,
    @ViewBuilder content: @escaping (_ initialState: State) -> Content
  ) {
    self.store = store
    self.content = content
  }
```

SwitchStore는 State, Action, Conent에 대한 제네릭 형식으로 정의된다.

- store는 enum상태를 관찰한다.
- content 클로저는 현재 상태를 받아 해당되는 콘텐츠를 생성한다.

```swift
public var body: some View {
    WithViewStore(
      self.store, observe: { $0 }, removeDuplicates: { enumTag($0) == enumTag($1) }
    ) { viewStore in
      self.content(viewStore.state)
        .environmentObject(StoreObservableObject(store: self.store))
    }
  }
}

```

body 프로퍼티에서는 WithViewStore를 사용하여 store를 관찰하고, 상태가 변경될 때 뷰를 업데이트 하게 된다.

- removeDuplicates 클로저는 enum case가 변경될 때만 중복을 제거한다.

```swift
public struct CaseLet<EnumState, EnumAction, CaseState, CaseAction, Content: View>: View {
  public let toCaseState: (EnumState) -> CaseState?
  public let fromCaseAction: (CaseAction) -> EnumAction
  public let content: (Store<CaseState, CaseAction>) -> Content
  // ...
}

```

**SwitchStore와 함께 사용되는 CaseLet**

enum의 특정한 case의 상태를 처리하고 그에 알맞는 뷰를 생성하는데 사용된다.

- toCaseState: Enum 상태에서 특정 case의 상태를 추출하기 위한 클로저다.
- fromCaseAction: case-specific Action을 EnumAction으로 래핑하기 위해 사용된다.
- content: case에 해당하는 상태와 액션을 받아 해당 case에 따른 뷰를 만들어주기 위한 클로저다.

→ SwitchStore의 상태가 특정 case와 일치할 때에만 해당 State에 대한 처리를 수행하게 된다.
