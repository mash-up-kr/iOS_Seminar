# TCA 1.0 스터디 (MultiStore)
# 챕터 자료
- https://axiomatic-fuschia-666.notion.site/Chapter-7-MultiStore-1e8734581d104073b9d0ec3697f5ee1d?pvs=25
***
#  스터디 내용
- ### MultiStore
  - 지금까지의 학습을 통해 Reducer로 Store를 생성하고 View에 연결하는 방법에 대해 모두 익혔지만, 이는 다소 간단한 규모의 프로젝트 예시로만 사용되었을 수 있음
  - 더 나아가 큰 규모의 앱이라면 하나의 Reducer로만 관리하기에 벅차기에, 잘게 요구에 맞게 쪼개 사용하는것이 이번 학습의 핵심
  - 즉, 이번 챕터에서 배울 MultiStore를 통해 그것을 가능케함
  - MultiStore에선 대표적으로 아래 장점 및 특징들을 가짐
    - 자식 State가 옵셔널로 없을 시에도 UI에 적절히 처리하는 등 특정한 케이스에서 자식 뷰의 렌더링을 할 수 있음
    - Reducer를 잘게 나눠 각각 독립적으로 동작 및 관리 가능
    - 작게 나눈 Store를 통해 특정 부분만의 업데이트를 가져가 성능 최적화
***
- ### ifLet
  - 부모 State의 옵셔널 프로퍼티에서 동작하는 자식 리듀서를 부모의 도메인으로 넣을 수 있게함
  ```swift
  struct Parent: Reducer {
    struct State {
      var child: Child.State?
    }
    
    enum Action {
      case child(Child.Action)
    }
    
    var body: some Reducer<State, Action> {
      Reduce { state, action in 
        ...
      }
      .ifLet(\.child, action: /Action.child) {
        Child()
      }
    }
  }
  ```
  - 위와 같이 자식 State가 옵셔널일 시 부모 리듀서에 ifLet을 붙여주면서 키패스와 케이스패스로 지정하여 자식 리듀서를 가져올 수 있음
  - 즉, 자식 State가 옵셔널이 아니게 되는 값이 부여될때 자식 Reducer를 실행해줌
