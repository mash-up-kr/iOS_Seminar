# Chap7 MultiStore

## MultiStore

`Reducer`를 특정 작업을 수행하도록 `작게 나눌 수` 있습니다.

1. 자식 state의 부재를 UI에서 우아하게 처리할 수 있습니다.
2. 작게 나눈 자식 Reducer는 독립적으로 작동하고 관리될 수 있습니다.
3. 특정 부분만 업데이트하고 싶을 때 해당 부분의 작은 store를 통해 성능을 최적화 할 수 있습니다.
    
    

## ifLet

- 부모 state의 optional 속성에서 작동하는 자식 reducer를 부모의 도메인에 포함합니다.

부모가 자식 State를 옵셔널로 가지고있는경우 사용가능

## IfLetStore

- 두 가지의 뷰 중 하나를 표시하기 위해 optional 상태의 store를 안전하게 unwrapping 하는 view

removeDuplicates 클로저를 사용하여 State의 `optional 여부에 따라 중복 제거를 수행`하게 됩니다.

---

## forEach

- 부모 도메인에 부모 State의 컬렉션 요소에서 작동하는 자식 Reducer를 포함합니다.

식별된 컬렉션 라이브러리의 IdentifiedArray를 사용

## ForEachStore

- 상태의 배열 또는 컬렉션을 순회하고, 각 항목에 대한 뷰를 생성하는데 사용할 수 있습니다.

removeDuplicates id로 식별

---

## ifCaseLet

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
```

- 부모 열거형 상태의 경우에서 작동하는 자식 Reducer를 부모 도메인에 포함시킵니다.

<aside>
💡 **ifCaseLet 연산자 또한 ifLet과 마찬가지로 정확성을 위해 여러 작업을 수행합니다.**

- 자식 및 부모 기능에 대해 특정 작업 순서를 강제합니다. 자식을 먼저 실행한 다음 부모를 실행합니다. 순서가 뒤바뀌면 부모 기능이 자식 열거형을 변경할 수 있으며 이 경우 자식 기능은 해당 동작에 반응할 수 없습니다. 이로 인해 미묘한 버그가 발생할 수 있습니다.
- 자식 열거형의 변경을 감지하면 모든 자식 효과가 자동으로 취소됩니다.
</aside>

## SwitchStore

- enum 형식의 State를 관찰하고 해당 상태의 각 경우에 대해 CaseLet으로 전환하기 위해 사용합니다.

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
```

- removeDuplicates 클로저는 enum case가 변경될 때만 중복을 제거합니다
