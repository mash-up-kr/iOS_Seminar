# Part 5

의존성에 대한 관리는 앱 개발 전반에 중대한 영향을 미칠 수 있다.

네트워크 같은 경우, SwiftUI에서 Preview를 제공하지만 mock과 같은 별도의 의존성을 처리해주지 않으면 볼 수 없다.

통제되지 못한 애플리케이션내의 의존성으로 발생하는 문제점을 해결하기 위해 TCA Dependency가 나왔다.

TCA Dependency 라이브러리 고려사항

- **애플리케이션의 한 부분에 대한 종속성을 어떻게 재정의 할 수 있을까?**
- **전역 종속성을 갖는 것보다 안전한 방식으로 앱 내에 종속성을 전파할 수 있는 방법은 무엇일까?**
- **테스트에서 기능이 사용하는 모든 종속성을 재정의했는지 어떻게 확인할 수 있나요?**

## ReducerProtocol 이전의 Dependency 관리방식

ReducerProtocol 도입 이전에 State, Action, Environment 3가지 요소가 있었다.

기존의 Environment를 통해 애플리케이션에 필요한 의존성을 관리하는 경우, 만약 해당 리듀서에서 추가적인 의존성이 필요해지는 상황이 발생한다면, 추가해야할 보일러 플레이트 코드가 많다.

예시로,

오픈소스 단어게임..이라는 곳에서 SettingsReducer에서 필요한 apiClient, fileClient와 같이 외부 서버와의 네트워크 통신 및 여러 의존성들을 관리하고 있다.

```swift
struct SettingsEnvironment {
	public var apiClient: ApiClient
	public var fileClient: FileClient
	public var userDefaults: UserDefaultsClient
  public var userNotifications: UserNotificationClient
	/* code */
}
```

추가 의존성을 추가하고 싶다면!

```swift
struct SettingsEnvironment {
	public var apiClient: ApiClient
	public var fileClient: FileClient
	public var userDefaults: UserDefaultsClient
  public var userNotifications: UserNotificationClient
	/* code */
  // 추가된 additionalClient 
	public var additionalClient: AdditionalClient

	init(additionalClient: AdditionalClient, /* code */) {
		  self.additionalClient = AdditionalClient
		}
}
```

init 시점도 바꿔줘야하고, 이것을 사용하는 곳에서도 모두 바꿔줘야한다.

이렇게 불필요한 보일러플레이트 코드가 늘어나게된다.

## ReducerProtocol 도입과 변화된 Dependency 관리 방식

기존의 Environment 방식에서 @Dependency 프로퍼티 래퍼 방식으로 대체하게 되었다.

### @Dependency

```swift
public struct Dependency<Value>: @unchecked Sendable, _HasInitialValues {
	// 앱내에 필요한 의존성이 저장되어있는 DependencyValues 
  let initialValues: DependencyValues
  private let keyPath: KeyPath<DependencyValues, Value>
  private let file: StaticString
  private let fileID: StaticString
  private let line: UInt
```

사용 방법

```swift
// 필수
import Dependencies 

// (1) ObservableObject로 구현된 Model에서 사용하는 방식
struct FeatureModel: ObservableObject {
	@Dependency(\.apiclient) var apiClient
	@Dependency(\.uuid) var uuid
}

// (2) ComposableArchitecture에서 사용하는 방식 
struct Feature: ReducerProtocol {
	@Dependency(\.apiClient) var apiClient
	@Dependency(\.uuid) var uuid
}

// ❌ 잘못된 사용 예시 ❌
// (1) ObservableObject로 구현된 Model에서 사용하는 방식
struct FeatureModel: ObservableObject {
  var apiClient = Dependency(\.apiclient)
  var uuid (\.uuid) = Dependency(\.uuid)
}

// (2) ComposableArchitecture에서 사용하는 방식 
struct Feature: ReducerProtocol {
  var apiClient = Dependency(\.apiclient)
  var uuid (\.uuid) = Dependency(\.uuid)
}
```

