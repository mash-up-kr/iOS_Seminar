# TCA 1.0 스터디 (Navigation)
# 챕터 자료
- https://axiomatic-fuschia-666.notion.site/Chapter-8-Navigation-855a4db02ef346e5b6ff8c35c7db3096
***
#  스터디 내용
### Navigation이란?
  - 글에선 SwiftUI의 sheet와 fullscreen covers도 네비게이션으로 볼 수 있다는데, 방식 자체는 해당 두개는 모달 방식이고 흔히 네비게이션 방식은 화면 흐름 자체가 전환되어 넘어가기에 조금 다르지 않나 싶음
  - 해당 자료에서는 팝오버, 얼럿, 다이얼로그 같은 모든것들을 다 네비게이션의 일종이라고 말함
    - 이 부분은 이게 맞다 저게 맞다가 아니라 다양하게 해석될 수 있다고 생각됨 (저는 다르게 생각함)
    - 우선 이 자료의 취지로 이해해보자~
  - 네비게이션은 앱 모드를 변경하는것!
    - 모드 변경은 없는 상태에서 있는 상태가 되거나 그 반대의 경우를 의미함
  - TCA에서 네비게이션은 앱 화면 전환 관리 기능을 의미함
  - State, Action을 사용하여 네비게이션을 처리함
  - 상태 기반 네비게이션에선 트리 기반과 스택 기반으로 구분할 수 있음
***
### 트리 기반 Navigation
  - drill-down Navigation 방식에서 사용되는 코드를 보자!
  ```swift
  struct MainFeature: Reducer {
    struct State {
      @PresentationState var item: ItemFeature.State?
    }
  }
  
  struct ItemFeature: Reducer {
    struct State {
      @PresentationState var alert: AlertSTate<AlertAction>?
    }
  }
  ```
  - 이처럼 파고 들어가는 구조가 충분히 생길 수 있음
  ```swift
  MainView(
    store: Store(
      initialState: MainFeature.State(
        item: ItemFEature.State(
          alert: AlertSTate {
            TextState("Alert!!")
          }
        )
      )
    )
  ) { 
    MainFeature()
  }
  ```
  - 이런식으로 뷰에서 초기화 시 구성할 수 있음
  - 도메인 모델링의 트리 구조를 가짐
  - 상태에 대한 존재 여부를 가지고 옵셔널이나 열거형 타입을 사용하는 경우 이러한 트리 기반 구조
  - 더 자세한것은 아래에서 확인할 예정!
***
### 스택 기반 Navigation
  - 상태 존재 여부를 컬렉션 타입으로 표현하는 방식
  - SwiftUI의 NavigationStack에서 활용되는것과 동일
  - 스택 내 네비게이션 가능한 모든것들을 열거형으로 정의할 수 있음
  ```swift
  enum Path { 
    case item(ItemFeature.State)
    case edit(EditFeature.State)
  }
  
  let path: [Path] = [ 
    .item(ItemFeature.State(item: item)),
    .edit(EditFeature.State(item: item)),
  ]
  ```
  - Path는 스택에 표시되는 기능 모음
  - 이런 형태가 기본적인 스택 기반 네비게이션
  - 더 자세한건 마찬가지로 아래에서!
