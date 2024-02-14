# TCA 1.0 스터디 (TCA Binding)
# 챕터 자료
- https://axiomatic-fuschia-666.notion.site/Chapter-4-TCA-Binding-87f748b3f8fa41a08a9089d78aeb422c
***
#  스터디 내용
- ### SwiftUI Binding VS TCA Binding
  - SwiftUI에선 @State, @Binding, @ObservedObject들을 통해 양방향 바인딩 구현 및 상태 관리
  - SwiftUI에서 상태 관리가 복잡해질수록 사이드 이펙트 관리에 어려움
  - 그렇기에 TCA의 Binding은 State 관리 바인딩 도구들을 제공하여 단방향 데이터 흐름 원칙을 지킴
  - 그로 인해, 사이드 이펙트 관리 및 복잡한 상태들을 일관되게 처리할 수 있음
  - 간단한 뷰하고 로직짜는데 여러 코드가 들어가야하는것은 어쩔수 없긴함
***
- ### TCA Binding
  - 가장 기본적으로 Binding(get:send:)의 형태로 TCA는 바인딩을 함
    - get: State를 바인딩 값으로 변환
    - send: 바인딩 값을 다시 Store에 피드백하는 Action으로 변환
  - ReducerProtocol 이전에도 늘 사용하던 방식이라 익숙한 방식
  ```swift
  // Core
  struct Main: Reducer {
    struct State: Equatable {
      var isOnAlarm: Bool = false
    }
    
    enum Action {
      case isOnAlarmChanged(Bool)
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case let .isOnAlarmChanged(isOn):
        state.isOnAlarm = isOn
        return .none
      }
    }
  }
  
  // View
  struct MainView: View {
    let store: StoreOf<Main>
    
    var body: some View {
      WithViewStore(self.store, observe: { $0 }) { viewStore in 
        Toggle(
          "Alarm",
          isOn: viewStore.binding(
            get: \.isOnAlarm,
            send: { .isOnAlarmChanged($0) }
          )
        )
      }
    }
  }
  ```
  - 이런 형태로 구성됨
  - Toggle 컴포넌트의 isOn 바인딩 파라미터에 바인딩 객체를 전달하는 형식
  - 여기서 get을 통해서 SwiftUI 컴포넌트와 바인딩 통신을 하고 send를 통해서 Store 내부에 바인딩 값을 전달하여 상태 변경과 같은 비지니스 로직을 수행하게됨
  - 기존에는 이렇게만 썼었는데, 이것의 가장 큰 문제점이라기 보다는 귀찮은 점은 이런 바인딩되는 State가 많다면 코어에서 State, Action, Reducer에 모두 코드가 구현되어야함
  - 즉, 반복 작업을 동반하게되고 리듀서가 점점 커져 관리가 복잡해질 수 있다는 점이 단점이라면 단점
***
- ### 다양한 TCA의 Binding tools
  - 위 알아봤던 바인딩의 문제들을 해결하고자 TCA에선 다양한 바인딩 도구들을 제공하게 됨
  - BindingState, BindingAction, BindingReducer들이 이제 적극적으로 활용되는데, 이전에 안다뤄봤던 영역이라 자세히 알아볼 예정!
  - BindingState
    ```swift
    struct Main: Reducer {
      struct State: Equatable {
        @BindingState var isOnAlarm = false
      }
    }
    ```
    - 이와 같이 @BindingState 프로퍼티 래퍼를 붙여 해당 필드 값을 뷰의 UI 컴포넌트에서 바인딩 가능하도록 만들어줌
    - 그럼 이제, 해당 값은 바인딩 값이 되었기에 바로 뷰에서 해당 필드 값의 조정이 가능한것!
    - 다만, 외부에서 직접 변경이 당연히 가능한 형태이니 캡슐화가 잘 지켜지지 않기에 꼭 SwiftUI 기본 컴포넌트에 전달하기 위한 필드들에만 사용하는것을 권장
    - 근데 이제 최신 버전에서는 매크로 등장으로 BindingState 프로퍼티 래퍼 안붙여도됨
    ```swift
    @ObservableState
    struct State {
      var isOnAlarm = true
    }
    ```
    - 이렇게 변경된걸로 쓰게 되면 뷰에서도 `@Bindable var store: StoreOf<Feature>` 처럼 사용
  - BindingAction
    - Action enum에 BindableAction 프로토콜을 채택하여, State의 모든 필드 액션을 하나의 케이스로 병합함으로 깔끔하게 제공해줌
    - 제네릭 타입을 갖는 BindingAction을 인자로 받음 -> BindingAction<State>
    ```swift
    enum Action: BindableAction {
      case binding(BindingAction<State>)
    }
    ```
  - BindingReducer
    - Binding Action이 들어올 때, State 업데이트 쳐주는 리듀서!
    ```swift
    var body: some Reducer<State, Action> {
      BindingReducer()
    }
    ```
    - 이것도 본 리듀서 전에 써줘야하는듯..!?
  - 요렇게 구성한다면 이제 뷰에서 아래와 같이 더 쉽고 직관적이게 코드를 가져갈 수 있음
  ```swift
  Toggle(
    "Alarm is On",
    isOn: viewStore.$isOnAlarm
  )
  ```
  - 아주아주 편하긴 하다!
  - BindingReducer가 body 내부에서 작동하고 바인딩 액션이 수신되면 상태를 변경
  - BindingReducer는 State와 Action 사이를 바인딩 하는 역할을 가짐
  - 즉, 바인딩 State 요소가 업데이트되면 BindingReducer가 해당 상태값과 액션을 수신하여 Reducer 클로저 내에서 도메인 로직을 처리해 결과를 State에 반영
  - 추가로, 바인딩 시 더 다른 로직을 추가하고 싶다면 아래와 같이 binding 액션 케이스에서 구현해줄 수 있음
  ```swift
  var body: some Reducer<State, Action> {
    BindingReducer()
    
    Reduce { state, action in 
      switch action { 
      case .binding(\.isOnAlarm):
        // 다른 작업 로직!
        
      case .binding(_): break
      }
    }
  }
  ```
