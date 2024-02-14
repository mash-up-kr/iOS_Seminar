# TCA 1.0 스터디 (Dependency)
# 챕터 자료
- https://axiomatic-fuschia-666.notion.site/Chapter-5-Dependency-de90da4e19554625af3ffc005ab13ed9
***
#  스터디 내용
- ### TCA & Dependency
  - Dependency는 의존성이라는 뜻
  - 네트워크 통신, 파일 액세스, 타이머 등 사이드 이펙트를 일으키는 요소들은 모두 Dependency로 볼 수 있음
  - TCA Dependency는 개발에 있어 의존성을 쉽게 관리할 수 있도록 도움을 주는 의존성 관리 라이브러리
  - 해당 라이브러리를 만들때 아래와 같은 사항들이 고려되었다고 함
    - 전역 종속성보다 안전한 방식으로 앱 내 종속성 전파, 즉 의존성 주입을 하는 방법
    - 앱의 특정 한 부분에 대한 종속성의 재정의
    - 테스트 시 기능이 사용하는 종속성들의 재정의 확인
***
- ### ReducerProtocol 이전의 Dependency 관리 방식
  - Environment라는 구조체에서 의존성 관리가 이뤄졌음
  - 다른 의존성들을 주입하여 확장을 할 때, 많은 코드 형식의 추가가 필요했음
  - 실제로 의존성 주입을 통해 상위에서 하위 코어단으로 흐르기에, 가장 하위에 있는 의존성을 주입할때도 거기서 생성할 수도 있겠지만, 주입 방식으로 흘러 내려온다면 전부 사용하지 않더라도 최상위 Environment에서 생성하여 주입해주는 방식으로도 사용되기에 여간 번거로운 작업이였음 🥲
  ```swift
  struct SettingEnvironment {
    public var apiManager: APIManager
    public var fileManager: FileManager
    
    init(
      apiManager: APIManager,
      fileManager: FileManager
    ) {
      self.apiManager = apiManager
      self.fileManager = fileManager
    }
  }
  ```
  - 위와 같이 Environment가 정의되고 초기화 되기에 만약 새로 의존성을 추가해야한다면, 선언부터 초기화까지 수정해야하며 상위에서 주입 받을 경우에는 상위에서도 선언하고 추가해야했음
  - 이런 구현 자체를 놓치게되면 당연히 컴파일 에러가 발생하게 되고 많이 엮여있다면 일일히 수정해야하는 뎁스가 점차 늘어나는 단점이 있음
