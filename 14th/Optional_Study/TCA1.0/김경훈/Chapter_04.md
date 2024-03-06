# Part 4

@State 관리가 복잡해질 수록 Side Effects를 관리하는 데 어려움이 있다.

SwiftUI 에서는 @State - @Binding을 활용해서 상태 변화를 UI에 즉시 반영해서 코드 작성이 간결하게 한다.

TCA에서는 이러한 문제를 해결하기 위해 TCA Binding를 제공하고 있다.

TCA는 단방향 데이터 흐름을 원칙으로 따르며, Action에 의해 State의 변화를 이룬다.

그리하여, TCA Binding은 SwiftUI Binding처럼 View State 업데이트하고, 동시에 단방향으로 복잡한 State 관리를 수행할 수 있는지 볼 수 있다.

### TCA Binding

가장 기본적인 Binding(get: send:)형태다.

- get: State를 바인딩의 값으로 변환하도록 하는 클로저
- send: 바인딩의 값을 다시 Store에 피드백 하는 Action으로 변환하는 클로저

햅틱피드백의 enable여부를 토글을 활용해서 하는 로직을 구현한다.

```swift
struct Settings: Reducer {
  struct State: Equatable {
    var isHapticFeedbackEnabled = true
    /* code */
  }
	enum Action { 
	  case isHapticFeedbackEnabledChanged(Bool)
    /* code */
	  }
	
	func reduce(
	    into state: inout State, action: Action
	  ) -> Effect<Action> {
	    switch action {
	    case let .isHapticFeedbackEnabledChanged(isEnabled):
	      state.isHapticFeedbackEnabled = isEnabled
	      return .none
	
	    /* code */
	    }
	  }
}
```

이벤트 Action를 받아서 state의 값을 바꿔주고 있다.

View에서 보면,

```swift
struct SettingsView: View {
  let store: StoreOf<Settings>
  
  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      Form {
        Toggle(
          "Haptic feedback",
          isOn: viewStore.binding(
            get: \.isHapticFeedbackEnabled,
            send: { .isHapticFeedbackEnabledChanged($0) }
          )
        )

        /* code */
      }
    }
  }
}
```

Toggle에서 isOn 바인딩 객체를 전달해야하는데

코드를 보면 get에 전달된 객체를 바인딩해서 isOn에 전달해주고,

send에 전달된 Action을 Store에 다시 피드백해서, 해당 Action에서 로직에 따라 State의 값을 변경해주고 있다.

binding의 get를 통해 SwiftUI UI 컨트롤과 바인딩 통신을 하고 send를 통해 Store 내부에 바인딩된 값을 전달함으로써 비즈니스 로직을 수행한다.

이렇게 하면 만약 여러개의 State를 작성해서 할떄 문제점이 있다.

```swift
struct Settings: Reducer {
  struct State: Equatable { /* code */ }

  enum Action {
    case isHapticFeedbackEnabledChanged(Bool)
    case digestChanged(Digest)
    case displayNameChanged(String)
    case enableNotificationsChanged(Bool)
    case protectMyPostsChanged(Bool)
    case sendEmailNotificationsChanged(Bool)
    case sendMobileNotificationsChanged(Bool)
  }

	func reduce(
	    into state: inout State, action: Action
	  ) -> Effect<Action> {
	    switch action {
	    case let .isHapticFeedbackEnabledChanged(isEnabled):
	      state.isHapticFeedbackEnabled = isEnabled
	      return .none
	
	    case let digestChanged(digest):
	      state.digest = digest
	      return .none
	
	    case let displayNameChanged(displayName):
	      state.displayName = displayName
	      return .none
	
	    case let enableNotificationsChanged(isOn):
	      state.enableNotifications = isOn
	      return .none
	
	    case let protectMyPostsChanged(isOn):
	      state.protectMyPosts = isOn
	      return .none
	
	    case let sendEmailNotificationsChanged(isOn):
	      state.sendEmailNotifications = isOn
	      return .none
	
	    case let sendMobileNotificationsChanged(isOn):
	      state.sendMobileNotifications = isOn
	      return .none
	    }
	  }
}
```