***
- ### Binding(get:send:) VS TCA Binding tools
  - 두 바인딩 방식의 어떤 차이가 있을까?
  - BindingState를 사용하면 뷰에서는 원래 익숙한 바닐라 SwiftUI 방식처럼 객체 바인딩을 할 수 있어서 편리함
  - SwiftUI의 바인딩은 양방향으로 BindingState는 데이터 바인딩을 하며 내부 로직 자체는 단방향으로 동작
  - BindingAction을 사용함으로 각 바인딩이 필요한 State 프로퍼티별로 액션을 기존처럼 전부 일일히 하나씩 수동으로 작업하지 않아도됨!
  - 하나의 바인딩 케이스로 대체되는데 이게 너무너무 편해졌다 👍
  - 이제는 단순 필드 값 바인딩을 위한 액션이 불필요하다~
  - 또한 리듀서에서도 해당 액션을 그냥 생략해버려도 됨
  - BindingReducer도 BindingAction 프로토콜을 채택한 액션을 사용함으로써 훨씬 리듀서 자체도 라이트해짐
  - 그냥 너무 편해진거 같은데? 이것도 최신 버전에서는 또 다른 변화가 있나..?
  - 최신 버전에서는 더 줄여서 표현되고 있으니.. 대체 어디까지 줄어들까 이러다 뷰만 남겠는데 다시 🤔
***
- ### View State Binding
  - 각 뷰들은 자신만의 View State를 가질 수 있음 (챕터 3 내용)
  - 스토어 외부에 있는 View State 바인딩을 위해선 ViewState 필드엔 @BindingViewState를 사용해야함
  ```swift
  struct MainView: View {
    let store: StoreOf<Main>
    
    struct ViewState: Equatable {
      @BindingViewState var sendNotification: Bool
    }
    
    var body: some View {
      WithViewStore(
        self.store,
        observe: { bindingViewStore in 
          ViewState(
            sendNotification: bindingViewStore.$sendNotification
          )
        }
      )
    }
  }
  ```
  - 이렇게 사용된다고 하는데 음 왜 쓰지?
  - 코어 단에서 하위 리듀서를 풀백 받아서 처리하는것으로도 될것 같은데 어떤 이점이 있을까!?
  - TCACoordinator 라이브러리를 같이 쓴다면 뭔가 더더욱 쓸일이 없을것 같은데.. 아직 잘 모르겠다~ 🥲
  - 아래와 같이 ViewState 이니셜라이저로 해놓는다면 더 편하게 사용할 수 있음
  ```swift
  struct MainView: View {
    struct ViewState: Equatable {
      @BindingViewState var sendNotification: Bool
      
      init(bindingViewStore: BindingViewStore<Notification.State>) {
        self._sendNotification = bindingViewStore.$sendNotification
      }
    }
    
    var body: some View {
      WithViewStore(self.store, observe: ViewState.init) { viewStore in
        Toggle(
        "Send Notification",
        isOn: viewStore.$sendNotification
        )
      }
    }
  }
  ```
  - 스토어 외부에 있는 ViewState와 바인딩을 할 때 사용된다는건 알겠다~
***
# 소감
- 아직 명확히 이해가 안되는 부분들도 있었지만, 확실하게는 Binding이 너무너무 편해졌다 🥹
- 기존에 binding(get:set:)으로 귀찮고 누락되거나 헷갈려서 고통받는 나날들이 이제는 안녕!