***
- ### ReducerProtocol 이후의 Dependency 관리 방식
  - TCA 0.41.0 버전의 도입에서 ReducerProtocol 도입과 함께 Dependency 라이브러리가 추가됨
  
  - @Dependency 프로퍼티 래퍼 방식으로 대체됨
  
  - @Dependency
	  ```swift
    public struct Dependency<Value>: @unchecked Sendable, _HasInitialValues {
      // 앱내에 필요한 의존성이 저장되어있는 DependencyValues 
      let initialValues: DependencyValues
      private let keyPath: KeyPath<DependencyValues, Value>
      private let file: StaticString
      private let fileID: StaticString
      private let line: UInt
    }
    ```
    - 위와 같이 @Dependency 프로퍼티 래퍼가 정의되어 있음
    - DependencyValues에 저장된 특정 의존성에 키패스를 통해 접근할 수 있도록 정의됨
    - @Environment 프로퍼티 래퍼와 아주 유사한 방식
    ```swift
    import Dependencies
    
    struct Feature: ReducerProtocol {
      struct State { ... }
      enum Action { ... }
      @Dependency(\.apiManager) var apiManager
    }
    ```
    - 위와 같이 사용할 수 있음
    - 직접 생성자를 호출하여 생성하면 안되고 키패스를 전달하는 방식으로 사용해야함
    
  - DependencyKey
    - DependencyValues에 특정 의존성을 추가/등록하기 위해서 DependencyKey 프로토콜 사용
    ```swift
    public protocol DependencyKey: TestDependencyKey {
      /// 실제 앱 동작에 사용될 값
      static var liveValue: Value { get }
      
      associatedtype Value = Self
      
      /// 프리뷰를 위한 값
      static var previewValue: Value { get }
      
      /// Test를 위해 사용될 mock 값
      static var testValue: Value { get }
    }
    ```
    - DependencyKey 프로토콜은 위처럼 3개로 구분할 수 있음
    - 여기서 liveValue는 필수적으로 반환해야함
    ```swift
    struct FeatureDependencyKey: DependencyKey {
      static let liveValue = "Default value"
    }
    ```
    - 위와 같은 예시로 적용할 수 있다고 함
    - 여기선 실제 어떻게 사용할지 감이 안올 수 있긴하지만 아래에서 더 자세히 흐름을 알아보자!
    
  - DependencyValue
    - DependencyKey를 통해 value와 의존성에 접근하기 위한 키 값을 생성할 수 있었음
    - DependencyValue는 DependencyKey를 통해서 의존성을 반환하며 의존성을 관리하는 역할
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
    - 위와 같이 DependencyValue가 구현되어 있음
    - currentDependency가 현재 Dependency Key를 사용하고 있는 의존성
    - subscript는 DependencyKey를 통해 storage에 저장된 디펜던시 탐색 및 접근하는 역할
    - storage는 DependencyKey를 통해 의존성을 저장하는 장소
    - 이를 통해 종속성이 필요한 코드 어디서든 등록된 종속성에 즉시 접근이 가능!
    
  - @Dependency 적용하기
    ```swift
    // 의존성 구현
    import Dependency
    
    struct NumberFactClient {
      var fetch: (Int) async throws -> String
    }
    
    extension NumberFactClient: DependencyKey {
      static let liveValue = Self { 
        fetch: { number in 
          let (data, _) = try await URLSession.shared
            .data(from: .init(string: "http://numbersapi.com/\(number)")!)
          return String(decoding: data, as: UTF8.self)
        }
      }
    }
    
    extension DependencyValues {
      var numberFact: NumberFactClient {
        get { self[NumberFactClient.self] }
        set { self[NumberFactClient.self] = newValue }
      }
    }
    
    // Core 구현
    import ComposableArchitecture
    
    struct Feature: Reducer {
      struct State { ... }
      enum Action { ... }
      @Dependency(\.numberFact) var numberFact
      
      func reduce(into: state: inout State, aciton: Action) -> Effect<Action> { 
        switch action {
        case .getNumber:
          return .run { send in 
            let num = try await numberFact.fetch(3)
            await send(.updateNum(num))
          }
        
        case let .updateNum(num):
          state.num = num
          return .none
        }
      }
    }
    ```
    - 위와 같이 활용할 수 있음
    - 또한, 테스트 환경 구축 시 TestStore를 만들때 live하지 않은 fetch 구현을 정의함으로 더욱 편리해짐
    ```swift
    let store = TestStore(
      initialState: Feature.State(),
      reducer: Feature()
    ) { 
      $0.numberFact.fetch = { "\($0) is a good number" }
    }
    ```
***
- ### TCA & Overriding Dependency
  - 전체 종속성이 아닌 앱의 특정 부분에서 다른 종속성을 사용하도록 런타임 시점에 종속성을 변경하는 방법을 소개함
  - 주로, 테스트 및 프리뷰 기능에서 적용될때 많이 사용
  ```swift
  func testNumberFact() async {
    let dummy = 3
    let store = TestStore(initialState: Feature: State()) {
      Feature()
    } withDependecies: {
      $0.numberFact.fetch = { dummy }
    }
    
    await store.receive(.updateNum(dummy)) {
      $0.num = dummy
    }
  }
  ```
  - 이런식으로 테스트 목 데이터를 활용하고 withDependencies를 이용하여, 디펜던시를 오버라이딩해 사용할 수 있음
***
- ### ObservableObejct & Overriding Dependency
  - TCA로의 구현이 아닌 ObservableObject를 사용할 시에도 Dependency를 사용할 수 있고 마찬가지로 오버라이딩 할 수 있음
  ```swift
  class AppModel: ObservableObject {
    @Published var todos: TodosModel?
    
    func buttonTapped() {
      self.todos = withDependencies(from: self) {
        $0.apiClient = .mock
      } operation: {
        TodosModel()
      }
    }
  }
  ```
  - 이런식으로 목 객체를 사용하여 오버라이딩할 수 있음
  - 새로운 종속성이 하위 모델로 전파되도록 의존성을 재정의 할 때는 주의해야함
    - 생성된 하위 모델이 withDependency 호출 내에서 수행되어야 하위에서 상위 모델에서 사용하는 종속성을 선택할 수 있음
  - 즉, 재정의된 종속성이 하위 모델에도 계속 전파되도록 하려면 하위에서도 withDependencies를 사용해야함
  ```swift
  class TodosModel: ObservableObject {
    ...
    
    func tappedTodo(_ todo: Todo) {
      // 아래처럼 하면 liveValue를 사용하게됨
      self.editTodo = EditTodoModel(todo: todo)
      // 아래처럼 사용하여 전파되도록 이용할 수 있음
      self.editTodo = withDependencies(from: self) {
        EditTodoModel(todo: todo)
      }
    }
  }
  ```