ObservableObject로 구현된 Model에서는 프로퍼티래퍼 방식으로만 사용 가능하다.

왜??

이처럼 사용하기 위해선 DependencyValues에 필요한 의존성을 등록하는 과정이 필요하다.

### DependencyKey

DependencyValues에 특정 의존성을 추가/등록하기 위해 DependencyKey 프로토콜이 사용된다.

```swift
public protocol DependencyKey: TestDependencyKey {
	/// ``` 실제 앱 동작 및 시뮬레이터 동작에 사용될 liveValue
  static var liveValue: Value { get }

  associatedtype Value = Self

  /// ``` SwiftUI의 프리뷰를 위한 previewValue
  static var previewValue: Value { get }

  /// ``` Test를 위해 사용될 mock testValue
  static var testValue: Value { get }
}
```

DependencyKey는 liveValue, previewValue, testValue 3가지로 이루어져 있다.

- liveValue: 앱이 실제 기기에서 동작하거나 시뮬레이터 동작할 때 사용하는 dependency value이며 항상 반환해야하는 default value
- previewValue: preview에 사용될 값
- testValue: Test 환경에서 사용될 dependency value

예시로

```swift
struct MyDependencyKey: DependencyKey {
	static let liveValue = "Default value"
}
```

### DependencyValue

DependencyKey를 통해 의존성을 return하며 의존성을 관리하는 역할

```swift
public struct DependencyValues: Sendable {
  @TaskLocal public static var _current = Self()
  #if DEBUG
    @TaskLocal static var isSetting = false
  #endif
  // 현재 의존성
  @TaskLocal static var currentDependency = CurrentDependency()
 
  fileprivate var cachedValues = CachedValues()
  // DepedencyKey를 통해, 앱에서 사용될 Dependency를 관리하는 storage
  private var storage: [ObjectIdentifier: AnySendable] = [:]

  public init() {
    #if canImport(XCTest)
      _ = setUpTestObservers
    #endif
  }

	/* DependencyValue를 DependencyKey를 통해, 접근할 수 있도록 구현된 subscript */
  public subscript<Key: TestDependencyKey>(
    key: Key.Type,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
  ) -> Key.Value where Key.Value: Sendable {
  /* 
	  (1) 커스텀하게 의존성을 등록하고 사용하기위해, 앞서 배운 DependencyKey 정의
     private struct MyDependencyKey: DependencyKey {
				 static let testValue = "Default value"
		  }
		(2) 정의된 DependencyKey값을 통해 아래와 같이, computed-property를 통해 의존성 등록 및 접근
			extension DependencyValues {
			  var myCustomValue: String {
			    get { self[MyDependencyKey.self] }
			    set { self[MyDependencyKey.self] = newValue }
			 }
  */
    get {
      guard let base = self.storage[ObjectIdentifier(key)]?.base,
        let dependency = base as? Key.Value
      else {
        let context =
          self.storage[ObjectIdentifier(DependencyContextKey.self)]?.base as? DependencyContext
          ?? defaultContext

        switch context {
        case .live, .preview:
          return self.cachedValues.value(
            for: Key.self,
            context: context,
            file: file,
            function: function,
            line: line
          )
        case .test:
          var currentDependency = Self.currentDependency
          currentDependency.name = function
          return Self.$currentDependency.withValue(currentDependency) {
            self.cachedValues.value(
              for: Key.self,
              context: context,
              file: file,
              function: function,
              line: line
            )
          }
        }
      }
      return dependency
    }
    set {
      self.storage[ObjectIdentifier(key)] = AnySendable(newValue)
    }
  }

  public static var live: Self {
    var values = Self()
    values.context = .live
    return values
  }

  /// A collection of "preview" dependencies.
  public static var preview: Self {
    var values = Self()
    values.context = .preview
    return values
  }

