# Part 8

Navigation은 앱에서 모드를 바꾸는 것이다. 그러므로 알림, 바텀시트, dialog 등이 모두 모드 변경에 포함된다.

TCA는 State, Action을 사용하여 Navigation을 처리하므로 SwiftUI의 명령형 방식의 화면 전환 코드를 작성할 필요가 없다.

상태기반 Navigation은 2가지가 존재한다. 트리 기반 Navigation, 스택 기반 Navigation

### 트리 기반 Navigation

상태 기반 Navigation은 상태의 존재 또는 비존재에 의해 제어된다.

상태의 존재 여부를 Swift의 옵셔널 혹은 열거형 타입으로 정의할 수 있는데 Navigation 상태가 중첩될 수 있음을 의미하고 트리와 같은 구조로 형성하므로 트리 기반 Navigation으로 구성할 수 있다.

item으로 구성된 리스트 항목 중 하나를 탭하면 해당 item의 세부 정보 화면으로 drill-down navigation 수행하는 예시 코드

State 변수를 옵셔널 타입으로 선언하고 PresentationState 프로퍼티 래퍼를 적용한다.

```swift
struct InventoryFeature: Reducer {
  struct State {
    @PresentationState var detailItem: DetailItemFeature.State?
    /* code */
  }
  /* code */
}
```

이후 세부 정보 화면 내 item을 편집하는 sheet 나타내는 버튼이 있을 수 있으며 이것도 옵셔널로 제어한다.

```swift
struct DetailItemFeature: Reducer {
  struct State {
    @PresentationState var editItem: EditItemFeature.State?
    /* code */
  }
  /* code */
}
```

item 수정 기능에는 alert 표시 여부를 나타내는 옵셔널 타입 State가 있을 수 있다.

```swift
struct EditItemFeature: Reducer {
  struct State {
    @PresentationState var alert: AlertState<AlertAction>?
    /* code */
  }
  /* code */
}
```

이 작업은 앱에 존재하는 Navigation 계층 수 만큼 계속 될 수 있다. 중첩된 상태를 구성하는 단순한 작업으로 대체할 수 있다.

우리가 특정 Item에 대해 drill-down하고 Edit sheet를 나타내고, alert을 나타내는 Inventory View를 만들고 싶다면, Navigation을 나타내는 State 부분을 간단히 구성하기만 하면 된다.

```swift
InventoryView(
  store: Store(
    initialState: InventoryFeature.State(
      detailItem: DetailItemFeature.State(      // Drill-down to detail screen
        editItem: EditItemFeature.State(        // Open edit modal
          alert: AlertState {                   // Open alert
            TextState("This item is invalid.")
          }
        )
      )
    )
  ) {
    InventoryFeature()
  }
```

### 스택 기반 Navigation

모드 변의 상태 존재 여부를 표현하는 다른 방식으로 컬렉션이 있다.

SwiftUI의 NavigationStack View에서 활용되며 스택 전체에 있는 기능들이 데이터 컬렉션으로 표현된다.

item이 컬렉션에 추가되면 새로운 기능 추가 된 것이고, 제거되면 기능이 팝업된 것이다.

스택 내 Navigation 가능한 모든 기능들을 포함하는 열거형을 정의한다.

트리기반 예시를 그대로 사용하면,

```swift
enum Path {
  case detail(DetailItemFeature.State)
  case edit(EditItemFeature.State)
  /* code */
}

let path: [Path] = [
  .detail(DetailItemFeature.State(item: item)),
  .edit(EditItemFeature.State(item: item)),
  /* code */
]
```

열거형 Path는 스택에 표시되는 기능 모음을 나타낸다.

Path 요소들의 컬렉션은 필요에 따라 어떤 길이든지 될 수 있는데, 여러 계층까지 깊게 drill-down 되어 있음을 나타내기 위해 매우 길어질 수도 있고, 스택의 루트에 있다는 것을 나타내기 위해 비어있을 수도 있다.

### 트리 기반 Navigation VS 스택 기반 Navigation

보통 앱은 2가지를 혼합해서 사용한다.

앱 루트에서 NavigationStack View가 있는 스택 기반 Navigation 사용하지만, 스택 내부 각 기능인 sheet, popovers, alert 등 표시하기 위해 트리 기반 Navigation 을 사용할 수도 있다.

트리 기반 Navigation 장점

- 트리 기반 Navigation은 매우 간결한 Navigation 모델링 방식을 제공한. 이 방식을 사용하면 앱에서 가능한 모든 Navigation 경로를 정적으로 설명할 수 있으며, 이는 앱에서 유효하지 않은 Navigation 경로를 사용하지 않도록 보장한다.
예를 들어, ‘Detail’ 화면 후에만 ‘Edit’ 화면으로 이동하는 것이 유의미하다면, detail 기능은 Edit 화면으로 이동하는 옵셔널 State만 유지하면 된다.