***
- ### DependencyLifeTime
  - @Dependency의 LifeTime에 대해 알아보는 섹션!
  - 디펜던시 프로퍼티 래퍼가 생성 될 초기에 디펜던시 상태를 캡처하는것이 가장 우선으로 일어남
  - @TaskLocal 값이 새로운 비동기 작업에 의해 상속되는 방식과 비슷한 범위 지정 매커니즘이 제공됨
  - @TaskLocal?
    - 앱의 모든 곳에 값들을 전달하도록 만들어주는 역할
    - 동시 컨텍스트 사용 시 안정성을 보장하여 raceCondition을 방지함
    - 특정 범위에서만 변경 가능 (다른곳에서 값의 변경이 되지 않는 안정성)
    - 기존 Task에서 생성된 Task에 의해 상속
    ```swift
    enum Locals {
      @TaskLocal static var value = 1
    }
    
    print(Locals.value) // 1
    Locals.$value.withValue(42) { 
      print(Locals.value) // 42
    }
    print(Locals.value) // 1
    ```
    - 이처럼 직접 수정이 되지 않고 withValue를 통해서만 값을 업데이트하여 적용할 수 있음
    - 이스케이프 되지 않은 클로저 범위 내에서만 값의 변경이 적용됨
    - get-only 프로퍼티에 해당됨
    - non-escaping 클로저의 범위 밖에서도 변경 값의 유지 및 사용을 위해서 Swift의 Concurrency를 사용할 수 있음
    - Task로 감싸주어 작업이 생성된 순간 @TaskLocal을 상속하는 작업 로컬 상속 방식을 가짐
    ```swift
    Locals.$value.withValue(42) {
      Task {
        try await Task.sleep(for: .seconds(1))
        print(Locals.value) // 42
      }
    }
    ```
    - 위와 같이 사용할 수 있음
    - 다만 Task, TaskGroup에는 동작하지만 스코프 범위가 넘어서면 @TaskLocal에 대한 재정의가 손실됨
    ```swift
    Locals.$value.withValue(42) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        print(Locals.value) // 1
      }
    }
    ```
    - 이처럼 사용 시 손실되어 적용되지 않음
  - @Dependency 수명의 작동 방식도 내부적으로는 @TaskLocal로 유지됨
  - Task에선 상속하지만, 이스케이프 경계를 넘어서는 상속되지 않음
  - withDependencies(_:Operation:)의 후행 클로저로는 변경이 가능함
  ```swift
  func testOnAppear() async {
    await withDependencies {
      // 테스트를 위해 종속성을 재정의한 스코프
      $0.apiClient.fetchUser = { _ in User(id: 10, name: "green") }
    } operation: {
      // 재정의된 종속성으로 테스트
      let model = FeatureModel()
      XCAssertEqual(model.user, nil)
      await model.onAppear()
      XCTAssertEqual(model.user, User(id: 10, name: "green"))
    }
  }
  ```
  - 결국 withDependencies의 후행 클로저에서 실행되는 모든 코드는 재정의된것을 사용하여 실제로 네트워크 요청을 하지 않고 테스트가 가능
  - 클로저에서 테스트 코드를 넣지 않아도 해당 스코프에서 모델만 구성된다면 외부에서도 재정의된 종속성을 사용할 수 있음
  ```swift
  let model = withDependencies {
    $0.apiClient = .mock
  } operation: {
    FeatureModel()
  }
  // 여기서 사용 가능!
  ```
  - 앞서도 언급되었지만 상위 모델에서 하위 모델을 생성할 때도 자식의 종속성을 부모의 종속성으로 주입 받으려면 자식 모델 생성 시 withDependencies에서 from을 두어 self를 넣어야함
  ```swift
  let model = withDependencies(from: self) {
    $0.apiClient = .mock
  } operation: {
    FeatureModel()
  }
  ```
  - 위와 같은 방식으로 FeatureModel의 종속성이 상속되어 추가 종속성 재정의가 가능함
***
#  소감
- 진짜 훨~씬 편해지고 여러 주입을 통해 실수 할 수 있던 부분이 많이 해소된것 같음
- 정말 중요한건 직접 써봐야하는것이란걸 다시 느끼고 이제 병행을 슬슬 해볼까..? 라는 생각!
- 모든 TCA의 기능들을 꼭 써야하고 다 따라야하는건 아니라고 생각은 들기에, 필요한 부분을 잘 캐치해서 사용해야할 것 같음