***
### 트리 기반 VS 스택 기반
  - 대부분은 혼합되어 사용
  - 시트, 팝오버, 얼럿 같은 경우는 모달의 형태이기에 트리 기반 네비게이션을 사용
  - 트리 기반 장/단점
    - 간결한것이 가장 특징
    - 앱에서 가능한 모든 네비게이션 경로를 정적으로 선언하고 유효하지 않은 네비게이션 경로에 대해선 사용하지 않도록 보장될 수 있음
    - 앱에서 지원되는 네비게이션 경로 수를 제한할 수도 있음 (최대 몇개까지 뜰지 등)
    - 모듈화 시 기능 모듈은 트리 기반 네비게이션을 사용해 구축되면 더욱 독립적으로 갈 수 있음
    - 기능 간 밀접한 결합 특성으로 유닛 테스트 작성도 간단
    - 모든 형태의 네비게이션을 간결한 단일 스타일의 API로 통합
    - 복잡하거나 재귀적인 네비게이션 경로에서 사용 시 번거로울 수 있음
    - 트리 기반은 서로 기능들이 결합되기에 컴파일 시간을 늦출 수 있음 (하위까지 모두 빌드해야하기에)
  - 스택 기반 장/단점
    - 재귀적인 네비게이션 경로 처리가 쉬움
    - 스택에 포함된것들은 각 실제로 완전히 다른 화면과 분리될 수 있음
    - 서로 의존성이 없기에 다른 부분을 컴파일 하지 않아도 독립적으로 컴파일이 가능
    - SwiftUI의 NavigationLink 방식인 기존 트리 기반보다 버그가 적어 안정적
    - 비논리적인 네비게이션 경로를 표현할 수 있어 실제로 실수할 수 있음
    ```swift
    let path: [Path] = [
      .edit(),
      .edit(),
      .edit(),
    ]
    ```
    - 앱 모듈화를 통해 분리하여 실행 시 독립적이기에 다른 기능들은 비활성화 상태를 가짐 (전체 앱을 컴파일 하고 실행하지 않는한)
    - 단위 테스트 진행이 어려움 (상호작용을 쉽게 테스트하기가 어려움)
    - drill-down 방식에서만 적용되고 시트, 팝오버, 얼럿등의 모달 형태로 뜨는것에는 대응되지 않음
      - 개인적으로 이건 단점이라기보다 특성이라고 생각됨
***
### 트리 기반 Navigation 톺아보기
  - 옵셔널과 열거형 상태를 사용하여 네비게이션을 모델링하는 방식
  - 깊이 중첩된 상태를 가볍게 구성해 SwiftUI에 전달하여 처리는 SwiftUI가 담당하도록 함
  - 또한, 해당 트리 기반 네비게이션 방식으로 앱의 어떤 상태로든 딥링크를 생성하는 역할을 가질 수 있음
  ```swift
  struct MainFeature: Reducer {
    struct State: Equatable {
      @PresentationState var item: ItemFeature.State?
    }
    
    enum Action: Equatable {
      case addItem(PresentationAction<ItemFeature.Action>)
    }
    
    var body: some ReducerOf<Self> {
      Reduce<State, Action> { state, action in 
        switch action {
        case .addButtonTapped:
          state.addItem = ItemFeature.State()
          return .none
        }
      }
      .ifLEt(\.$addItem, action: /Action.addItem) {
        ItemFeature()
      }
    }
  }
  
  struct MainView: View {
    let store: StoreOf<MainFeature>
    
    var body: some View {
      List {
        ...
      }
      .sheet(
        store: self.store.scope(state: \.$addItem, action: { .addItem($0) }) { store in
          ItemView(store: store)
        }
      )
    }
  }
  ```
  - 전체적인 흐름은 위에 코드처럼 사용될 수 있음
  - PresentationState와 PresentationAction 타입을 활용해 통합
  - ifLet(_:action:then:fileID:line:) Reducer 연산자를 사용해 리듀서를 결합
  - sheet(store:) 모디파이어를 사용하여 뷰에서 노출시켜줌
  - alert, confirmationDialog, sheet, popover, fullScreenCover 등 SwiftUI의 모든 Navigation API에 대한 오버로드가 포함되어 있음
