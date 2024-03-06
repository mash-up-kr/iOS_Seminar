# dependency

keyPath로 dependencyValues 타입의 인스턴스를 가져온다.

```swift
private let keyPath: KeyPath<DependencyValues, Value>
```

static 프로퍼티 선언 X

static 프로퍼티는 lazy 하기 때문에, 의존성 주입 후 해당 모듈을 처음으로 사용할 때 capture 된다.

이로 인해 의도하지 않은 동작이 발생할 수 있기 때문에 아래처럼 @Dependency 변수는 static 프로퍼티로 선언되어선 안된다.

[https://pointfreeco.github.io/swift-dependencies/1.0.0/documentation/dependencies/dependencyvalues/](https://pointfreeco.github.io/swift-dependencies/1.0.0/documentation/dependencies/dependencyvalues/)

dependency의 값을 바꾸고 싶다면,

`[withDependencies(_:operation:)](https://pointfreeco.github.io/swift-dependencies/1.0.0/documentation/dependencies/withdependencies(_:operation:)-4uz6m)` 이 메서드를 활용해서 할 수 있다.

```swift
@Dependency(\.date) var date
let now = date.now

withDependencies {
  $0.date.now = Date(timeIntervalSinceReferenceDate: 1234567890)
} operation: {
  @Dependency(\.date.now) var now: Date
  now.timeIntervalSinceReferenceDate  // 1234567890
}
```

실행되는 곳의 lifetime 내에서 dependencies값이 바뀐다.

일반적으로, 실행되는 범위 내에서 값을 바꾼다면 바뀐 값의 영역은 그 내부만 있는다.

만약 비동기 클로저에서 dependency를 캡쳐하면 그 변화된 값이 다른 곳으로 퍼지지 않는다.

하지만, 예외가 있는데 dependencyValues안의 dependencies의 collection에서 @TaskLocal이 있는데 이것은 Task 안에서 비동기 클로저가 있을 때 dependency 값이 바뀌는 것이 다른 곳에도 영향 끼친다.

```swift
withDependencies {
  $0.date.now = Date(timeIntervalSinceReferenceDate: 1234567890)
} operation: {
  @Dependency(\.date.now) var now: Date
  now.timeIntervalSinceReferenceDate  // 1234567890
  Task {
    now.timeIntervalSinceReferenceDate  // 1234567890
  }
}
```

dependency key는 구조체형식으로 해두된다~

Dependency Lifetime에 대해!..

[https://pointfreeco.github.io/swift-dependencies/1.0.0/documentation/dependencies/lifetimes/](https://pointfreeco.github.io/swift-dependencies/1.0.0/documentation/dependencies/lifetimes/)

TaskLocal

tasklocal는 task와 간접적으로 관련 있는 값들이다.

값들이 직접적으로 전달할 필요 없이 application의 모든 부분 내부에 값을 넣어줄 수 있다.

이러면 global한 느낌이 들지만, 3가지 이유로 안전하고 쉽게 쓸 수 있다.

- concurrent 상황에서 안전하게 사용할 수 있다. 이말은, 여러 task들이 race condition 없이 동일한 task local를 접근할 수 있다.
- tasklocal는 오로지 특정된, 정의가 잘된 범위내에서만 변할 수 있다. 모든 부분에서 이를 observe하고 바꿀 수 있는 것이 아니다
- 존재하는 task로부터 바뀐 새 task에 의해 상속될 수 있다?..

예를 들어,

```swift
enum Locals {
  @TaskLocal static var value = 1
}
```

값은 오로지 taskLocal의 withValue안에서만 바꿀 수 있다.

```swift
print(Locals.value)  // 1
Locals.$value.withValue(42) {
  print(Locals.value)  // 42
}
print(Locals.value)  // 1
```

비탈출 클로저의 범위에서만 오로지 값을 바꾸는 것을 허용하고 있다.

```swift
Locals.value = 42
// 🛑 Cannot assign to property: 'value' is a get-only property
```

이렇게 값을 바꾸는 것은 불가능하다.

이래서 안전하고 예측가능한 값을 얻을 수 있다.

하지만 Swift는 밖에서도 바뀐 값을 사용할 수 있도록 툴을 제공하고 있다.

이 툴은, task local 상속으로 어떤 child tasks는 TaskGroup, async let, Task { } 를 생성해서 tasklocal는 상속할 수 있다.

```swift
enum Locals {
  @TaskLocal static var value = 1
}

print(Locals.value)  // 1
Locals.$value.withValue(42) {
  print(Locals.value)  // 42
  Task {
    try await Task.sleep(for: .seconds(1))
    print(Locals.value)  // 42
  }
  print(Locals.value)  // 42
}
```

첫 번째에 바뀐 값을 출력하고

두 번째 Task가 비동기일지라도 값을 그대로 나오고 있다.

이러한 이유는, tasks에서 tasklocal이 상속되기 때문에 값도 상속되어서 받고 있는 것

중요한 사실은, tasklocal는 모든 비동기 상황에서 상속을 하지 않는다.

오로지 Task.init이나 TaskGroup.addTask에서 실행된 비동기 클로저에서만 실행된다.

왜냐하면, 내부 standard library의 특별한 케이스에서만 이를 허용한 것

일반적으로 다른 곳에서는 값을 못 받는다.

```swift
print(Locals.value)  // 1
Locals.$value.withValue(42) {
  print(Locals.value)  // 42
  DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    print(Locals.value)  // 1
  }
  print(Locals.value)  // 42
}
```

### @Dependency lifetime이 어떻게 동작하나?

일반적인 방식에서는 후행클로저에서 값을 바꿀 수 있다.

만약 우리는 특정 상황에서만 사용하는 것을 만들고 싶다면..!

withDependencies를 활용해서 하면 된다(보통 테스트 상황)

```swift
func testOnAppear() async {
  await withDependencies {
    $0.apiClient.fetchUser = { _ in User(id: 42, name: "Blob") }
  } operation: {
    let model = FeatureModel()
    XCTAssertEqual(model.user, nil)
    await model.onAppear()
    XCTAssertEqual(model.user, User(id: 42, name: "Blob"))
  }
}
```

2개의 클로저가 제공되는데,

첫 번째에는 원하는 어떤 dependency를 override할 수 있고 두번째에는 dependency의 값을 바꿀 수 있는 범위 내에서 기능의 로직을 실행할 수 있다.

코드를 보면 직접 api 호출하지 않고 로직을 수행하고 있다.

하지만, 우리는 전체 로직을 후행 클로저에서 다 실행할 필요 없다

필요한 모델에 대해서만 생성해주고 나머지는 밖에서 실행하면 된다.

```swift
func testOnAppear() async {
  let model = withDependencies {
    $0.apiClient.fetchUser = { _ in User(id: 42, name: "Blob") }
  } operation: {
    FeatureModel()
  }

  XCTAssertEqual(model.user, nil)
  await model.onAppear()
  XCTAssertEqual(model.user, User(id: 42, name: "Blob"))
}
```

controlling dependency는 테스트에서만 쓰이는 것이 아니라, 하위 기능에 대해서 제한된 환경을 제공하고 싶을 때도 사용할 수 있고 preview에서도 사용할 수 있다.

으음..잘아는걸까..