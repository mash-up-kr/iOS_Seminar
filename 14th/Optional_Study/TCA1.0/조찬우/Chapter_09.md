# TCA 1.0 스터디 (Testable Code)
# 챕터 자료
- https://axiomatic-fuschia-666.notion.site/Chapter-9-TCA-Testable-Code-ad3924113fbb4f89a06f30ddb8e884f7
***
#  스터디 내용
### 유닛 테스트
- TCA를 학습하며 디펜던시에 대해 파고들어봤던 이유 중 하나는 의존성들을 효율적으로 관리하기 위함
- 즉, 의존성의 동일성을 방해하지 않고 안전히 사용하기 위한 목적
- TCA는 액션 단위로 만들기에 테스트에 용이하며 의존성을 배제하고 실제 통신을 하지 않는 fake 테스트에도 용이
- 즉, TCA는 유닛 테스트하기에 너무 적합하고 편리함
***
### TCA와 Testable Code
- TCA는 액션에 의한 변형을 주관하는 리듀서가 존재하며, 그 리듀서는 서로 독립적이기에 테스트 시 아래와 같은 스텝을 고려해봐야함
  1. State가 의도한바로 업데이트 되는지
  2. 리듀서의 State, Action이 잘 전달되는지
  3. 액션 트리거 시 다른 액션이 제대로 피드백 되는지
- 즉 이러한 스텝을 통해 TCA를 테스트해봐야함
***
### TCA가 지향하는 Testable Code
- TCA는 테스트 방면에서 아래 이점을 가진다고 소개함
  - 빠르게 테스트 하고 싶은 기능을 구현할 수 있으며 액션의 흐름 점검이 가능
  - 디펜던시의 커스터마이징을 통해 서버 의존성을 배제한 테스트가 가능
  - 액션의 기본 플로우 외 사용 플로우 테스트 가능
  - 액션의 send, receive를 제어할 수 있는 기능 제공 (withExhaustivity)
  - 명확한 실패 로그
- TCA가 제공하는 Clock Dependency로 테스트를 짜면 비동기 작업을 XCTestExpectation()에 등록하여 .fulfill()하는 과정부터 wait(for:timeout)를 호출할 필요 없이 즉각 테스트가 가능
***
### 테스트를 위한 첫걸음
- 엑코 플젝은 하나 이상의 빌드 타겟을 가질 수 있음
- 타겟에서 General Setting (Testing)에서 어떤 타겟을 테스팅할지 선택 가능 (유닛 테스트 파일을 생성해 타겟 멤버쉽에서 테스트 타겟으로 체크)
- 테스트 파일을 생성하고 ComposableArchitecture를 import해줌
  - 기본적으로 UnitTest 파일 생성 시 제공되는 기본 코드들은 TCA 테스트 시 필요하지 않아 제거해도 무방
