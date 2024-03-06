# Chap5 Dependency

Dependency 프로퍼티 래퍼는 다음과 같이 정의되어 있으며, `DependencyValues`에 저장되어 있는 특정 의존성에 키 경로(`KeyPath`)를 통해 접근할 수 있도록 정의된 프로퍼티 래퍼입니다.

```swift
public struct Dependency<Value>: @unchecked Sendable, _HasInitialValues {
	// 앱내에 필요한 의존성이 저장되어있는 DependencyValues 
  let initialValues: DependencyValues
  private let keyPath: KeyPath<DependencyValues, Value>
  private let file: StaticString
  private let fileID: StaticString
  private let line: UInt
```

<aside>
💡 @Dependency 프로퍼티 래퍼의 경우, SwiftUI의 @Environment 프로퍼티 래퍼와 유사한 방식으로 진행됨을 확인할 수 있습니다. EnvironmentKey 와 EnvironmentValues

</aside>

<aside>
💡 **DependencyValue 핵심요소**

- `currentDependency`: 현재 Dependency Key를 통해 사용하고 있는 의존성
- `subscript`: DependencyKey를 통해 storage에 저장된 dependency 탐색 및 접근
- `storage`: DependencyKey를 통해 storage에 의존성 저장
</aside>

```swift
// 현재 의존성
  @TaskLocal static var currentDependency = CurrentDependency()
 
  // DepedencyKey를 통해, 앱에서 사용될 Dependency를 관리하는 storage
  private var storage: [ObjectIdentifier: AnySendable] = [:]

/* DependencyValue를 DependencyKey를 통해, 접근할 수 있도록 구현된 subscript */
  public subscript<Key: TestDependencyKey>(
    key: Key.Type,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
  ) -> Key.Value where Key.Value: Sendable {
```

## Override dependency

런타임시점에 종속성을 변경하는 방법

`withDependencies` 를 통해서 `Dependency`를 `Overriding`할 수 있습니다. 즉, `imageApiClient` 의 프로퍼티인 `var getRandomImageData` 를 테스트에 알맞게 dummy 데이터 또는 mock 데이터를 전송하도록 다음과 같이 코드를 작성할 수 있습니다.

```swift
func testRandomImageData() async {
        let dummyData = Data(count: 0)
        let store = TestStore(initialState: PracticeReducer.State()) {
            PracticeReducer()
        } withDependencies: {
            $0.imageApiClient.getRandomImageData = { dummyData }
        }

        await store.send(.getImageButtonTapped) {
            $0.isRequestingImage = true
        }
        await store.receive(.imageDataResponse(dummyData)) {
            $0.imageData = dummyData
            $0.isRequestingImage = false
        }
    }
```

👉 에러뜨는데 어케하지…?

## Task Local

<aside>
💡 TaskLocal은 동시 컨텍스트에서 사용할 때, `안전성`을 보장합니다.

   - 여러 작업이 경쟁 조건에 대한 걱정 없이 로컬에서 동일한 작업에 액세스할 수 있습니다.

TaskLocal은 정의된 `특정 범위(scope)에서만 변경`할 수 있습니다.

  - 애플리케이션의 모든 부분이 변경 사항을 관찰하는 방식으로 값을 변경하는 것은 허용되지 않습니다.

TaskLocal은 기존 Task에서 생성된 `Task에 의해 상속`됩니다.

</aside>

```swift
enum Locals {
	@TaskLocal static var value = 1
}

print(Locals.value)  // value: 1

Locals.$value.withValue(42) {
	print(Locals.value)  // value: 42

}
print(Locals.value)  // value: 1
```

한편, `@TaskLocal`은 모든 이스케이프 컨텍스트에서 상속되지 않는다는 점에 유의해야 합니다**.** escaping 클로저를 사용하는 `Task.init` 및 `TaskGroup.addTask`에 대해 작동하지만, 일반적으로 scope 범위를 벗어났을 때, `@TaskLocal`에 대한 재정의가 손실됩니다. 

예를 들어 `Task`를 사용하는 대신`DispatchQueue.main.asyncAfter`를 사용한 경우 이스케이프 된 클로저에서 `@TaskLocal` 의 value 값이 다시 1로 결과 값이 출력되는 것을 확인할 수 있습니다.

```swift
print(Locals.value)  // 1

Locals.$value.withValue(42) {
	print(Locals.value)  // 42

	DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
		print(Locals.value)  // 1

	}
	print(Locals.value)  // 42
}
```

`withDependency(_:Operation:)` 를 통해 테스트를 진행할 수 있습니다

아래 코드에서 첫 번째 클로저를 통해 원하는 종속성을 재정의할 수 있고, 두 번째 클로저를 사용하면 재정의된 종속성을 통해 원하는 테스트를 구현할 수 있습니다. 

```swift
func testOnAppear() async {
  await withDependencies {
		// (1) 통제된 테스트를 위해 특정 종속성을 재정의할 수 있는 Scope
    $0.apiClient.fetchUser = { _ in User(id: 42, name: "Blob") }
  } operation: {
		// (2) 종속성이 재정의된 범위안에서 로직테스트를 진행 
    let model = FeatureModel()
    XCTAssertEqual(model.user, nil)
    await model.onAppear()
    XCTAssertEqual(model.user, User(id: 42, name: "Blob"))
  }
}
```

예를 들어 다음과 같은 방법으로 기능 모델을 생성하는 경우:

```swift
let onboardingModel = withDependencies {
  $0.apiClient = .mock
} operation: {
  FeatureModel()
}
```

그러면 `FeatureModel` 내부의 `apiClient` 종속성에 대한 모든 참조는 `mock API 클라이언트`를 사용하게 됩니다. 이는 `FeatureModel`의 `onAppear` 메소드가 작업 클로저 범위 외부에서 호출되는 경우에도 마찬가지입니다.

그러나 상위 모델에서 하위 모델을 생성할 때는 주의가 필요합니다. 자식의 종속성이 부모의 종속성을 상속받으려면 자식 모델을 생성할 때, `withDependency(from:Operation:file:line:)`를 사용해야 합니다.

```swift
let onboardingModel = withDependencies(from: self) {
  $0.apiClient = .mock
} operation: {
  FeatureModel()
}
```

이렇게 하면 `FeatureModel`의 종속성이 상위 기능에 상속되며 원하는 추가 종속성을 재정의할 수 있습니다.