***
### 열거형 상태
  - 옵셔널 상태로 네비게이션을 제어하는것도 좋지만 간혹 한 화면에서 여러 화면에 대해 옵셔널 값을 가질때 동시에 nil이 아닌 상태가 발생할 여지도 있음
  - 이런 경우를 방지하고자 열거형으로 모델링하는것이 더 나을 수 있음
  ```swift
struct InventoryFeature: Reducer {
  struct State {
    @PresentationState var destination: Destination.State?
  }
  enum Action {
    case destination(PresentationAction<Destination.Action>)
  }
  
  ... // 리듀서 구성
  case .addButtonTapped:
    state.destination = .addItem(AddFeature.State())
    return .none
 ...

  struct Destination: Reducer {
    enum State {
      case addItem(AddFeature.State)
      case detailItem(DetailFeature.State)
      case editItem(EditFeature.State)
    }
    enum Action {
      case addItem(AddFeature.Action)
      case detailItem(DetailFeature.Action)
      case editItem(EditFeature.Action)
    }
    var body: some ReducerOf<Self> {
      Scope(state: /State.addItem, action: /Action.addItem) { 
        AddFeature()
      }
      Scope(state: /State.editItem, action: /Action.editItem) { 
        EditFeature()
      }
      Scope(state: /State.detailItem, action: /Action.detailItem) { 
        DetailFeature()
      }
    }
  }
}
  ```
  - 즉, 중첩될 일은 없음
  - Destination을 만들어서 사용하는 형식
  - 이제 마지막 뷰에서는 아래와 같이 편리하게 사용할 수 있음
  ```swift
struct InventoryView: View {
  let store: StoreOf<InventoryFeature>

  var body: some View {
    List {
      /* code */
    }
    .sheet(
      store: self.store.scope(state: \.$destination, action: { .destination($0) }),
      state: /InventoryFeature.Destination.State.addItem,
      action: InventoryFeature.Destination.Action.addItem
    ) { store in 
      AddFeatureView(store: store)
    }
    .popover(
      store: self.store.scope(state: \.$destination, action: { .destination($0) }),
      state: /InventoryFeature.Destination.State.editItem,
      action: InventoryFeature.Destination.Action.editItem
    ) { store in 
      EditFeatureView(store: store)
    }
    .navigationDestination(
      store: self.store.scope(state: \.$destination, action: { .destination($0) }),
      state: /InventoryFeature.Destination.State.detailItem,
      action: InventoryFeature.Destination.Action.detailItem
    ) { store in 
      DetailFeatureView(store: store)
    }
  }
}
  ```
  - 결국 트리 기반에서 흐름이 꼬일일이 없고 옵셔널 상태보다 조금 더 안전한 느낌이 듬
***
### API 통합
  - 트리 기반 네비게이션의 장점 중 하나는 모든 형태의 네비게이션을 단일 API 스타일로 통합한다는것에 있음
  - ifLet 연산자를 통해서 가능 (모든 형태의 옵셔널 기반 네비게이션을 지원)
  - 또한, 열거 타입에서 아래와 같이 추가적인 작업의 조합이 편리
  ```swift
  case .destination(.presented(.editItem(.saveButtonTapped))):
    guard case let .editItem(editItemState) = self.destination
    else { return .none }

    state.destination = nil
    return .fireAndForget {
      self.database.save(editItemState.item)
    }
  ```
***
### Dismissal
  - 해당 네비게이션을 닫는 기능은 쉽게 nil로 처리하여 가능
  ```swift
  case .closeButtonTapped:
    state.destination = nil
    return .none
  ```
  - 혹은 ChildView에서 dismiss 환경 변수를 이용하여 부모와 소통없이도 닫을 수 있음
  ```swift
  struct ChildView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
      Button("close") { 
        self.dismiss() 
      }
    }
  }
  ```
  - 해당 dismiss가 호출되면 상위에서 바인딩된 값에 nil을 자동으로 SwiftUI가 입력해 해제하는 방식
  - 유용하지만 뷰모델에서 유효성 검사나 비동기 작업과 같은 복잡한 로직들이 구현되어 있을때는 사용하기 현실적으로 어려움 (딱 뷰에 한정적)
  - TCA에선 리듀서에서 사용하기 적합한 DismissEffect를 제공 (리듀서 내부에서만 사용!)
  ```swift
  struct Feature: Reducer {
    struct State { ... }
    struct Action {
      case closeButtonTapped
    }
    
    @Dependency(\.dismiss) var dismiss
    
    ... // 리듀서 구성
     switch action {
     case .closeButtonTapped:
       return .run { send in 
         await self.dismiss()
       }
     }
  }
  ```
  - 이와 같이 사용할 수 있는데, 해당 dismiss는 비동기 함수이기에 .run에서 호출해야함
  - 또한, dismiss 호출 후 다른 액션 처리를 하는것은 런타임 워닝이 됨