위 방식을 사용하면 get, send에 직접 State, Action을 정의하여 전달해야하는 작업이 필요하다.

만약 더 많은 바인딩 코드가 작성되며 Reducer의 관리도 복잡해질 수 있다.

그리하여, 다른 바인딩 툴을 제공하고있따!

## 다양한 TCA의 Binding tools

BindingState, BindingAction, BindingReducer 등이 있다.

개선되는 것을 보면,

```swift
struct Settings: Reducer {
  struct State: Equatable {
		@BindingState var isHapticFeedbackEnabled = true
    @BindingState var digest = Digest.daily
    @BindingState var displayName = ""
    @BindingState var enableNotifications = false
    var isLoading = false
    @BindingState var protectMyPosts = false
    @BindingState var sendEmailNotifications = false
    @BindingState var sendMobileNotifications = false
  }

  /* code */
}
```

State는 각각 동일하게 정의하지만 앞에 @BindingState가 붙게된다.

isLoading은 추가하지 않고 있는데 그 이유로는 View에서 해당 필드 값을 변경할 수 없도록 강제하는 역항을 한다.

TCA에서 모든 필드에 @BindingState 등 바인딩 툴을 사용하는것을 권장하지 않음.

왜냐? 외부에서 즉시 변경이 가능하므로 캡슐화가 손상될 수 있으므로 필요한 곳에만 사용하는 것을 추천한다.

Action에 열거형 BindableAction 프로토콜을 채택함으로써, State의 모든 필드 Action을 하나로 합칠 수 있다.

Action case는 제네릭 타입을 갖는 BindingAction을 associatedValue로 보유한다.

```swift
struct Settings: Reducer {
  struct State: Equatable { /* code */ }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
  }

	var body: some Reducer<State, Action> {
	    BindingReducer()
	  }
	}
}
```

Reducer는 BindingReducer를 사용하여 State를 변경하는 비즈니스 로직을 간단하게 할 수 있다.

BindingReducer는 Binding action이 수신된 경우 State를 업데이트 해주는 reducer다

UI에서도 많은 개선이 이루어 진다.

```swift
Toggle(
    "Haptic feedback",
    isOn: viewStore.$isHapticFeedbackEnabled
  )

	TextField("Display name", text: viewStore.$displayName)
```

직관적으로 State 필드 값을 바인딩하여 쓸 수 있다.

TextField에서도 Action를 정의할 필요 없다.

BindingReducer는 View에서 Binding action이 직접 호출되지 않음에도 불구하고 BindingReducer()는 action을 수신하고 있다.

`BindingReducer()`는 `State`와 `Action` 사이를 `바인딩`하는 역할을 한다.

따라서 Store 내부 바인딩 가능한 State 필드가 업데이트되면, BindingReducer()는 업데이트된 필드 값과 함께 Action을 수신하고 Reducer 클로저 내에서 도메인 로직을 처리하여 결과를 State에 반영한다.

정리하면, 기초적인 바인딩 작업(SwiftUI View 컨트롤러의 바인딩) 외에 추가 기능을 작성해야 하는 경우 기능의 로직을 담당하는 Reduce 클로저 안에 추가 작업에 대한 코드를 작성하면 된다.

```swift
var body: some Reducer<State, Action> {
  BindingReducer()

  Reduce { state, action in
    switch action
    case .binding(\.$displayName):
      // Validate display name
  
    case .binding(\.$enableNotifications):
      // Return an authorization request effect
  
    /* code */
		
		case .binding: break
    }
  }
}
```

### Binding(get:send:) VS TCA Binding tools

UI

```swift
// binding(get:send:)를 사용할 때
  Toggle(
    "Haptic feedback",
    isOn: viewStore.binding(
      get: \.isHapticFeedbackEnabled,
      send: { .isHapticFeedbackEnabledChanged($0) }
    )
  )

// BindingState 프로퍼티 래퍼를 사용할 때
  Toggle(
    "Haptic feedback",
    isOn: viewStore.$isHapticFeedbackEnabled
  )
```

Action

