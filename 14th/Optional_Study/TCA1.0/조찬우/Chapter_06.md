# TCA 1.0 스터디 (Swift의 비동기 처리와 TCA에서의 응용)
# 챕터 자료
- https://axiomatic-fuschia-666.notion.site/Chapter-6-Swift-TCA-af211cdc6e54486d815e5ef1b4f2599d
***
#  스터디 내용
- ### TCA와 비동기 처리
  - 리듀서는 Effect<Action> 타입으로 앱의 상태를 제어
  - 여기서 내부 State를 업데이트하는것 외 외부에서 Effect를 피드백하는걸 흔히 사이드이펙트라 부름
***
- ### .run(priority:operation:catch:fileID:line:)
  - 사이드이펙트를 담당하여 처리하는 Effect
  - Effect의 타입 메서드로 EffectPublisher<Action, Failure>를 반환함
    - EffectTask<Action>의 typealias를 사용하려고 권장
  ```swift
  var body: some ReducerOf<Self> {
    Reduce { state, action in 
      switch action {
      case .requestNetwork:
        return .run { send in 
          🙋🏻 비동기 로직 구현
        } catch: {
          ⚠️ 에러 처리
        }
      }
    }
  }
  ```
  - 위와 같이 사용될 수 있음
***
- ### .run의 역할
  - .run의 비동기 처리 코드를 구체적으로 예시를 통해 살펴보시죠!
  ```swift
  var body: some ReducerOf<Self> {
    Reduce { state, action in 
      switch action {
      case .btnTapped:
        return .run { send in 
          let image = try await requestImage()
          await send(.requestResponse(image))
        } catch: { error, send in 
          ⚠️ 에러 처리
        }
        
      case let .requestResponse(image):
        state.image = image
        return .none
      }
    }
  }
  
  private func requestImage() async throws -> Image {
    Task { try! await Task.sleep(for: .seconds(1)) }
    return Image(systemName: "circle.fill")
  }
  ```
  - 기본적으로 TCA의 Action 케이스에서 하는 모든 일들은 메인 스레드에서 수행됨
  - .run 블럭에 들어가는것은 예외로 메인 스레드에서 처리되지 않음 (비동기 작업이기에)
  - .run을 통해 operation 클로저에서 실행된 작업은 메인 스레드가 아닌 다른 스레드에서 처리가 되고 결국 이를 통해 상태값를 바꾸는 등의 작업은 다시 메인 스레드로 돌아와 처리해야함
  - 여기서 공통된 requestImage는 액션 케이스로 다루는것이 아닌 별도 내부 메서드로 처리하는편
  - sleep을 주고 하는 작업등도 사이드이펙트로 볼 수 있음
***
- ### MainActor & send
  - 위 .run 블록의 내부에서 전달되는 send는 MainActor의 Send<Action> 인스턴스
  - 결국 위처럼 리듀서가 상태값 변경을 위해 state에 사이드이펙트로부터 완료된 새 상태값을 업데이트하는건 결국 메인 스레드에서 발생해야하기에 send를 통해 액션을 호출해야함
  - send 앞에 await를 사용하는건 actor가 다른 스레드의 작업이 일시 정지 될 수 있음을 알려주기 위함
