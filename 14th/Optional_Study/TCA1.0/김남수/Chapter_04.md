# Chap 4 TCA Binding

## TCA Binding

State 변화는 Action을 전송하고 Reducer가 이를 수신하여 로직을 처리합니다

간단한 State 변화에 비해 코드가 복잡하며, 각 State 변화에 대해 Action을 정의하고 Reducer에서 이를 처리하는 로직을 작성해야 합니다.

```swift
Toggle(
    "Haptic feedback",
    isOn: viewStore.binding(
        get: \.isHapticFeedbackEnabled, // state
        send: { .isHapticFeedbackEnabledChanged($0) } // action
    )
)
```

코드가 길어지고 복잡하면 가독성이 나빠지고 반복적인 작업이 필요합니다. 따라서 TCA는 reducer와 View에 이러한 불필요한 작업이 반복되지 않도록 하고 `간단하게 바인딩 관리할 수 있는 환경`을 제공합니다.

`BindingState`, `BindingAction`, `BindingReducer`

// 아니 이거 왜공부한거야 다사라지는것들이엿네 ~ iOS17+

### BindingState

선언시 프로퍼티래퍼 $ 바인딩 변수생김

```swift
struct State: Equatable {
    @BindingState var isOn: Bool = false
}
```

### BindableAction

State필드의 모든 필드 Action을 하나의 case로 축소

```swift
enum Action: BindableAction {
// 정의는 하나로하고 필요한 바인딩은 꺼내쓸 수 있음
    case binding(BindingAction<State>)
}
```

### BindingReducer

Binding action 수신된경우 State를 업데이트해줌

```swift
var body: some ReducerOf<Self> {
//  BindableAction사용시 
    BindingReducer()
    Reduce { state, action in 
        ...
    }
}
```

<aside>
💡 이렇게 하면 바인딩의 로직이 기능의 로직보다 먼저 실행되므로 바인딩이 작성된 이후의 상태만 볼 수 있습니다. 바인딩이 작성되기 전의 상태에 반응하고 싶다면 컴포지션의 순서를 뒤집을 수 있습니다:

</aside>

![Untitled](Chap%204%20TCA%20Binding%20c0c655f1314b4bd99f14798948772dc3/Untitled.png)

### 예시

```swift
var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
        switch action {
        case .binding(\.$isOn):
            print(state.isOn)
            return .none
// 이떄 디폴트 case위치 중요함 위아래가 다르면 case 실행이 다르게될수잇음
        case .binding:
            print("not thing")
            return .none
        }
    }
}
```

### BindingViewState

Store외부에있는 View State를 바인딩하기위함

sorce of truth를 위한 정의

> BindingViewState 언제쓰지..?
> 

뷰내부에 정의

WithViewStore 정의시 생성

뷰에서 Store값에 접근하지않고 ViewState값에 접근해서 사용함

```swift
struct TestTCAView: View {
    let store: StoreOf<TestTCAReducer>
    
    struct ViewState: Equatable {
        @BindingViewState var isHidden: Bool
    }
    
    var body: some View {
        WithViewStore(store, observe: { store in
            ViewState(isHidden: store.$isOn)
        }) { viewStore in
            VStack {
                Toggle("토글", isOn: viewStore.$isHidden)
            }
        }
    }
}
```

→ store를 정의해서 ViewState로 전달함 → 2번 정의하는거아닌가??

→ subview를 나누고싶을떄 유용할듯

→ 뷰를 관리하기위한 리듀서를 또만들지않아도됌 

→ 이벤트도 받을 수 있음

reducer에 이벤트는 그대로 똑같이 들어옴 

### 예시

```swift
struct TestTCAView: View {
    let store: StoreOf<TestTCAReducer>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                ToggleView(store: store)
            }
        }
    }
}

struct ToggleView: View {
    let store: StoreOf<TestTCAReducer>

    struct ViewState: Equatable {
        @BindingViewState var isHidden: Bool
        
        init(store: BindingViewStore<TestTCAReducer.State>) {
            self._isHidden = store.$isOn
        }
    }
    
    var body: some View {
        WithViewStore(self.store, observe: ViewState.init) { viewStore in
            Toggle("토글", isOn: viewStore.$isHidden)
        }
    }
}
```

이런 뷰를 구성하는거보다…아래가 편한데…?

```swift
struct TestTCAView: View {
    let store: StoreOf<TestTCAReducer>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
//                ToggleView(store: store)
                ToggleView2(isOn: viewStore.$isOn)
            }
        }
    }
}

struct ToggleView2: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle("토글", isOn: $isOn)
    }
}
```

이게더 간편한데 굳이왜 쓸까..?

부모쪽에서 그대로 이벤트도 받을 수 있음

~~→ WithViewStore를 통한 액션이 가능하다!~~ 똑같다 ~!