***
### 예시 Reducer
- 테스트에 들어가기 앞서 간단한 기능을 가진 테스트를 위한 리듀서에 대해 소개
- Root와 Child 리듀서가 있음
- Root 리듀서는 Child 리듀서로 네비게이션될 수 있는 기능을 가짐
```swift
import ComposableArchitecture

struct AppFeature: Reducer {
  struct State: Equatable {
    var path = StackState<Path.State>()
    var recentGuessMyAgeInformation: String?
  }

  enum Action: Equatable {
    case path(StackAction<Path.State, Path.Action>)
		case childHasBeenModified(String)
  }
  
  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      switch action {
			case let .path(.element(id: id, action: .guessMyAge(.guessAgeResponse(_)))):
        guard let guessMyAgeState = state.path[id: id, case: /Path.State.guessMyAge]
        else { return .none }
          
        if !guessMyAgeState.isGuessAgeIncorrect {
          return .send(.childHasBeenModified(guessMyAgeState.name))
        }
        return .none
          
      case .path:
        return .none
        
			case let .childHasBeenModified(name):
        state.recentGuessMyAgeInformation = name
        return .none
      }
    }
    .forEach(
      \.path,
       action: /Action.path
    ) {
      Path()
    }
  }
  
	// NavigationStack의 각 경로를 처리하는 Path Reducer
  struct Path: Reducer {
    enum State: Equatable {
      case guessMyAge(GuessMyAgeFeature.State)
    }

    enum Action: Equatable {
      case guessMyAge(GuessMyAgeFeature.Action)
    }

    var body: some ReducerOf<Self> {
        // code
    }
  }
}
```
- Child 리듀서는 사용자가 입력한 이름을 가지고 나이를 추론하는 로직을 담당
```swift
struct GuessMyAgeFeature: Reducer {
    @Dependency(\.guessAgeClient)
    var guessAgeClient

    struct State: Equatable {
        var name: String
        var age: Int?
        var isGuessAgeButtonTapped: Bool = false
        var isGuessAgeIncorrect: Bool = false
    }
    
    enum Action: Equatable {
        case nameTextFieldEditted(String)
        case emptyNameTextFieldButtonTapped
        
        case guessAgeButtonTapped
        case guessAgeResponse(GuessAge)
        case guessAgeFetchFailed
    }
    
    var body: some ReducerOf<Self> {
        core()
    }
    
    private func core() -> some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .nameTextFieldEditted(name):
                state.name = name
                return .none
                
            case .emptyNameTextFieldButtonTapped:
                state.name = ""
                return .none
                
            case .guessAgeButtonTapped:
                state.isGuessAgeButtonTapped = true
                state.age = nil
                state.isGuessAgeIncorrect = false
                
                return .run { [name = state.name] send in
                    let result = try await guessAgeClient.singleFetch(name)
                    await send(
                        .guessAgeResponse(result),
                        animation: .easeInOut
                    )
                } catch: { error, send in
                    await send(.guessAgeFetchFailed)
                }
                
            case let .guessAgeResponse(result):
                state.isGuessAgeButtonTapped = false
                if let age = result.age {
                    state.age = age
                } else {
                    state.isGuessAgeIncorrect = true
                }
                
                return .none
                
            case .guessAgeFetchFailed:
								// code
                return .none
            }
        }
    }
}
```
- 다음으로 TestStore를 가지고 기존 Store 타입을 대체함
- TestStore 인스턴스 초기화 시 리듀서가 디펜던시를 가지고 있다면 자유롭게 커스터마이징이 가능함
  - 대신 Dependency가 testValue를 구현해놨어야함
```swift
 func testTextField_Writing() async throws {
  let testStore = TestStore(
		// 🧩 initialState에서 ``name``에 "Name" 리터럴을 할당
    initialState: GuessMyAgeFeature.State(name: "Name")
  ) {
		// 🧩 State를 Reduce하는 Reducer를 호출
    GuessMyAgeFeature()
  } withDependencies: { dependency in
    // 🧩 Dependency를 새로 할당하고 정의
  }
	// code
}
```
- 이런식으로 만들게됨
- TestStore는 기본적으로 액션 트리거 및 트리거된 액션이 다시 피드백하는 액션을 받아오는 2개 메서드를 제공
  - 대부분의 테스트는 해당 2개 메서드로 해결이 되지만, 더 편리한 테스트를 위해 exhaustivity, .skipReceivedActions(strict:) 등의 프로퍼티 및 메서드를 사용할 경우도 있음