```swift
// binding(get:send:)를 사용할 때
  enum Action {
    case isHapticFeedbackEnabledChanged(Bool)
    case digestChanged(Digest)
    case displayNameChanged(String)
    case enableNotificationsChanged(Bool)
    case protectMyPostsChanged(Bool)
    case sendEmailNotificationsChanged(Bool)
    case sendMobileNotificationsChanged(Bool)
  }

// BindingAction 프로토콜
  enum Action: BindableAction {
    case binding(BindingAction<State>)
  }
```

Reducer

```swift
// binding(get:send:)를 사용할 때
  func reduce(
    into state: inout State, action: Action
  ) -> Effect<Action> {
    switch action {
    case let .isHapticFeedbackEnabledChanged(isEnabled):
      state.isHapticFeedbackEnabled = isEnabled
      return .none

    case let digestChanged(digest):
      state.digest = digest
      return .none

    case let displayNameChanged(displayName):
      state.displayName = displayName
      return .none

    case let enableNotificationsChanged(isOn):
      state.enableNotifications = isOn
      return .none

    case let protectMyPostsChanged(isOn):
      state.protectMyPosts = isOn
      return .none

    case let sendEmailNotificationsChanged(isOn):
      state.sendEmailNotifications = isOn
      return .none

    case let sendMobileNotificationsChanged(isOn):
      state.sendMobileNotifications = isOn
      return .none
    }
  }
}

// BindingReducer를 사용할 때
var body: some Reducer<State, Action> {
  BindingReducer()

  Reduce { state, action in
    switch action
    case .binding(\.$displayName):
			state.isLoading.toggle()
  
    case .binding(\.$enableNotifications):
      // Return an authorization request effect
  
    /* code */
    }
  }
}
```

### View State Binding

개별 View는 각각 View State를 가지고 있을 수 있다. View에도 TCA의 store를 사용한다면 Store의 State와 ViewState의 일부 필드를 바인딩하여 비즈니스 로직에 사용할 수 있다.

Store 외부에 있는 View State를 바인딩 하기 위하여 먼저 View State의 필드에는 @BindingState가 아닌, @BindingViewState 프로퍼티 래퍼를 사용한다.

```swift
struct NotificationSettingsView: View {
  let store: StoreOf<Settings>

  struct ViewState: Equatable {
    @BindingViewState var enableNotifications: Bool
    @BindingViewState var sendEmailNotifications: Bool
    @BindingViewState var sendMobileNotifications: Bool
  }

  /* code */
}
```

ViewStore가 구성되면 init(_:observe:content:file:line:) 이니셜라이저를 호출하고 observe에서 bindingViewStore를 전달받아 ViewState의 필드 값과 바인딩한다.

```swift
struct NotificationSettingsView: View {
  /* code */

  var body: some View {
    WithViewStore(
      self.store,
      observe: { bindingViewStore in
        ViewState(
          enableNotifications: bindingViewStore.$enableNotifications,
          sendEmailNotifications: bindingViewStore.$sendEmailNotifications,
          sendMobileNotifications: bindingViewStore.$sendMobileNotifications
        )
      }
    ) {
      /* code */
    }
  }
}
```

ViewState 구조체에 이니셜라이저를 다음처럼 정의한다면 더 간단하게 Store와 ViewState 바인딩을 할 수 있다.

```swift
struct NotificationSettingsView: View {
  /* code */
  struct ViewState: Equatable {
    /* code */

    init(bindingViewStore: BindingViewStore<Settings.State>) {
      self._enableNotifications = bindingViewStore.$enableNotifications
      self._sendEmailNotifications = bindingViewStore.$sendEmailNotifications
      self._sendMobileNotifications = bindingViewStore.$sendMobileNotifications
    }
  }

  var body: some View {
    WithViewStore(self.store, observe: ViewState.init) { viewStore in
      /* code */
    }
  }
}
```

UI 컨트롤에서 바인딩 객체를 사용할 때에도 다음처럼 사용한다.

```swift
Form {
  Toggle("Enable notifications", isOn: viewStore.$enableNotifications)

  /* code */
}
```