```swift
struct State {
  @PresentationState var editItem: EditItemFeature.State?
  /* code */
}
```

Detail 화면에서 Edit 화면으로만 이동할 수 있다는 정적 관계가 형성된다.

- 트리 기반 Navigation을 사용하면 앱에서 지원하는 Navigation 경로의 수를 제한할 수도 있다.
- 앱의 기능을 모듈화하면, 이러한 기능 모듈들은 트리 기반 Navigation 도구를 사용하여 구축될 때 더욱 독립적으로 구성된다. 즉, Xcode previews 와 해당 기능을 위해 구축된 previews 앱들이 완벽하게 작동됩니다. 예를 들어 상세 기능에 대한 모든 로직과 View를 포함하는 DetailFeature 모듈이 있다면, 편집 기능의 도메인이 상세 기능에 직접 내장되어 있으므로 previews에서 편집 기능으로 이동할 수 있다.
- 기능 간 서로 밀접하게 결합된 특성 때문에 통합에 대한 단위 테스트 작성이 매우 간단해진다. 상세 기능 및 편집 기능이 어떻게 통합되는지에 대해 심층적이고 섬세한 테스트를 작성할 수 있으며, 올바른 방식으로 상호 작용하는지 증명할 수 있다.
- 트리 기반 Navigation은 drill-down, sheet, popovers, fullscreen covers, alert, dialogs 등 모든 형태의 Navigation을 간결한 단일 스타일의 API로 통합한다.

트리 기반 Navigation 단점

- 복잡하거나 재귀적인 Navigation 경로를 트리 기반 Navigation을 사용해 표현하는 것은 번거로울 수 있다.
    
    예를 들어, 영화 앱에서 영화 정보로 이동한 후 해당 영화에 출연한 배우 목록으로 이동하고, 특정 배우로 이동한 후 다시 처음 시작했던 동일한 영화로 돌아가는 상황을 가정한다.
    
    이는 기능 간에 재귀적인 의존성을 만들어내며, Swift 데이터 타입으로 모델링하기 어렵게 만든다.
    
- 설계상 트리 기반 Navigation은 기능들을 서로 결합한다. 상세 정보 기능에서 편집 기능로 이동이 가능하다면, 상세 정보 기능을 컴파일하기 위해서는 전체 편집 기능도 컴파일할 수 있어야 한다. 이는 결국 컴파일 시간을 늦추며, 앱의 루트에 가까운 곳일 수록 포함된 하위 목적지의 모든 기능을 빌드해야 하므로 지연되는 시간이 더 늘어난다.
- 역사적으로 보면, 트리 기반 Navigation은 SwiftUI의 Navigation 버그에 좀 더 취약하다. 특히 drill-down Navigation과 관련된 문제가 그렇다. 그러나 많은 버그들은 iOS 16.4에서 수정되었으므로 요즘에는 크게 걱정할 필요가 없다.

**스택 기반 Navigation의 장점**

- 재귀적인 Navigation 경로를 쉽게 처리할 수 있다. 앞서 살펴본 영화 앱 예시는 스택 기반 Navigation으로 다양한 기능들과 State를 사용하여 쉽게 수행할 수 있다.
    
    ```swift
    let path: [Path] = [
      .movie(/* code */),
      .actors(/* code */),
      .actor(/* code */)
      .movies(/* code */),
      .movie(/* code */),
    ]
    
    ```
    
    movie 기능에서 시작하여 movie 기능에서 끝나는 것을 알 수 있다. 이 Navigation은 1차원 배열이기 때문에 실제 재귀가 없다.
    
- 스택에 포함된 각 기능은 일반적으로 스택의 다른 모든 화면에서 완전히 분리될 수 있다. 즉, 기능을 서로 의존성 없이 자체 모듈에 넣을 수 있으며 다른 기능을 컴파일하지 않고도 컴파일할 수 있다.
- SwiftUI의 NavigationStack API는 일반적으로 트리 기반 Navigation에 사용되는 `NavigationLink(isActive:)`및 `navigationDestination(isPresented:)` 보다 버그가 적다. NavigationStack에는 여전히 몇 가지 버그가 있지만 평균적으로 훨씬 더 안정적이다.

**스택 기반 Navigation의 단점**