***
- ### TCA 비동기 처리의 맥락 이해하기
  - 위와 같은 비동기 블럭에서의 값을 send를 사용하지 않고 state에 직접 접근하여 업데이트 쳐주는것은 허용되지 않고 있음
  - 그걸 알아보는게 이번 소주제의 목표!
  ```swift
  func doSomething() async {
    var value = "green"
    Task {
      value = "red"
    }
  }
  ```
  - 위 코드는 에러가 남
    - Task가 생성할 새 스레드에서 변수에 새 값을 할당하려하지만 어느 시점에 이뤄질지 미확정
  - 해당 에러들을 해결된 돌아가는 코드는 아래와 같아요!
  ```swift
  var value = "green"
  
  func doSomething(
    _ value: inout String, 
    completion: @escaping @MainActor (String) -> Void
  ) async {
    Task { [value = value] in 
      let result = "red"
      await completion(result)
    }
  }
  
  Task {
    await doSomething(&value) { result in 
      value = result
    }
  }
  ```
  - 이렇게 한다면 돌아갑니다!
    - 우선 외부 변수 자체를 비동기 코드 내에서 변경할 수 없으니 전역값으로 뺌
    - inout 파라미터는 비동기 블럭에서 사용할 수 없기에 값을 캡쳐하여 사용
    - 변경된 값을 컴플리션을 통해 메인 스레드에서 값 업데이트가 발생하게 구현
    - 컴플리션 타입에 @MainActor를 사용하여 메인 스레드에서 작업이 이뤄지도록 보장함
  - 만약 TCA에서 send를 제공하지 않으면 우리는 이러한 작업들을 각 액션에서 번거롭게 구현해줘야함
  - 위와 같은 형태가 .run의 비동기 처리 코드 로직과 아주 유사함
  - 결국 핵심은 값 업데이트는 메인 스레드에서 이뤄져야하고 비동기 처리 후 해당 도출된 값을 메인 스레드에서 어떻게 반영시키는지 그 맥락을 이해해봤으며, TCA에선 이런 번거로운것들을 send를 통해 쉽게 처리해볼 수 있음
***
- ### 구조화된 Task
  - .run 블럭에서 에러 처리에 따른 Task 취소와 일괄 관련된 모든 Task 취소 등 자유롭게 구현해줄 수 있음
  - 하나의 Task 취소 시 다른 Task도 동시 취소가 되어야 한다면 withTaskCancellation을 사용할 수 있음
  - 블럭에 cancellable을 붙여 쉽게 구성해줄수도 있음
  - 또한 catch에서도 send를 통해 구성도 가능
  ```swift
  case .doSomething:
    return .run {
      // 비동기 작업
    } catch: { error, send in 
      print(error)
      await send(.asyncResponse)
    }
    .cancellable(id: CancelKey.cancel)
  ```
  - 위와 같은 흐름으로 구성이 자유롭게 가능
  - 위와 같이 Effect에 .cancellable을 붙여주어 취소할 작업의 ID를 지정해줄 수 있게됨
    - 다른 액션 로직에서 .cancel로 해당 취소 ID가 호출되면 해당 작업도 취소하는 형식