  /// A collection of "test" dependencies.
  public static var test: Self {
    var values = Self()
    values.context = .test
    return values
  }

  func merging(_ other: Self) -> Self {
    var values = self
    values.storage.merge(other.storage, uniquingKeysWith: { $1 })
    return values
  }
}
```

- currentDependency
    - 현재 Dependency Key를 통해 사용하고 있는 의존성
- subscript
    - DependencyKey를 통해 storage에 저장된 dependency 탐색 및 접근
- storage
    - DependencyKey를 통해 storage에 의존성 저장

### @Dependency 적용하기

DependencyKey를 통해 DependencyValue에 의존성 추가하는 법

적용 예시

UserDefault를 통해 값을 저장, 삭제, 찾는 역할 수행하는 UserDefaultClient 생성하고 프로퍼티래퍼로 접근할 수 있도록 의존성을 등록한다

```swift
// ✅ "import Dependencies" 과정은 필수!
// 물론 "import ComposableArchitecture"를 통해 대체될 수 있음
import Dependencies

public struct UserDefaultsClient {
  public var boolForKey: @Sendable (String) -> Bool
  public var dataForKey: @Sendable (String) -> Data?
  public var doubleForKey: @Sendable (String) -> Double
  public var integerForKey: @Sendable (String) -> Int
  public var remove: @Sendable (String) async -> Void
  public var setBool: @Sendable (Bool, String) async -> Void
  public var setData: @Sendable (Data?, String) async -> Void
  public var setDouble: @Sendable (Double, String) async -> Void
  public var setInteger: @Sendable (Int, String) async -> Void
 /* code */
}
```

DependencyValues를 커스텀하게 구현하기 위해 DependencyKey 프로토콜을 준수하고 코드를 추가적으로 작성한다.

해당하는 유저디폴트에 여러 타입을 대응해주고, set에서도 여러 타입 대응해주고있다.

```swift
extension UserDefaultsClient: DependencyKey {
  public static let liveValue: Self = {
    let defaults = { UserDefaults(suiteName: "group.isowords")! }
    return Self(
      boolForKey: { defaults().bool(forKey: $0) },
      dataForKey: { defaults().data(forKey: $0) },
      doubleForKey: { defaults().double(forKey: $0) },
      integerForKey: { defaults().integer(forKey: $0) },
      remove: { defaults().removeObject(forKey: $0) },
      setBool: { defaults().set($0, forKey: $1) },
      setData: { defaults().set($0, forKey: $1) },
      setDouble: { defaults().set($0, forKey: $1) },
      setInteger: { defaults().set($0, forKey: $1) }
    )
  }()
}
```

이제 내부 동작이 구현되었다면 DependencyKey 프로토콜을 따르는 UserDefaultsClient를 key 값으로 불러오거나 새로운 값으로 변경할 수 있는 연산프로퍼티 형태로 의존성을 생성한다.

```swift
extension DependencyValues {
  public var userDefaults: UserDefaultsClient {
    get { self[UserDefaultsClient.self] }
    set { self[UserDefaultsClient.self] = newValue }
  }
}
```

### Overriding Dependency

application의 특정 부분에서 다른 종속성을 사용할 수 있도록 런타임 시점에 종속성을 변경하는 방법

보통 xcode내의 preview 기능을 위해 사용한다.

TCA에서의 적용예시 / ObservableObject에서의 적용예시

**TCA와 Overriding Dependency**

Image Data를 가져오는 방식

```swift
struct ImageApiClient {
	  // 임의의 Image Data를 얻어오는 Api요청을 담당할 프로퍼티
    var getRandomImage: () async throws -> Data
}
```

전역적으로 Dependency 관리하고 사용하기 위해 등록한다.

```swift
extension ImageApiClient: DependencyKey {
    static var liveValue = ImageApiClient(
      getRandomImageData: {
        let urlString = "<https://picsum.photos/200/300>"
        guard let url = URL(string: urlString)
        else { throw URLError(.badURL) }

        if let data = try? Data(contentsOf: url) {
          return data
        }
        throw URLError(.badServerResponse)
      }
    )
}