- 완전히 비논리적인 Navigation 경로를 표현할 수 있다. 예를 들어, 상세 화면에서 편집 화면으로 이동하는 것이 합리적이지만 스택에서는 기능을 역순으로 표시하는 것이 가능하다.
    
    ```swift
    let path: [Path] = [
      .edit(/* code */),
      .detail(/* code */)
    ]
    
    ```
    
    이는 완전히 비논리적이다. 위 코드는 편집 화면으로 drill-down 한 다음 상세 정보 화면으로 이동한다는 것으로 해석이 가능한데, 실제 앱에서 어떻게 작동될지 예측할 수 없는 논리적 오류를 갖고 있다. 또한, 여러 개의 편집 화면이 연이어 표시되는 등 비합리적인 Navigation 경로를 만들 수 있다.
    
    ```swift
    let path: [Path] = [
      .edit(/* code */),
      .edit(/* code */),
      .edit(/* code */),
    ]
    
    ```
    
    이 역시 완전히 비논리적이며, 앱에서 명확하게 정의된 유한한 수의 Navigation 경로를 원하는 상황에서 이런 코드가 발생할 수 있다는 것은 스택 기반 접근법의 한계다.
    
- 앱을 모듈화하여 각 기능을 별도의 모듈로 분리하면, Xcode previews 에서 해당 기능들이 독립적으로 실행될 때 다른 기능들은 대부분 비활성화 상태가 된다.
    
    예를 들어 상세 정보 기능 내에서 편집 기능으로 drill-down 하는 버튼은 두 기능이 완전히 분리되어 있기 때문에 Xcode previews 에서 정상 작동하지 않는다. 이로 인해 Xcode previes 에서는 상세 정보 기능의 모든 기능을 테스트할 수 없으며, 대신 전체 앱을 컴파일하고 실행하여 모든 기능을 확인해야 한다.
    
- 상기한 내용과 관련하여, 여러 기능들이 서로 어떻게 통합되는 지에 대한 단위 테스트를 진행하는 것이 더욱 복잡해진다. 완전히 분리된 기능들로 인해 상세 정보 기능과 편집 기능 간의 상호작용을 쉽게 테스트할 수 없다. 이러한 유형의 테스트를 작성하는 유일한 방법은 전체 앱을 컴파일하고 실행하는 것이다.
- 스택 기반 Navigation과 NavigationStack 은 drill-down에만 적용되며 sheet, popovers, alert 등과 같은 다른 형태의 Navigation에 대해서는 전혀 대응하지 않는다. 이러한 종류의 Navigation을 분리하는 작업은 여전히 개발자의 몫이다.

TCA는 Navigation 상태를 `앱의 State`에 포함시킨다. 예를 들어, 현재 보여지고 있는 화면이 어떤 것인지를 나타내는 변수나, 다음으로 이동해야 할 화면 정보 등을 State에 저장한다. 이렇게 함으로써 현재 Navigation 상태를 쉽게 추적하고 변경할 수 있으며 디버깅과 테스트 작성에도 용이하다.

사용자의 화면 전환 요청은 Action으로 처리된다. 사용자가 버튼을 클릭하거나 제스터를 수행하는 등의 인터랙션은 해당 이벤트가 Action으로 변환되어 Reducer로 전달된다. Reducer는 이 `Action`을 받아서 앱의 `State`를 업데이트하고, 업데이트된 State에 따라 View가 자동으로 변경되어 새로운 화면이 표시된다.

Navigation 관련 로직은 주로 Reducer에서 처리되는데, Reducer는 현재 `Navigation State`와 `Action`을 기반으로 새로운 Navigation 상태를 결정하고 반환한다. 이렇게 함으로써 TCA는 일관된 방식으로 화면 전환 로직을 관리하며, 코드 가독성과 유지보수성을 향상시킨다.

### 트리 기반 Navigation 살펴보기

트리 기반 Navigation을 위한 도구에는 PresentationState 프로퍼티 래퍼, PresentationAction, ifLet(_:action:then:fileID:line:) 연산자, .sheet, .popover 등과 같은 SwiftUI의 일반 도구를 모방한 여러 API가 있다.

일반적으로 기능의 도메인을 함께 통합하는 것으로 시작하는데, 이는 부모에 자식의 State와 Action을 추가하고, Reducer 연산자를 사용하여 자식 기능을 부모에 구성한다.

예를 들어 Item 리스트가 있고 새 Item을 추가하는 Form을 보여주기 위한 sheet를 나타내려 하면PresentationState와 PresentationAction 타입들을 활용하여 State와 Action을 함께 통합할 수 있다.

```swift
struct InventoryFeature: Reducer {
  struct State: Equatable {
    @PresentationState var addItem: ItemFormFeature.State?
    var items: IdentifiedArrayOf<Item> = []
    /* code */
  }

  enum Action: Equatable {
    case addItem(PresentationAction<ItemFormFeature.Action>)
    /* code */
  }

  /* code */
}
```

또한 ifLet(_:action:then:fileID:line:) Reducer 연산자를 사용하여 부모와 자식 기능의 Reducer를 통합할 수 있으며, Navigation을 유도하기 위해 자식의 State를 채우는 Action을 부모 도메인에서 가질 수 잇다.