***
- ### ifLet 생성자
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
					Wrapped: Reducer
  ```
  - toWrappedState는 부모 State에서 옵셔널한 자식 State를 포함하게하는 키패스
  - toWrappedAction은 부모 Action에서 자식 Action을 포함하게 하는 케이스패스
  - wrapped는 자식 State가 옵셔널이 아닐 시 자식 Action과 함께 호출될 리듀서
  - 반환 타입에서 where절을 해석해보면 WrappedState가 자식의 State고, WrappedAction도 자식의 액션이고 자식 리듀서 자체는 리듀서 프로토콜을 따르고 있다면 부모 리듀서와 자식 리듀서를 조합하여 새로운 리듀서를 반환한다는 뜻!
  - ifLet은 아래와 같은 작업을 수행
    - 자식과 부모 기능에서 특정 작업 순서를 강제함 (자식 액션 > 부모 액션 실행 순)
    - 자식 State가 nil이 되면 모든 자식의 이펙트를 자동으로 취소
    - 얼럿이나 컨펌과 같은 창에서 액션이 전송되면 자동으로 자식을 nil로 무효화 처리함
***
- ### ifLetStore
  - ifLet을 통해 옵셔널한 자식 리듀서를 부모 리듀서에 끌어왔으니 이제는 뷰에 보여줄 차례
  - 자식 State가 있을때 자식 뷰 혹은 특정한 뷰를 보여주고 없다면 대체 뷰를 보여줄때 사용
  ```swift
  IfLetStore(store.scope(state: \.child, action: Child.Action.blabla)) {
    ChildView(store.$0)
  } else: {
    Text("자식 State nil")
  }
  ```
  - 이런식으로 자식 State 값을 스코프로 가져와 상태에 넣고 수행할 특정 액션도 넣고 else 구문에선 자식 State가 nil일 시 대체할 뷰를 제공
***
- ### ifLetStore 생성자
  ```swift
  public struct IfLetStore<State, Action, Content: View>: View {
  private let content: (ViewStore<State?, Action>) -> Content
  private let store: Store<State?, Action>
  ...
  }
  ```
  - State는 옵셔널한 자식 State
  - Action은 자식 액션
  - Content는 뷰
  ```swift
  public init<IfContent, ElseContent>(
    _ store: Store<State?, Action>,
    @ViewBuilder 
		then ifContent: @escaping (_ store: Store<State, Action>) -> IfContent,
    @ViewBuilder 
		else elseContent: () -> ElseContent
  ) where Content == _ConditionalContent<IfContent, ElseContent> {
  ```
  - store는 스코프한 자식 State와 Action을 넣어 사용
  - then은 자식 State가 존재할 시 실행되는 클로저로 뷰빌더를 채택하기에 뷰를 구성
  - else에서는 자식 State가 없을 시 보여줄 뷰를 구성
  ```swift
  let store = store.invalidate { $0 == nil }
  self.store = store
  ```
  - 해당 invalidate 함수를 통해서 nil일 때 상태를 무시하는 새 store를 지정할 수 있음
  - 이것이 어떻게 활용되는건지 잘 모르겠음
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
  - 아 위와 같이 사용되는구나!
  - content를 만들때 자식 State가 nil이 아닌지 바인딩을 통해 구성하면서 first로 첫번째로 보여줄 뷰에 대한 스토어는 ifContent를 통해서 만들며 nil을 스토어가 무시해야하기에 invalidate를 쓰는것 같음!
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
  - 결국 이렇게 body 프로퍼티를 구성할때 WithViewStore로 스토어를 지정해줘야하는데 위에서 이미 자식 State의 nil여부에 따라 store를 구성했기에 넣어주면 가능한듯
  - 이렇게 WithViewStore를 지정해준다면 옵셔널 여부에 따라 중복 제거도 되고 그런듯
  - 1.7에서 이마저도 Deprecated되어서 이제 아래처럼 사용해야함
  ```swift
  if let childStore = store.scope(state: \.child, action: \.child) {
  ChildView(store: childStore)
  } else {
  Text("Nothing to show")
  }
  ```
***
- ### forEach
  - 부모 도메인에 부모 State의 컬렉션 요소에서 작동하는 자식 리듀서를 포함하는 기능
  - 즉, 자식 State가 어레이 같은 타입일 때 forEach를 통해서 부모 로직과 자식 로직을 수행할 수 있도록 함
  ```swift
  struct Parent: Reducer {
    struct State {
      var rows: IdentifiedArrayOf<Child.State>
    }
    
    enum Action {
      case row(id: Child.State.ID, action: Child.Action)
    }
    
    var body: some Reducer<State, Action> {
      Reduce { state, action in 
        ...
      }
      .forEach(\.rows, action: /Action.row) {
        Row()
      }
    }
  }
  ```
  - ID로 안전하게 접근하도록하며 컬렉션 라이브러리의 IdentifiedArray를 사용함
  - forEach도 자식 및 부모 기능에 대해서 작업 순서를 강제화함 (자식 > 부모 순)
***
- ### forEach 생성자
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
  - toElementState는 부모 State로부터 자식 State의 식별된 배열에 대한 키패스
  - toElementAction은 자식 액션의 케이스 패스
  - element는 자식 리듀서
  - 반환값으로는 where절을 만족시키면 자식 리듀서와 부모 리듀서를 결합한 리듀서를 반환하게됨
***
- ### ForEachStore
  - 배열된 State를 순회하면서 각 항목에 대한 뷰를 생성하는데 사용됨
  - 동적으로 UI 생성하며 배열 요소를 기반으로 뷰를 표시함
  ```swift
  ForEachStore(
    self.store.scope(state: \.rows, action: { .row(id: $0, action: $1) })
  ) { childState in 
    ChildView(store: childStore)
  }
  ```
***
- ### ForEachStore 생성자
  ```swift
  public struct ForEachStore<
  EachState, EachAction, Data: Collection, ID: Hashable, Content: View>: DynamicViewContent {
  public let data: Data
  let content: Content
  ```
  - EachState와 EachAction은 각 요소의 State, Action을 나타냄
  - Data는 순회하는 데이터 컬렉션이며 ID는 데이터 요소의 고유 식별자
  - Content는 각 요소에 대한 뷰를 생성하는 클로저 형식
  ```swift
  public init<EachContent>(
    _ store: Store<IdentifiedArray<ID, EachState>, (ID, EachAction)>,
    @ViewBuilder 
		content: @escaping (_ store: Store<EachState, EachAction>) -> EachContent
  )
  ```
  - 초기화 메서드에서 store는 위 사용부처럼 자식 상태와 액션으로 스코핑된 store로 넣음
  - content는 각 요소에 대한 뷰를 반환하도록 함
  - 사실 이후 내부 구현들을 더 자세히 알아봐도 되지만 1.7에서 Deprecated됨ㅎ... 그래서 스킵합니다~
  - 이젠 아래처럼 사용해야함!
  ```swift
  ForEach(
    store.scope(state: \.rows, action: \.rows),
    id: \.state.id
  ) { childStore in
    ChildView(store: childStore)
  }
  ```
  - 사용 시 각 행의 상태 ID에 의존하지 않는 경우에는 ID 매개 변수도 생략 가능
***
- ### ifCaseLet
- 부모 State가 enum 타입이고 각 여러 자식 State들을 가질 때, 특정 케이스에 대해 자식 리듀서를 실행하도록 함
- 즉, 기존에는 State는 Struct였지만, 부모 State를 enum으로 가져가면서 여러 자식에 대해 포함할 수 있음
  ```swift
  struct Parent: Reducer {
    enum State {
      case firstChild(FirstChild.State)
      case secondChild(SecondChild.State)
    }
  
    enum Action {
      case firstChild(FirstChild.Action)
      case secondChild(SecondChild.Action)
    }
  
    var body: some Reducer<State, Action> {
      Reduce { state, action in 
        ...
      }
      .ifCaseLet(/State.firstChild, action: /Action.firstChild) {
        FirstChild()
      }
      .ifCaseLet(/State.secondChild, action: /Action.secondChild) {
        SecondChild()
      }
    }
  }
  ```
  - 이렇게 부모 상태에서 선택된 자식 상태 및 액션에 따라 해당 리듀서가 결합되어 사용될 수 있음
  - 마찬가지로 자식 및 부모 기능에 대해 특정 작업 순서를 강제화함 (자식 > 부모)
  - 다른 자식 열거 값으로 변경이 되면 모든 기존 이펙트가 취소됨
***
- ### ifCaseLet 생성자
  ```swift
  @warn_unqualified_access func ifCaseLet<CaseState, CaseAction, Case>(
    _ toCaseState: CasePath<Self.State, CaseState>,
    action toCaseAction: CasePath<Self.Action, CaseAction>, @ReducerBuilder<CaseState, CaseAction> then case: () -> Case,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> _IfCaseLetReducer<Self, Case> 
		where CaseState == Case.State, CaseAction == Case.Action, Case : Reducer
  ```
  - toCaseState는 자식 State를 지정하는 케이스패스
  - toCaseAction은 자식 Action을 지정하는 케이스패스
  - Case는 자식 리듀서
  - 반환 타입으로 부모와 자식 리듀서가 결합된 리듀서를 반환
***
- ### SwitchStore
  - ifCaseLet하고 짝꿍이라고 보면됨
  - 리듀서를 조합한걸 이제 뷰에서 스토어를 통해 갈아끼워줄 수 있음
  - enum 타입의 State를 관찰하면서 해당 각 케이스에 대해 CaseLet으로 전환해줌
  ```swift
  struct ParentView: View {
  let store: StoreOf<Parent>
  
  init(store: StoreOf<Parent>) {
    self.store = store
  }
  
  var body: some View {
    SwitchStore(self.store) { state in 
      switch State {
      case .firstChild:
        CaseLet(/Parent.State.firstChild, action: Parent.Action.firstChild) { store in 
          FirstChildState(store: store)
        }
      case .secondChild:
        CaseLet(/Parent.State.secondChild, action: Parent.Action.secondChild) { store in
          SecondChildState(store: store)
        }
      }
    }
  }
  ```
  - 이처럼 사용될 수 있음
  - CaseLet은 enum의 특정 case 상태를 처리하고 그에 따라 맞는 뷰를 생성하는데 사용됨
  - 즉, SwitchStore의 상태가 특정 케이스에 일치할때만 해당 State에 대한 처리를 수행
  - 이제 SwitchStore도 사실 1.7에서 Deprecated되어서 생성자나 그런것을 알아보기 보다 이제 어떻게 쓰이는지 한번 보자!
  ```swift
  switch store.state {
  case .activity:
    if let store = store.scope(state: \.activity, action: \.activity) {
      ActivityView(store: store)
    }
  case .settings:
    if let store = store.scope(state: \.settings, action: \.settings) {
      SettingsView(store: store)
    }
  }
  ```
  - 이처럼 좀 더 바닐라스럽게 변하면서 간단해짐!
***
- # 소감
  - 뭔가 이제 Store 붙은 기존의 기능들을 제거하면서 점차 더 바닐라스럽게 변화하면서 간소화되는 느낌이 큼