- 모든 테스트의 시작점은 .send(_:assert:file:line:) 메서드로 TestStore에 새로운 액션을 트리거하며 해당 메서드는 @MainActor 어노테이션을 가짐으로 데이터에 대한 교착 상태를 일으키지 않음
```swift
import ComposableArchitecture
import XCTest
@testable import TCAWorkshop

@MainActor
final class GuessMyAgeTest: XCTestCase {
  func testTextField_Writing() async throws {
    let testStore = TestStore(
      initialState: GuessMyAgeFeature.State(name: "Name")
    ) {
      GuessMyAgeFeature()
    }
		// 🧩 단순 TextField 테스트에는 의존성을 재정의할 필요가 없기 때문에
		// 🧩 ``withDependencies`` 후행 클로저 생략

		// 1️⃣ 특정 ``Action``을 트리거 하기 위해 ``.send(_:assert:file:line:)`` 호출
    // 2️⃣ 후행 클로저에서 ``assertEquals()``가 작동하도록 값을 할당
    // 3️⃣ send된 ``Action``이 실제로 예상 변경 값과 동일한 변화를 만들 경우,
		// 4️⃣ Test 통과
		// 🧩 initialState의 ``name``이 "NewName"을 새로 갖도록
		// 🧩 ``Action``의 연관값으로 전달
    await testStore.send(.nameTextFieldEditted("NewName")) { state in
			// 🧩 ``TestStore``의 ``State``를 받아온 후,
			// 🧩 해당 값이 실제로 "NewName"으로
			// 🧩 정상적으로 할당될 것인지 테스트
      $0.name = "NewName"
			// ✅ ``State``의 변형이 실제와 동일하다면 테스트 통과
    }
  }
}
```
- 이렇게 State 변경에 따른 기본적인 테스트가 가능
- exhaustivity 속성이 .off로 설정되면 상태 변화는 무시하고 액션 플로우만 확인할 수 있음
- 액션이 액션을 호출하거나 네트워크 통신과 같은 사이드이펙트 테스트 시 아래와 같이 withDependencies를 통해 테스트 구현 가능
```swift
struct GuessMyAgeFeature: Reducer {
  @Dependency(\.guessAgeClient)
  var guessAgeClient
	// code
}

func testGuessAge_Success() async throws {
  let guessAgeInstance = GuessAge.testInstance()
  
  let testStore = TestStore(
    initialState: GuessMyAgeFeature.State(name: "Name")
  ) {
    GuessMyAgeFeature()
  } withDependencies: {
    $0.guessAgeClient.singleFetch = { _ in return guessAgeInstance }
  }
  
  // 1️⃣ 유저가 버튼을 누르는 ``Action`` 트리거
  // 2️⃣ 해당 ``Action``이 수행하는 ``State`` 변형에 대한 ``assert``
  await testStore.send(.guessAgeButtonTapped) {
    $0.isGuessAgeButtonTapped = true
    $0.age = nil
    $0.isGuessAgeIncorrect = false
  }
  
	// 3️⃣ ``.guessAgeResponse``가 mock-up을 받아오도록 하여 서버 의존성 제거
	// 🧩 ``Action``이 피드백되며 발생하는 ``State`` 변형에 대한 테스트 진행
	// ✅ mock-up의 속성에 따라 분기처리 되는 ``State``가 올바르게 할당된다면
	// ✅ 네트워크 통신에 대한 서버 비의존적인 방식의 기능 테스트 성공
  await testStore.receive(.guessAgeResponse(guessAgeInstance)) {
    $0.isGuessAgeButtonTapped = false
      
    if let age = guessAgeInstance.age {
      $0.age = age
    } else {
      $0.isGuessAgeIncorrect = true
    }
  }
}
```
- 디펜던시 로직 자체를 mock-up 데이터를 리턴하는 로직으로 테스트에서 변경해버림
- 액션으로 인한 결과나 사이드이펙트를 받아오기 위해선 .receive(_:tileout:assert:file:line:) 메서드를 사용
  - .receive는 .send와 동일하게 비동기로 작동하기에 메인 스레드에서 로직 처리가 보장되는 @MainActor 어노테이션을 가짐
  - 액션 트리거 시 피드백할 액션들은  TestStore의 receiveAction에 쌓이고 이 액션들은 순서대로 테스트됨
  - .withExhaustivity(_:operation:)을 호출하는 방법에 따라 receivedAction에 쌓여있는 액션 테스트의 연쇄 작용이 발생할때 상태 변화를 무시하고 테스트의 진행이 가능