```swift
struct InventoryFeature: Reducer {
  struct State: Equatable { /* code */ }
  enum Action: Equatable { /* code */ }
  
  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in 
      switch action {
      case .addButtonTapped:
        // Populating this state performs the navigation
        state.addItem = ItemFormFeature.State()
        return .none

      /* code */
      }
    }
    .ifLet(\.$addItem, action: /Action.addItem) {
      ItemFormFeature()
    }
  }
}
```

이제 이것을 sheet형식으로 보여주려면, View에서 처리해주면 된다.

```swift
struct InventoryView: View {
  let store: StoreOf<InventoryFeature>

  var body: some View {
    List {
      /* code */
    }
    .sheet(
      store: self.store.scope(state: \.$addItem, action: { .addItem($0) })
    ) { store in
      ItemFormView(store: store)
    }
  }
}
```

이렇게 화면 전환 방식에 여러개가 존재한다.

- alert(store:)
- confirmationDialog(store:)
- sheet(store:)
- popover(store:)
- fullScreenCover(store:)
- navigationDestination(store:)
- NavigationLinkStore

### 열거형 상태

```swift
struct State {
  @PresentationState var detailItem: DetailFeature.State?
  @PresentationState var editItem: EditFeature.State?
  @PresentationState var addItem: AddFeature.State?
  /* code */
}
```

옵셔널 상태로 Navigation을 제어하는 것은 효과적일 수 있지만, 항상 이상적이지 않을 수 있다.

하나의 기능에 여러 화면으로 이동할 수 있는 경우 여러개 옵셔널 값으로 모델링 하려는 유혹에 빠질 수 있다.

그러나 이렇게 하면 두 개 이상의 상태가 동시에 nil이 아닌 것과 같은 유효하지 않은 상태가 발생할 수 있고, 이로 인해 많은 문제가 발생할 수 있다.

첫째로, SwiftUI는 단일 View에서 동시에 여러 View를 표시하는 것을 지원하지 않는다. 따라서 위 상태에서 이런 경우를 허용하면, 앱이 SwiftUI와 관련하여 일관성 없는 상태에 빠질 위험이 있다.

둘째로, 어떤 기능이 실제로 표현되고 있는지 판단하기가 더 어려워진다. 어떤 값이 nil이 아닌지 여러 옵셔널 상태 값을 확인해야 하며, 그 후에도 여러 상태가 동시에 nil이 아닐 때 그것을 어떻게 해석해야 할 지 결정해야한다.

그리고 이동 가능한 기능의 수에 따라 유효하지 않은 상태의 경우의 수는 기하급수적으로 증가한다.

예컨대 3개의 옵셔널 상태는 4개의 유효하지 않은 상태를 만들어내고, 4개는 11개의 유효하지 않은 상태를 만들어내고, 5개는 26개의 유효하지 않은 상태를 만들어낸다. 유효하지 않은 상태의 수는 탐색할 수 있는 기능의 수에 따라 기하급수적으로 증가한다.

이런 문제들과 그 외 다른 문제들 때문에, 기능 내에서 여러 목적지를 모델링할 때 단일 열거형으로 모델링하는 것이 여러 옵셔널 상태 값을 사용하는 것보다 나을 수 있다. 따라서 위 예처럼 세 개의 옵셔널 값을 가진 State를 열거형으로 리팩토링한다.

```swift
enum State {
  case addItem(AddFeature.State)
  case detailItem(DetailFeature.State)
  case editItem(EditFeature.State)
  /* code */
}
```

이 방법은 컴파일 시간에 한 번에 하나의 목적지만 활성 상태가 될 수 있다는 것을 증명해준다.

이런 유형의 도메인 모델링을 적용하려면 추가적인 단계를 거쳐야 한다. 첫째로, 이동 가능한 모든 기능의 영역과 행동을 포함하는 ‘destination’ Reducer를 설계한다.

그리고 보통은 이 Reducer를 Navigation을 실행할 수 있는 기능 내부에 배치하는 것이 가장 좋다.

```swift
struct InventoryFeature: Reducer {
  /* code */

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

TCA Coordinator 와 비슷한구조?

State 및 Action 열거형에서 특정 case를 세밀하게 다루기 위해 case path를 사용한다.

이제 PresentationState 프로퍼티 래퍼를 사용하여 기능에서 단일 옵셔널 상태를 유지할 수 있게 되며, destination Action은 PresentationAction 타입을 이용해 관리할 수 있게 된다.

```swift
struct InventoryFeature: Reducer {
  struct State { 
    @PresentationState var destination: Destination.State?
    /* code */
  }
  enum Action {
    case destination(PresentationAction<Destination.Action>)
    /* code */
  }

  /* code */
}
```

특정 기능 표시하고 싶을 때 destination State를 열거형의 case로 채우기만 하면 된다.

```swift
case addButtonTapped:
  state.destination = .addItem(AddFeature.State())
  return .none