***
- ### Swift Concurrency 히스토리 탐방하기
  - Swift Concurrency는 WWDC 2021에서 처음 소개되어 기존 GCD 방식의 동시성 프로그래밍에서 더욱 편리하게 사용할 수 있도록 해줌
  - GCD
    - GCD 이전에는 아래와 같이 개발자가 해당 작업을 어떤 스레드에서 처리할지 구현해줘야 했음
    ```swift
    Thread.newThread {
      ...
    }
    ```
    - 이러한 방식은 스레드를 무한정으로 생성될 여지도 있고 CPU를 효율적으로 쓰지 못함
    - Thread가 non-blocking을 지원하지 않기에 그러함
    - 이런 기존 방식을 해결하고자 작업의 큐 관점으로 GCD라는 동시성 프로그래밍 방식이 나옴
    ```swift
    let queue = DispatchQueue(label: "green")
    
    queue.async {
      ...
    }
    ```
    - 기본적으로 DispatchQueue는 순차적이기에 동시적으로 큐를 작업하고 싶다면 attributes에 .concurrent로 큐를 선언해줘야함
    - GCD를 통해 개발자들이 스레드에 대해 직접적으로 구현하지 않기에, 이전보다는 편리하게 동시성 프로그래밍을 구현할 수 있게 됨
    - DispatchGroup으로 서로 다른 큐의 작업들을 묶어 관리하기에도 편리해짐
    - 다만 GCD 방식도 각 스레드가 여전히 데이터 경쟁을 유발할 수 있고 기존 스레드를 직접 생성하는것처럼 많은 스레드가 생길 여지도 있음
    - 즉, 성능상으로 잘못 사용된다면 이슈가 클 수 있다는 소리!
  - Swift Concurrency
    - async & await 키워드를 통해 고유한 Swift의 Concurrency 코드 작성이 가능케됨
    - async는 이 함수가 동시성의 성격일 가지고 있다는것을 컴파일러에게 노티해주는것이고 await는 async로 정의된 함수가 언제 일시 정지되야하는지 컴파일러에 노티해주는 역할을 함
    ```swift
    func asyncSomething() async -> Void {
      ...
    }
    
    await asyncSomething()
    ```
    - 위와 같이 기본적으로 사용됨
    - 스레드 제어권에 대해 개발자 개입을 피할 수 있음
    - 시스템과 소통하면서 해당 동시성 코드들을 불특정한 Thread로 할당
    - Concurrency에선 Suspension이라는 개념을 통해 GCD의 미비한것들이 개선됨
    - suspension은 async 메서드가 suspension을 감지하는 키워드인 await와 함께 호출될 경우 그 시점에 일시 정지될 수 있음을 의미해줌
    - 시스템에 제어권을 돌려주고 다른 작업을 실행하게함
    - 즉, await로 호출되어 일시 정지된 시점부터 비동기 로직이 끝날때까지 스레드가 시스템에 의해서 다른 작업을 수행할 수 있도록 하는것
    - 결론적으로 await로 붙여주면 그 후의 코드는 해당 async 함수가 종료될떄까지 호출되지 않는다는것!
    - Task는 비동기 처리를 위해 새 스레드를 할당해주지만 스레드가 무한정 생성되지 않도록 내부적인 pool을 지님
    - Task 블럭 내에선 순차적으로 처리
    - Task는 하나의 작업에 대한 비동기 처리만을 책임
    - 만약 동시에 여러 작업을 수행해야한다면, TaskGroup을 사용
    ```swift
    Task {
      await withTaskGroup(of: VOid.self) { group in 
        group.addTask {
          await doSomething1()
        }
        group.addTask {
          await.doSomething2()
        }
        
        await group.waitForAll()
      }
    }
    ```
    - 하나의 group에 두개의 async 로직을 담으면 안됨 (작업이 동시적으로 진행되지 않음)
    - TaskGroup 방식 외 async-let으로도 동시 처리가 가능
    ```swift
    func doSomething() async -> Void {
      async let a = doSomething1()
      async let b = doSomething2()
    }
    
    Task {
      await doSomething()
    }
    ```
    - 이렇게도 가능한데 이 경우는 반환 타입이 존재하는 경우 많이 사용됨
  - Data Race & actor
    - 여러 스레드에서 동시에 공통 변수에 접근하고 수정하려고할 때 발생하는 문제를 Data Race라고함
    - 사실 Race Condition과 같음
    - 그래서 이전 방식에서는 NSLock을 걸거나 세마포어를 쓰거나 하는 등 여러 접근이 동시에 되면서 문제를 유발하지 않도록 해결해왔으나 이 또한 신경써야할게 많고 실수를 많이 유발할 수 있는 방식이였음
    - actor가 등장하며 조금 더 수월하게 사용할 수 있게됨
    - actor는 struct, class처럼 프로퍼티, 메서드, 이니셜라이저등을 가질 수 있는 하나의 타입
    ```swift
    actor Value {
      var someValue: String = ""
      func doSomething() { }
    }
    ```
    - 여러 스레드가 하나의 프로퍼티를 참조하는 상황에서 actor는 각 스레드에서 동기화 될 수 있도록 해줌
    - 비동기, 멀티스레딩 작업에서 유용
    - 현재 들어온 스레드가 아닌 다른 작업은 suspension 되도록 보장해줌
***
# 소감
- TCA에서 액션이 어떤 스레드에서 일어나고 .run의 동작은 어떤 원리인지 좀 더 명확히 알 수 있어 배워가는게 개인적으로 많았던 챕터!
- 확실히 정형화되어 사용하기에 너무 좋은것 같음