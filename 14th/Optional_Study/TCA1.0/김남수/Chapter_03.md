# Chap3 TCA 기본개념2

## Effect

- none - 아무동작없음
- send - 액션이후 추가적인 동기액션필요시, 자식컴포넌트 → 부모컴포넌트 데이터전달시 사용
공식 문서 상에서 로직을 **공유하기 위한 목적으로 사용하지 말라고 권장**하고 있습니다. 즉, 여러 곳에서 동일한 로직을 사용하기 위해 `.send` 메서드를 사용하지 말라
- run - 비동기 작업 래핑
- merge - Effect 동시에 실행
- concatenate - 순서있는 Effect묶음

### Scope

state - 상태추출할 key path

action - 액셕추출할 key path

`scope`는 전체 앱 상태에서 `해당 도메인의 상태와 액션만을 추출`한 작은 범위의 Store를 반환하게 됩니다. 이렇게 함으로 각 View는 필요한 상태와 액션에만 접근할 수 있게 되어 `모듈화`와 코드의 `유연성`에 도움이 됩니다. 

### ViewStore

Store가 앱의 상태 변화를 관리

`ViewStore` 는 `View에 필요한 상태만`을 구독하고 업데이트하는 역할을 수행합니다

 View가 필요로하지 않는 상태의 변경에 따른 불필요한 View 업데이트를 방지합니다. 

`Store`가 있는데 왜 `ViewStore`가 또 필요한지 ?

자식 View에서 액션을 받으면 이를 부모 스토어에 전달하고 그 액션을 받은 부모 스토어는 자체 리듀서를 호출하여 내부 상태를 업데이트하게 되는데, 만약 이 행동이 이루어지는 동안에 부모 스토어보다 상위의 스토어에서 View을 렌더링하라는 요청이 오게 되면 View를 여러 번 렌더링 해야 하는 상황이 발생

변화의 중복을 방지하는 기능을 탑재한 `ViewStore`를 만들게 된 것

> viewStore.(state) 바로 접근가능한 이유?
> 

### WithViewStore

`WithViewStore`는 `Store`를 View 빌더에서 사용할 수 있는 `ViewStore`로 변환해 주는 조력자입니다.

`WithViewStore`가 감싸고 있는 View가 복잡하면 복잡할수록 컴파일러의 성능이 저하

이를 방지하기위해 두가지 방법권고함

```swift
// 방법 1. 타입을 명시해서 컴파일러의 연산을 줄여준다.
// 이외는 기존의 방식과 동일.
WithViewStore(self.store, observe: { $0 }) { viewStore: ViewStoreOf<CounterFeature> in
		// 복잡한 View를 아래에 추가하면 됩니다.
		/* code */
}

// 방법 2. 이니셜라이저를 통해 Store를 주입받고, 그 안에서 ViewStore를 생성한다.
// View 계층을 줄여준다는 장점이 있다.
let store: StoreOf<CounterFeature>
    @ObservedObject var viewStore: ViewStoreOf<CounterFeature>

    init(store: StoreOf<CounterFeature>) {
      self.store = store
      self.viewStore = ViewStore(self.store, observe: { $0 })
}
```

`Store`는 `참조 타입`이며 Thread-Safe 하지 않다고 나와있습니다

*락이나 *큐를 도입할 수는 있겠지만, 이는 새로운 복잡성을 도입하고 예기치 못한 Side Effect를 낳을 수도 있습니다. 이러한 이유들로 인해 Store는 Thread-safe 하지 않고 따라서 모든 액션은 동일한 스레드에서 보내야 합니다.