```

Destination 영역에 초점을 맞춘 Store를 제공하고, State와 Action 열거형의 특정 case를 고립시키는 변환을 제공한다.

각 프레젠테이션 스타일이 해당 destination 열거형의 case에 따라 작동되도록 설정할 수 있다.

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

### API 통합

트리 기반 Navigation의 주요 장점 중 하나는 모든 형태의 Navigation을 단일 API 스타일로 통합한다.

만약 Edit 기능 내의 save 버튼 눌렀던 것을 감지하고 싶다면, 재구성하기만 하면 된다.

```swift
case .destination(.presented(.editItem(.saveButtonTapped))):
  /* code */
```

```swift
case .destination(.presented(.editItem(.saveButtonTapped))):
  guard case let .editItem(editItemState) = self.destination
  else { return .none }

  state.destination = nil
  return .fireAndForget {
    self.database.save(editItemState.item)
  }
```

### Dismissal

닫으려면 destination을 nil로 해주면 된다.

```swift
case .closeButtonTapped:
  state.destination = nil
  return .none
```

만약 부모와 커뮤니케이션 없이 스스로 해결하고 싶으면 dismiss Environment를 사용해도 된다.

```swift
struct ChildView: View {
  @Environment(\.dismiss) var dismiss
  var body: some View {
    Button("Close") { self.dismiss() }
  }
}
```

이게 호출되면 가장 인접한 부모 View 찾아서 해당 프레젠테이션 실행하고 주동하는 바인딩에 false, nil 값을 입력하여 해제한다.

 따라서, Observable Object와 같은 곳에서 유효성 검사나 비동기 작업과 같은 복잡한 해제 로직을 구현하는데 dismiss 기능을 활용하는 것은 불가능하다.

TCA는 유사한 도구를 제공하지만 이 도구는 Reducer에서 사용하기 적합하며 Reducer 내부에는 대부분의 기능 로직과 동작이 포함되어 있다.

이 기능은 라이브러리의 의존성 관리 시스템을 통해 접근할 수 있으며, ‘DismissEffect’라고 명명되어 있다.

```swift
struct Feature: Reducer {
  struct State { /* code */ }
  enum Action { 
    case closeButtonTapped
    /* code */
  }
  @Dependency(\.dismiss) var dismiss
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .closeButtonTapped:
      return .fireAndForget { await self.dismiss() }
    } 
  }
}
```

이 함수는 비동기 함수이므로 일반적인 Reducer에서 못하고 run에서 호출해야한다.

```swift
return .run { send in 
  await self.dismiss()
  await send(.tick)  // Warning
}
```

dismiss() 호출한 후 Action 전송하면 제대로 수행되지 않는다.

상태가 nil일 때 기능에 대한 Action을 전송하게 될 때, Xcode에서 런타임 경고가 발생되고 테스트를 실행할 때 테스트가 실패하게 된다.

SwiftUI의 환경 변수 @Environment(\.dismiss)와 TCA의 의존성 변수 @Dependency는 비슷한 용도로 사용되지만, 완전히 다른 타입이다.

SwiftUI의 환경 변수는 SwiftUI View에서만 사용할 수 있고, 이 라이브러리의 의존성 변수는 Reducer 내부에서만 사용 가능하다.

### 트리 기반 Navigation Testing

카운트가 5보다 크거나 같으면 자신을 dismiss하는 카운터

```swift
struct CounterFeature: Reducer {
  struct State: Equatable {
    var count = 0
  }
  enum Action: Equatable {
    case decrementButtonTapped
    case incrementButtonTapped
  }

  @Dependency(\.dismiss) var dismiss

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .decrementButtonTapped:
      state.count -= 1
      return .none

    case .incrementButtonTapped:
      state.count += 1
      return state.count >= 5
        ? .fireAndForget { await self.dismiss() }
        : .none
    }
  }
}
```

ifLet 사용하여 해당 기능을 부모 기능과 통합한다.

```swift
struct Feature: Reducer {
  struct State: Equatable {
    @PresentationState var counter: CounterFeature.State?
  }
  enum Action: Equatable {
    case counter(CounterFeature.Action)
  }
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      // Logic and behavior for core feature.
    }
    .ifLet(\.$counter, action: /Action.counter) {
      CounterFeature()
    }
  }
}
```

3으로 설정된 상태에서 Feature용 TestStore를 만들어야 한다.

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
```

```swift
await store.send(.counter(.presented(.incrementButtonTapped))) {
  $0.counter?.count = 4
}
```

```swift
await store.send(.counter(.presented(.incrementButtonTapped))) {
  $0.counter?.count = 5
}
```

마지막으로, 카운터 상태가 nil로 변환된 상태가 되는데 이것을 receive로 확인할 수 있다.