extension DependencyValues {
    var imageApiClient: Self {
        get { self[ImageApiClient.self] }
        set { self[ImageApiClient.self] = newValue }
    }
}
```

사용

```swift
struct PracticeReducer: Reducer {
    struct State: Equatable {
        var imageData: Data
        var isRequestingImage = false
    }

    enum Action: Equatable {
        case getImageButtonTapped
        case imageDataResponse(Data)
    }

    @Dependency(\.imageApiClient) var imageApiClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .getImageButtonTapped:
          state.isRequestingImage = true
          return .run { send in
            let imageData = try await imageApiClient.getRandomImageData()
            await send(.imageDataResponse(imageData))
          }

        case .imageDataResponse(let newImageData):
          state.isRequestingImage = false
          state.imageData = newImageData
            return .none
        }
    }
}
```

실제 네트워크 통신을 사용하는 게 아니라 mock 데이터로 테스트 하고 싶다면..!

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

**ObservableObject와 Overriding Dependency**

ObservableObject로 구현된 특정 Model에서 Dependency Overriding이 어떻게 적용 될지?

온보딩 과정에서 사용자 작업으로 데이터가 기록되거나 변경되는 것을 적절하지 못하다.

그래서 해당 종속성의 Mock 버전을 사용하는 것이 좋다.

기존 객체에서 종속성을 상속하고, 해당 종속성 중 일부를 추가로 재정의할 수 있는 withDependency(from:_:Operation:file:line:) 메서드를 사용해야 한다.

```swift
final class AppModel: ObservableObject {
  @Published var onboardingTodos: TodosModel?

  func tutorialButtonTapped() {
    self.onboardingTodos = withDependencies(from: self) {
      $0.apiClient = .mock
      $0.fileManager = .mock
      $0.userDefaults = .mock
    } operation: {
      TodosModel()
    }
  }
}
```

TodosModel은 상위 AppModel과 같은 종속성을 모두 갖는 환경으로 구성되었으며 apiClient, fileManager, userDefaults는 제어할 수 있는 방식으로 재정의되어 실제 네트워크 및 side efffect를 일으키지 않는다.

또 다른 주의사항으로는, 새로운 종속성이 자식 모델, 자식의 자식 모델 등으로 전파되도록 의존성을 재정의할 때는 특별한 주의가 필요하다.

생성된 모든 하위 모델은`withDependency(from:Operation:file:line:)` 호출 내에서 수행되어야 하위 모델이 상위 모델이 사용하는 정확한 종속성을 선택할 수 있다.

예를 들면,

```swift
final class TodosModel: ObservableObject {
  @Published var todos: [Todo] = []
  @Published var editTodo: EditTodoModel?

  @Dependency(\.apiClient) var apiClient
  @Dependency(\.fileManager) var fileManager
  @Dependency(\.userDefaults) var userDefaults