***
### 트리 기반 네비게이션 테스팅
  - 피쳐 테스트용 TestStore를 만듬
  ```swift
func testDismissal() {
  let store = TestStore(
    initialState: Feature.State(
      counter: CounterFeature.State(count: 3)
    )
  ) {
    CounterFeature()
  }
}

await store.send(.counter(.presented(.incrementButtonTapped))) {
  $0.counter?.count = 4
}

await store.receive(.counter(.dismiss)) {
  $0.counter = nil
}
  ```
  - 이와 같이 액션에 따른 상태 변경 테스트 및 dismiss 테스트를 해볼 수 있음
  - 아니면 실제로 중요하다고 판단되는 기능들의 일부들을 모아 검증할 수 있음
  ```swift
func testDismissal() {
  let store = TestStore(
    initialState: Feature.State(
      counter: CounterFeature.State(count: 3)
    )
  ) {
    CounterFeature()
  }
  store.exhaustivity = .off

  await store.send(.counter(.presented(.incrementButtonTapped)))
  await store.send(.counter(.presented(.incrementButtonTapped)))
  await store.receive(.counter(.dismiss)) 
}
  ```
  - 열거형 상태로 모델링이 되어 있다면, XCTModify를 활용할 수 있음
  ```swift
await store.send(.destination(.presented(.counter(.incrementButtonTapped)))) {
  XCTModify(&$0.destination, case: /Feature.Destination.State.counter) { 
    $0.count = 4
  }
}
  ```
  - 해당 함수는 첫번째 매개변수로 inout 형태의 enum 상태 변수를 받고 두번째로는 케이스패스를 받아 케이스패스를 활용해 해당 케이스의 payload를 추출하여 수정 및 데이터를 다시 enum에 재삽입하는 과정을 거침
***
### 스택 기반 Navigation 톺아보기
  - 컬렉션 상태를 사용해 네비게이션을 모델링하는 방식
  - 단순히 1차원 데이터 컬렉션을 구성하여 SwiftUI에 전달하여 동작하는 방식
  ```swift
  struct RootFeature: Reducer {
    struct State {
      var path = StackState<Path.State>()
    }
    enum Action {
      case path(StackAction<Path.State, Path.Action>)
    }
    
    struct Path: Reducer {
      enum State {
        case addItem(AddFeature.State)
        case detailItem(DetailFeature.State)
      }
      enum Action {
        case addItem(AddFeature.Action)
        case detailItem(DetailFeature.Action)
      }
      var body: some ReducerOf<Self> {
        Scope(state: /State.addItem, action: /Action.addItem) {
          AddFeature()
        }
        Scope(state: /State.detailItem, action: /Action.detailItem) {
          DetailFeature()
        }
      }
    }
    
    var body: some ReducerOF<Self> {
      Reduce { state, action in 
        ...
      }
      .forEach(\.path, action: /Action.path) {
        Path()
      }
    }
  }
  ```
  - 이와 같이 리듀서가 구성될 수 있음
  - StackState와 StackAction을 사용하고 forEach로 리듀서에 결합해줌
  - 여기서도 트리 기반 네비게이션의 열거형 상태를 만들때 하던것처럼 Path라는 새 리듀서를 정의하여 스택에 추가될 모든 기능들의 도메인을 포함하여 구성
  - 이제 뷰에서는 아래와 같이 사용
  ```swift
  struct RootView: View {
    let store: StoreOf<RootFeature>
    
    var body: some View {
      NavigationStackStore(
        path: self.store.scope(state: \.path, action: { .path($0) })
      ) { 
        // RootView 구성
      } destination: { state in 
        switch state {
        case .addITem:
          CaseLet(
            state: /RootFeature.Path.State.addItem,
            action: RootFeature.Path.Action.addItem,
            then: AddView.init(store:)
          )
        case .detailItem:
          CaseLet(
            state: /RootFeature.Path.State.detailItem,
            action: RootFeature.Path.Action.detailItem,
            then: DetailView.init(store:)
          )
        }
      }
    }
  }
  ```
  - Path.State 열거형의 모든 케이스 처리에 매칭시켜 뷰를 구성