```swift
await store.receive(.counter(.dismiss)) {
  $0.counter = nil
}
```

추가로 ‘열거형 상태’에서 설명한 개념을 이용하여 여러 Destination을 다수의 옵셔널이 아닌 Enum으로 모델링하면 테스트는 더 복잡해진다.

Enum State를 사용하는 경우, 상태 변화에 대한 검증을 위해서는 반드시 Enum에서 관련된 상태 값을 추출하고, 수정한 후, 수정된 새로운 상태 값을 다시 Enum에 넣어야 한다.

라이브러리는 이 과정들을 한 번에 처리할 수 있는 도구인 ‘XCTModify’를 제공한다.

```swift
await store.send(.destination(.presented(.counter(.incrementButtonTapped)))) {
  XCTModify(&$0.destination, case: /Feature.Destination.State.counter) {
    $0.count = 4
  }
}

```

XCTModify 함수는 첫 번째 매개변수로 inout 형태의 enum 상태 변수를, 두 번째 매개변수로 case path를 받는다.

그리고 이 case path를 활용해 해당 case의 payload를 추출하며, 이것에 대한 수정을 진행하고 데이터를 다시 enum에 재삽입한다.

따라서 위 코드에서는 `$0.destination` 이라는 enum을 `.counter`로 분리하고 count 값을 1만큼 증가시켜 4가 되도록 수정하는 것이다.

추가적으로 만약 `$0.destination`의 case가 case path와 일치하지 않다면 테스트 실패 메시지가 출력된다.

### 스택 기반 Navigation 살펴보기

스택 기반 Navigation을 위한 도구로는 StackState, StackAction 그리고 forEach(_:action:destination:fileID:line:) 연산자를 포함하여, TCA에 맞추어 조정된 새로운 NavigationStackStore View가 있다.

스택에 통합하는 과정은 2단계로 구성 되어 잇다.

1. 기능들의 도메인을 통합하고 스택 내의 모든 View를 설명하는 NavigationStackStore를 만든다.  보통은 기능들의 도메인 통합부터 시작한다. 이 과정에서 Path라 불리는 새 Reducer를 정의하여 스택에 추가될 수 있는 모든 기능들의 도메인을 포함한다.

```swift
struct RootFeature: Reducer {
  /* code */

  struct Path: Reducer {
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

Path Reducer는 트리기반과 동일하다.

Navigation 스택을 관리하는 기능에서 StackSate, StackAction을 유지할 수 있다.

```swift
struct RootFeature: Reducer {
  struct State {
    var path = StackState<Path.State>()
    /* code */
  }
  enum Action {
    case path(StackAction<Path.State, Path.Action>)
    /* code */
  }
}
```

부모 기능의 도메인과 함께 Navigation을 수행할 수 있는 모든 기능들의 도메인을 통합하기 위해서는 forEach(_:action:destination:fileID:line:) 메서드를 활용해야 한다.

```swift
struct RootFeature: Reducer {
  /* code */

  var body: some ReducerOf<Self> {
    Reduce { state, action in 
      // Core logic for root feature
    }
    .forEach(\.path, action: /Action.path) { 
      Path()
    }
  }
}
```

자식 기능과 부모 기능을 통합하는단계는 완료

2번째 단계는, 자식 View와 부모 View를 결합하는 것이다.

NavigationStackStore를 구성해서 수행된다.

3가지 매개변수를 필요로 한다.

- 도메인 내의 StackState와 StackAction에 초점을 맞춘 store
- 스택의 Root View를 위한 Trailing View Builder
- 스택에 푸쉬될 수 있는 모든 View들을 생성하는 추가적인 Trailing View Builder

```swift
NavigationStackStore(
  // Store focused on StackState and StackAction
) {
  // Root view of the navigation stack
} destination: { state in 
  switch state {
    // A view for each case of the Path.State enum
  }
}
```

Root 기능은 이미 보유하고 있는 Path State, Path Action으로만 store의 범위 저정해주면 된다.

```swift
struct RootView: View {
  let store: StoreOf<RootFeature>

  var body: some View {
    NavigationStackStore(
      path: self.store.scope(state: \.path, action: { .path($0) })
    ) {
      // Root view of the navigation stack
    } destination: { state in
      // A view for each case of the Path.State enum
    }
  }
}
```

마지막으로 후행 클로저는 Path.State 열거형의 한 부분을 제공하여 분기 처리할 수 있게 한다.

```swift
struct RootView: View {
  let store: StoreOf<RootFeature>