  func tappedTodo(_ todo: Todo) {
    self.editTodo = EditTodoModel(todo: todo)
  }
}
```

특정 할일 수정하기 위해 편집 화면으로 이동한다면, tappedTodo 실행했을 때 EditTodoModel을 생성시키도록 옵셔널 프로퍼티를 사용하여 모델링 할 수 있다.

하지만, tappedTodo 메서드 내에서 EditTodoModel을 할당할 때 종속성을 다시 liveValue로 돌아가게 된다.

그래서 재정의된 것을 하위모델에 계속 전파하려면

withDependencies(from:operation:file:line:)을 사용하여 하위 모델 생성 시, 래핑해야 한다.

```swift
func tappedTodo(_ todo: Todo) {
  self.editTodo = withDependencies(from: self) {
    EditTodoModel(todo: todo)
  }
}
```

### DependencyLifeTime

Dependency 프로퍼티 래퍼가 생성될때 상태를 캡쳐하게된다. 전역으로 가지고 있으므로 Static → lazy하기 때문에 호출하는 그 시점에 상태를 캡쳐한 것

이러한 방식은 @TaskLocal 값이 새로운 비동기 작업에 의해 상속되는 방식과 유사하다.

@TaskLocal은 애플리케이션의 모든 곳에 값들을 전달하는 것을 가능하게 만들어주는 역할을 한다.

- 동시 컨텍스트에서 사용할 때 안정성을 보장
    - 여러 작업이 경쟁 조건에 대한 걱정 없이 로컬에서 동일한 작업에 액세스 가능
- 특정 범위에서만 변경 가능
    - 모든 부분이 변경사항을 관찰하는 방식으로 값을 변경하는 것을 허용하지 않음
- 기존 Task에서 생성된 Task에 의해 상속된다.

예를 들어,

```swift
enum Locals {
	@TaskLocal static var value = 1
}
```

@TaskLocal 프로퍼티 래퍼로 선언된 Value는 오로지 withValue 메서드를 통해서만 값의 변화를 적용할 수 있고, escaping 되지 않는 클로저 범위에 대해서만 값 변경 허용

```swift
print(Locals.value)  // value: 1

Locals.$value.withValue(42) {
	print(Locals.value)  // value: 42

}
print(Locals.value)  // value: 1
```

Locals.value가 withValue 클로저 범위에 한하여 변경된 값을 보여주고 있다.

제한적일 수 있지만, 보다 안전하고 값을 추론하기 쉽도록 만들어져있다(예상되는 결과)

```swift
Locals.value = 42
// 직접 @TaskLocal로 선언된 value 값에 접근하여 값을 변경하는 것은 허용되지 않는다.
```

이렇게 변경 허용X

만약 값 접근해서 바꿀 수 있으면 print의 위치에 따라 결과값이 다를 수 있다.

결과 예측이 어렵기 때문에 특정한 범위내에서인 @TaskLocal에서 값을 변경할 수 있게 한다.

한편 비탈출 클로저 범위 밖에서도 변경된 값 유지할 수 있도록 하기 위해

TaskGroup OR async let를 통해 생성된 모든 하위 작업과 Task { } 로 생성된 작업은 생성된 순간에 @TaskLocal을 상속한다.

예를들어,

1초 후에 Task에서 엑세스할 때에도 그 클로저가 탈출인 경우에도 @TaskLocal이 재정의된 상태로 유지되는 것을 확인할 수 있다.

```swift
enum Locals {
	@TaskLocal static var value = 1
}

print(Locals.value)  // 1

Locals.$value.withValue(42) {
	print(Locals.value)  // 42

	Task {
		try await Task.sleep(for: .seconds(1))
		print(Locals.value)  // 42
	}

	print(Locals.value)  // 42
}
```

Task에 전달된 클로저가 이스케이프 되고 withValue의 범위가 종료된 후에, print문이 실행되더라도 여전히 변화된 값인 "42" 값이 출력됨을 확인할 수 있다. 이는 @TaskLocal이 Task에 상속되기 때문에 발생한다.

한편, `@TaskLocal`은 모든 escape context에서 상속되지 않는다는 점에 유의해야 한다.

escaping 클로저를 사용하는 `Task.init` 및 `TaskGroup.addTask`에 대해 작동하지만, 일반적으로 scope 범위를 벗어났을 때, `@TaskLocal`에 대한 재정의가 손실된다.

예를 들어 `Task`를 사용하는 대신`DispatchQueue.main.asyncAfter`를 사용한 경우 이스케이프 된 클로저에서 `@TaskLocal` 의 value 값이 다시 1로 결과 값이 출력되는 것을 확인할 수 있다.

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

결론적으로 Swift는 `@TaskLocal`을 특정 이스케이프, 구조화되지 않은 컨텍스트로 전파하기 위해 추가 작업을 수행하지만, 위와 같은 엣지 케이스가 존재한다는 점을 인지해야 한다.

이제 `@TaskLocal`의 작동 방식에 대해 이해했으므로 `@Dependency` 수명의 작동 방식과 확장 방법을 이해할 수 있다.

내부적으로 종속성은 `@TaskLocal`로 유지되며 `@TaskLocal`의 많은 규칙도 종속성에 적용된다.

종속성은 `Task`에서 상속되지만, 일반적으로 이스케이프 경계를 넘어 상속되지는 않는다.

`@TaskLocal`과 마찬가지로 종속성 값은 `withDependency(_:Operation:)`의 후행 non-escaping 클로저 범위에 대해 한정적으로 변경될 수 있지만, 라이브러리에는 잘 정의된 방식으로 변경 상태를 유지하기 위한 몇 가지 방법도 구현되어 있다.

예를 들어 사용자를 가져오기 위해 API 클라이언트에 접근해야 하는 기능이 있다는 상황에서,

```swift
class FeatureModel: ObservableObject {