- 네트워크 실패 상황을 아래와 같은 코드로 테스트해볼 수 있음
```swift
func testGuessAge_Fail() async throws {
  enum GuessAgeTestError: Error { case fetchFailed }
  let guessAgeInstance = GuessAge.testInstance()
  
  let testStore = TestStore(
      initialState: GuessMyAgeFeature.State(name: guessAgeInstance.name)
  ) {
    GuessMyAgeFeature()
  } withDependencies: {
		// 🧩 기존의 네트워크 통신 로직이 실패하는 상황을 가정
		// 🧩 테스트가 진행되는 동안, Reducer는 아래의 재할당된 throw 클로저를 호출
    $0.guessAgeClient.singleFetch = { _ in throw GuessAgeTestError.fetchFailed }
  }
	
	// 🧩 테스트가 모든 ``State`` 변형에 대해 진행되지 않도록 ``exhaustivity`` 속성을 
	// 🧩 ``.off(showSkippedAssertions: false)``로 재할당
	// 🧩 ``.off(showSkippedAssertions: true)``로 재할당할 경우, 생략된 테스트에 대한
	// 🧩 잠재적 실패 상황을 Gray Message로 확인 가능
  testStore.exhaustivity = .off(showSkippedAssertions: false)        
  await testStore.send(.guessAgeButtonTapped)

	// 1️⃣ 네트워크 통신이 실패하면 ``GuessAgeTestError.fetchFailed``를 ``throw``
	// 2️⃣ 에러에 대한 처리를 진행하고 ``State``의 변형에 대한 테스트 수행 가능
	// ✅ ``State`` 변형에 대한 테스트 결과에 따라 테스트 성공
  await testStore.receive(.guessAgeFetchFailed)
}
```
- testStore의 exhaustivity 속성을 .off로 하여 상태 업데이트에 대해 테스트 진행하지 않도록 함
- .receive 메서더는 케이스패스 타입을 인자로 받을 수 있음
- 위 코드에선 즉, 네트워크 통신 실패 시 throw로 에러를 던지는데 이 에러에 대한 처리를 다루는 케이스를 테스트로 테스트 할 수 있음
- NavigationStack 테스트 시에는 아래 상황들을 고려해봐야함
  - Root에서는 Child의 상태와 액션을 받아와야함
  - Child의 액션에 반응해 Root의 액션을 트리거할 수 있어야함
  - 트리거된 액션이 Child의 State와 Root의 State를 적절하게 변형하는지 확인할 수 있어야함