  var body: some View {
    NavigationStackStore(
      path: self.store.scope(state: \.path, action: { .path($0) })
    ) {
      // Root view of the navigation stack
    } destination: { state in
      switch state {
      case .addItem:
      case .detailItem:
      case .editItem:
      }
    }
  }
}
```

이 방식 사용하면, 컴파일 시간에 Path.State 열거형의 모든 case가 처리되었다는 것을 보장받게 된다. 이는 스택에 새로운 유형의 Destination을 추가할 때 편리하다.

각각 원하는 종류의 View 반환할 수 있지만, Path.State 열거형인 특정 case로 범위 좁히기 위해 CaseLet View를 활용하고자 한다.

```swift
} destination: { state in
  switch state {
  case .addItem:
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
  case .editItem:
    CaseLet(
      state: /RootFeature.Path.State.editItem,
      action: RootFeature.Path.Action.editItem,
      then: EditView.init(store:)
    )
  }
}
```

### API 통합

path에서 해당 케이스에서 기능의 상태 추출하여 추가적인 로직 실행 가능하다.

```swift
case let .path(.element(id: id, action: .editItem(.saveButtonTapped))):
  guard case let .editItem(editItemState) = self.path[id: id]
  else { return .none }

  state.path.pop(from: id)
  return .run { _ in
    await self.database.save(editItemState.item)
  }
```

### Dismissal

스택에서 제거하는 것으로 popLast(), pop(from:) 이용해 간단히 수행가능.

```swift
case .closeButtonTapped:
  state.popLast()
  return .none
```

아까 트리기반 처럼, Environment dismiss 가능하다!

@Dependency dismiss도 동일하게 제공

### StackState vs NavigationPath

SwiftUI에서 NavigationPath라는 강력한 타입 가지고 있는데, NavigationPath를 왜 활용 안할까?

NavigationPath 데이터 유형은 특히 NavigationStacks에 맞춰 조정된 타입-제거된(type-erased) 데이터 목록이다. 이는 Hashable 속성을 가진 어떤 종류의 데이터든지 경로에 추가될 수 있도록 해주므로, 스택 안의 기능들을 최대한 분리하는 데 도움이 된다.

```swift
var path = NavigationPath()
path.append(1)
path.append("Hello")
path.append(false)
```

SwiftUI는 어떤 View가 특정 데이터 유형에 대응하여 스택에 삽입되어야 하는지 명시함으로써 해당 데이터 해석한다.

```swift
struct RootView: View {
  @State var path = NavigationPath()

  var body: some View {
    NavigationStack(path: self.$path) {
      Form {
        /* code */
      }
      .navigationDestination(for: Int.self) { integer in 
        /* code */
      }
      .navigationDestination(for: String.self) { string in 
        /* code */
      }
      .navigationDestination(for: Bool.self) { bool in 
        /* code */
      }
    }
  }
}
```

강력하지만, 단점은 데이터가 타입-제거 되어있어서 이에대한 API를 제공하지 않고 있다.

또는 Path의 개수를 확인할 수 있다.

```swift
path.count

```

참고로 스택 끝을 제외한 다른 곳에서는 항목을 삽입하거나 제거할 수 없으며 Path 내부 항목을 순환할 수도 없다.

```swift
let path: NavigationPath = …
for element in path {  // 🛑
}
```

이로 인해 스택 상태를 분석하거나 전체 스택 걸쳐 데이터를 집계하는 것이 매우 어려워질 수 있습니다. TCA의 StackState는 NavigationPath와 비슷한 목적으로 사용되지만 다른 절충점들을 갖게 된다.

StackState는 완전히 정적으로 타입화 되어있다.

따라서 장단점 중 하나는 단순히 어떤 종류의 데이터든 함부로 추가할 수 없다는 것이다. 그러나, StackState는 Collection 프로토콜(RandomAccessCollection 및 RangeReplaceableCollection)의 요구사항들도 만족한다. 이러한 속성은 컬렉션 조작과 스택 내부 접근에 대한 여러 방법들을 사용할 수 있게 한다.

기능의 데이터는 Hashable일 필요 없이 StackState에 포함될 수 있다. 데이터 타입은 내부적으로 기능의 식별자를 안정적으로 관리하고 해당 식별자로부터 해시 값을 자동으로 추출한다.

우리는 StackState가 완벽한 런타임 유연성과 컴파일 시간에서의 정적 타입 보장 사이에서 훌륭한 균형을 제공한다고 생각한다. 그리고 이것이 TCA에서 Navigation 스택을 모델링하기 위한 최적의 도구라고 믿는다.

### 스택 기반 Navigation Testing

트리 기반과 동일하게 테스트가 용이하다.

아까와 같은 코드에서,

해당 기능을 부모 기능과 통합

```swift
struct Feature: Reducer {
  struct State: Equatable {
    var path = StackState<Path.State>()
  }
  enum Action: Equatable {
    case path(StackAction<Path.State, Path.Action>)
  }