***
### API 통합
  - 패턴 매칭을 통해 이후 동작들의 조합이 가능
  ```swift
  case let .path(.element(id: id, action: .editItem(.saveButtonTapped))):
    guard case let .editItem(editItemState) = self.path[id: id]
    else { return .none }

    state.path.pop(from: id)
    return .run { _ in
      await self.database.save(editItemState.item)
    }
  ```
  - subscript(id:)나 pop(from:)을 이용하여 동작 구성도 가능
***
### Dismissal
  - 스택 기반에서 쌓인것을 제거하기 위해서 popLast()나 pop(from:)을 이용하면 편리함
  - 트리 기반에서와 마찬가지로 뷰에서 dismiss 환경 변수를 사용하여 닫을 수도 있음
  - 또한 리듀서에서 DismissEffect를 사용하여도 동일하게 가능 (트리 기반에서 동일 내용 언급되어 참고!!)
***
### StackState vs NavigationPath
  - SwiftUI에선 NavigationPath라는 타입 자체가 있어 NavigationStack에서 데이터 모델링 시 사용
  - 근데 왜 TCA에선 StackState를 만들었을까?
    - 단순히 끝에 추가 및 제거만 되고 Path 내부 항목을 순회할 수 없었음
    - 스택 상태의 분석이나 데이터 집계하는것이 기본적인 NavigationPath의 기능으론 되지 않아 StackState로 보완하여 만듬
    - StackState는 완전한 정적의 타입화를 가짐
    - 그렇기에 데이터를 함부로 추가할 수 없다는 장단을 가짐
    - 그러나, Collection 프로토콜의 RandomAccessCollection, RangeReplaceableCollection의 요구사항을 만족하기에 컬렉션 조작과 스택 내부 접근에 대해 여러 방법을 사용할 수 있게 구성됨
    - 즉, 런타임의 유연성과 컴파일 타임에서 정적 타입 보장의 균형이 잘 유지되고 있음
***
### 스택 기반 네비게이션 테스팅
  - 트리 기반과 마찬가지로 테스트에 용이함
  - 트리 기반에서 설명한 모든 내용과 코드가 거의 일치하여 큰 설명없이 하나의 참고 테스트 코드만 보고 넘어가봄~
  ```swift
func testDismissal() {
  let store = TestStore(
    initialState: Feature.State(
      path: StackState([
        CounterFeature.State(count: 3)
      ])
    )
  ) {
    CounterFeature()
  }
  store.exhaustivity = .off

  await store.send(.path(.element(id: 0, action: .incrementButtonTapped))) 
  await store.send(.path(.element(id: 0, action: .incrementButtonTapped))) 
  await store.receive(.path(.popFrom(id: 0)))
}
  ```
  - 테스트에 대해 간결한 코드로 이뤄지며 중요치 않은 기능의 변경에 더 유연하게 대응할 수 있음
***
### 소감
- 네비게이션에 대해 확실히 이번에 좀 많이 신경을 쓴 느낌이 들었음
- TCACoordinator라는 라이브러리를 자주 이용하는데 해당 라이브러리를 이용하면 이정도 원초적으로 사용까지 하진 않겠지만, 해당 라이브러리가 발전되는 속도가 더뎌 이제는 필요할지 의문이 생겼음