	@Dependency(\\.apiClient) var apiClient

	func onAppear() async {
		do {
			self.user = try await self.apiClient.fetchUser()
		} catch {
			/* code */
		}
	}
}

```

`apiClient`의 다른 구현을 사용하는 통제된 환경에서 이 모델을 구성하고 싶을 수 있다.

테스트 환경에서 실제로 호출되는 네트워크 요청을 만들고 싶지 않다. 왜냐하면, 테스트를 위해 통제할 수 없는 여러 케이스가 존재하기 때문이다. 대신, 데이터가 코드 상의 로직을 통해 어떻게 처리되는지 테스트할 수 있도록 일부 데이터를 즉시 반환하는 `apiClient`의 구현을 제공하고자 한다.

이를 수행하기 위해,`withDependency(_:Operation:)` 를 통해 테스트를 진행할 수 있다.

아래 코드에서 첫 번째 클로저를 통해 원하는 종속성을 재정의할 수 있고, 두 번째 클로저를 사용하면 재정의된 종속성을 통해 원하는 테스트를 구현할 수 있다.

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

`withDependency(_:Operation:)`의 후행 클로저에서 실행되는 모든 코드는 재정의된 `fetchUser` 엔드포인트를 사용하므로 실제 네트워크 요청 없이, 해당 코드 로직을 테스트할 수 있다.

물론, 위의 예시 코드처럼 후행 작업 클로저 범위에서 모든 테스트를 실행할 필요는 없다.

해당 범위에서 모델만 구성하면 되며, 모든 종속성이 `FeatureModel`에 인스턴스 변수로 선언된 모델과의 모든 상호 작용은 작업 클로저 외부에서도 재정의된 종속성을 사용한다.

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

예를 들어 다음과 같은 방법으로 기능 모델을 생성하는 경우:

```swift
let onboardingModel = withDependencies {
  $0.apiClient = .mock
} operation: {
  FeatureModel()
}

```

그러면 `FeatureModel` 내부의 `apiClient` 종속성에 대한 모든 참조는 `mock API 클라이언트`를 사용하게 된다. 이는 `FeatureModel`의 `onAppear` 메소드가 작업 클로저 범위 외부에서 호출되는 경우에도 동일하다.

그러나 상위 모델에서 하위 모델을 생성할 때는 주의가 필요!!

자식의 종속성이 부모의 종속성을 상속받으려면 자식 모델을 생성할 때, `withDependency(from:Operation:file:line:)`를 사용해야 한다.

```swift
let onboardingModel = withDependencies(from: self) {
  $0.apiClient = .mock
} operation: {
  FeatureModel()
}

```

이렇게 하면 `FeatureModel`의 종속성이 상위 기능에 상속되며 원하는 추가 종속성을 재정의할 수 있다.