  struct Path: Reducer {
    enum State: Equatable { case counter(Counter.State) }
    enum Action: Equatable { case counter(Counter.Action) }
    var body: some ReducerOf<Self> {
      Scope(state: /State.counter, action: /Action.counter) { Counter() }
    }
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      // Logic and behavior for core feature.
    }
    .forEach(\.path, action: /Action.path) { Path() }
  }
}
```

자식에서 5을 넘어서 증가하면 종료된다는 것을 입증하기 위해 Feature Reducer에 대한 테스트 진행

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
}
```

그런 다음, 카운트가 1씩 증가하는 것을 확인하기 위해 스택 내부의 카운터 자식 기능에 `.incrementButtonTapped`Action을 전송할 수 있다. 그러나 이를 실행하기 위해서는 ID를 제공해야 한다.

```swift
await store.send(.path(.element(id: ???, action: .incrementButtonTapped))) {
  /* code */
}

```

API 통합에서 언급한 바와 같이, StackState는 각각의 기능에 대해 자동적으로 ID를 관리하고, 이 ID는 주로 외부에서 볼 수 없다.

그러나 테스트 상황에서는 이러한 ID들이 전역적으로 정수 형태를 가지며, ID는 0부터 시작해 스택에 푸쉬되는 각 기능마다 전역 ID가 하나씩 증가한다.

따라서 스택에 이미 하나의 요소가 있는 상태에서 TestStore를 구성하면 해당 요소에 0의 ID가 부여되며, 이것이 바로 Action을 전송할 때 사용할 수 있는 ID가 된다.

```swift
await store.send(.path(.element(id: 0, action: .incrementButtonTapped))) {
  /* code */
}
```

다음으로 우리는 Action이 전송됐을 때 스택 내부의 카운터 기능이 어떻게 변화하는지 확인하려 한다.

이 과정은 ID의 값을 반환하고 열거형 case와 패턴매칭을 진행하는 등 여러 단계를 필요로 하지만 간단하게 XCTModify 함수로 테스트를 진행할 수 있다.

```swift
await store.send(.path(.element(id: 0, action: .incrementButtonTapped))) {
  XCTModify(&$0[id: 0], case: /Feature.Path.State.counter) {
    $0.count = 4
  }
}
```

XCTModify 함수는 첫 번째 매개변수로 inout 형태의 enum 상태를 가져오고, 두 번째 매개변수로는 case path를 가져온다. 그 후 이 함수는 case path를 사용해 해당 case에서 payload를 추출하고 이에 대한 변환을 수행한 후 데이터를 다시 enum에 포함시킨다.

따라서 위 코드에서 우리는 ID는 0으로 subscripting을 수행하며 `Path.State.enum`의 `.counter` case를 분리하고 카운트가 하나씩 증가해서 4가 되도록 수정한다.

추가적으로 만약 `$0[id: 0]`의 case가 case path와 일치하지 않으면 테스트 실패 메시지가 발생된다.

또 다른 방법은 `subscript(id:case:)`을 사용하여 스택의 ID와 열거형의 case path를 동시에 subscript 하는 것이다.

```swift
await store.send(.path(.element(id: 0, action: .incrementButtonTapped))) {
  $0[id: 0, case: /Feature.Path.State.counter]?.count = 4
}

```

마지막으로, 우리는 자식 객체가 스스로를 해제하는 것을 예상한다.

이는 `StackAction.popFrom(id:)` Action을 통해 카운터 기능이 스택에서 제거되는 형태로 나타나는데, 이 과정은 TestStore의 `receive(_:timeout:assert:file:line:)` 메서드를 사용하여 확인할 수 있다.

```swift
await store.receive(.path(.popFrom(id: 0))) {
  $0.path[id: 0] = nil
}

```

이를 통해 Navigation 스택에서 부모와 자식 기능 간의 미세한 상호작용에 대한 테스트를 작성하는 방법을 알아보았다.

그러나 기능이 복잡해질수록 통합 테스트는 점점 더 까다로워진다.

원칙적으로 TestStore는 완전성을 요구하는데, 모든 상태 변화, 모든 Effect가 시스템에 어떻게 데이터를 피드백하는지, 모든 Effect가 테스트 종료 전까지 완료 되었는지 확인할 수 있어야한다.

그러나 TestStore는 비완전한 혹은 선택적인 테스트도 지원한다.

이를 이용하면 실제로 중요하다고 생각되는 기능의 일부만 검증할 수 있다.

예를 들어, TestStore에서 완전성 검사를 비활성화하면, 증가 버튼이 두 번 클릭될 때 결국 `StackAction.popFrom(id:)` Action이 발생함을 상위 수준에서 검증할 수 있다.

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

이는 본질적으로 이전 테스트에서 증명한 것과 동일한 내용을 증명하고 있지만, 훨씬 더 간결한 코드로 이루어지며, 중요하지 않은 기능의 변경에 대해 더 유연하게 대응할 수 있다.