```swift
func testNavigationStack_Child_GuessMyAge_Parent_Update() async throws {
  let guessAgeMock = GuessAge.testInstance()
  
  let testStore = TestStore(
      initialState: AppFeature.State(
        path: StackState([
            AppFeature.Path.State
            .guessMyAge(
              GuessMyAgeFeature.State(name: guessAgeMock.name)
            )
        ])
      )
  ) {
    AppFeature()
  }
  
	// 1️⃣ ``TestStore``에 ``NavigationStack``의 Child Action을 트리거
	// 🧩 ``.path(_:)`` 는 ``StackAction`` 타입 열거형을 요구
	// 🧩 각 ``StackAction`` 타입이 요구하는 ``id`` 값은 0부터 Stack 계층 설정 가능
	// 2️⃣ Child의 ``State`` 변화도 exhaustive 테스트에서는 테스트 필수
  await testStore.send(.path(.element(id: 0, action: .guessMyAge(.guessAgeButtonTapped)))) {
		// 3️⃣ Root ``State``의 ``path``에서 Child의 ``State`` 정보를 ``id``와 ``case``로 전달
		// 🧩 Child ``State`` 테스트 진행
    $0.path[id: 0, case: /AppFeature.Path.State.guessMyAge]?.isGuessAgeButtonTapped = true
    $0.path[id: 0, case: /AppFeature.Path.State.guessMyAge]?.age = nil
    $0.path[id: 0, case: /AppFeature.Path.State.guessMyAge]?.isGuessAgeIncorrect = false
  }
  
	// 4️⃣ Child가 ``.guessMyAge()``의 피드백하는 ``Action``을 먼저 받음
  await testStore.receive(.path(.element(id: 0, action: .guessMyAge(.guessAgeResponse(guessAgeMock))))) {
		// 5️⃣ Child의 ``State`` 정보를 ``id``와 ``case``로 전달 후, 직접 속성에 접근
		// 🧩 Child ``State`` 테스트 진행
    $0.path[id: 0, case: /AppFeature.Path.State.guessMyAge]?.isGuessAgeButtonTapped = false
    $0.path[id: 0, case: /AppFeature.Path.State.guessMyAge]?.age = 0
  }

	// 6️⃣ Child의 피드백 처리 이후, Root의 피드백 처리 진행
	await testStore.receive(.childHasBeenModified(guessAgeMock.name)) {
		// 🧩 Root ``State`` 테스트 진행
		// ✅ 모든 Assertion이 통과하면 테스트 성공
    $0.recentGuessMyAgeInformation = guessAgeMock.name
  }
}
```
***
### 그 외 상황에 해당하는 테스트
- 시간이 오래 걸리는 작업의 테스트를 위해서는 Clock을 활용하면 좋음
- withDependencies 클로저에서 Dependency를 ContinuousClock 타입으로 초기화함으로 시간 흐름을 시스템 흐름과 동일히 계산하며 개발자가 멈추기 전엔 멈추지 않음
- ImmediateClock 타입으로는 시간 지체 없이 즉각적 테스트 가능
```swift
func testTakeLongLongTimeTask() async throws {
  let store = TestStore(
		initialState: AppFeature.State()
	) {
    AppFeature()
  } withDependencies: {
    // 🧩 테스트 진행에 120초가 소요되며,
    // 🧩 QUARANTINED DUE TO HIGH LOGGING VOLUME log 메시지를 띄운다.
	  $0.continuousClock = ContinuousClock()
	}
  
  await store.send(.takeLongLongTimeTaskButtonTapped)
  // 🧩 store가 피드백을 받을 때까지 120초를 기다리겠다는 명시가 없으면 테스트 실패
  await store.receive(.takeLongLongTimeTaskResponse("COMPLETE"), timeout: .seconds(120.0)) {
    $0.takeLongLongTimeTaskResult = "COMPLETE"
  }
}

func testTakeLongLongTimeTaskInShort() async throws {
  let store = TestStore(initialState: MeetingRoomListDomain.State()) {
    MeetingRoomListDomain()
  } withDependencies: {
    // 🧩 테스트가 즉각적으로 진행
    $0.continuousClock = ImmediateClock()
  }
  
  await store.send(.takeLongLongTimeTaskButtonTapped)
  // 🧩 store가 피드백을 받을 시간이 필요하지 않음
  await store.receive(.takeLongLongTimeTaskResponse("COMPLETE")) {
    $0.takeLongLongTimeTaskResult = "COMPLETE"
  }
}
```
- 결국 동일 테스트가 둘다 되지만 시간적으로는 후자의 코드가 더 유용함
- 테스트 편의를 위해 디펜던시를 정의해봐야함
- 즉, liveValue와 testValue를 구성해야한다는것
- XCTestDynamicOverlay의 unimplement() 메서드를 사용해 클로저 타입의 변수에 대해 해당 변수가 구현되지 않았음을 알려주는 XCTFail을 대신 수행해주는 클로저를 기본 제공하며 placeholder로 원하는 결과 타입을 그대로 제공할 수도 있음
```swift
import XCTestDynamicOverlay

struct GuessAgeClient: APINetworkInterface {
  var update: @Sendable (_ updateTarget: GuessAge) async throws -> Void
  var fetchDataArray: @Sendable () async throws -> [GuessAge]
  var singleFetch: @Sendable (String) async throws -> GuessAge
}

extension GuessAgeClient {
  static let live = GuessAgeClient(
    update: { _ in },
    fetchDataArray: { [.testInstance()] },
    singleFetch: { name in
      let (data, response) = try await URLSession.shared.data(
        from: URL(string: "https://api.agify.io?name=\(name)")!
      )
      
      guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200 else {
        print("Fetch Failed", response)
        throw GuessAgeError.fetchError
      }
      
      let result = try JSONDecoder().decode(
        GuessAge.self,
        from: data
      )
      
      return result
    }
  )
    
  static let test = GuessAgeClient(
    update: unimplemented(),
    fetchDataArray: unimplemented(placeholder: [.testInstance()]),
    singleFetch: unimplemented(placeholder: .testInstance())
  )
}
```
- 이렇게 디펜던시를 구현할때 test에 대해 구현해놓을 수 있음
- 각 환경에 따라 다른 testValue를 가질 수 있어 unimplement()를 활용해도 좋을것 같음
- TCA로 테스트를 진행 시 아쉬운건 많은 다른 외부 프레임워크들을 사용해야된다는것!
- 즉, 외부 프레임워크에 대한 의존성이 높아져 이 자체는 매우 아쉬움
***
### 소감
- 테스트는 정말 필요하단걸 알지만 잘해보지 않던 영역이라 이번 챕터의 학습을 통해 TCA에서 쉽게 활용할 수 있는 부분들에 대해 자신감을 얻었다!
- 중요 핵심 로직에 대해서 먼저 간략히라도 작성해봐야겠다 😃