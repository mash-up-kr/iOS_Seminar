# TCA 1.0 스터디 (TCA의 기본 개념 - 1)
# 챕터 자료
- https://axiomatic-fuschia-666.notion.site/Chapter-2-TCA-6b5165bd46ee43fdb9b915d5d581fd6a
***
#  스터디 내용
- ### TCA는 단방향 아키텍쳐
  - 사실 MVVM도 단방향 아키텍쳐
    - 뷰가 뷰모델의 상태를 관찰하고 상태에 따라 업데이트 되기 때문에!
    - 여기서 단방향하는것은 흐름이 하나로 흐르는것을 의미하며 MVVM에서 뷰는 상태와 로직 변경이 어떻게 일어나게 되는지는 모르는것 (뷰에서 상태와 로직 변경을 담고 있다면 그것은 뷰에서 모든걸 처리하기에 단방향 하지는 않은것)
  - SwiftUI는 기본적으로는 양방향
    - SwiftUI를 사용하게 되면 애초에 양방향 데이터 바인딩을 하기에 양방향이다
    - @State, @Binding과 같은 프로퍼티 래퍼를 뷰에서 사용하는것 자체가 어떻게 보면 뷰에서 상태를 변경시키고 로직을 처리하는 역할을 같이 하게됨
    - 그렇기에 이를 뷰모델을 두어 @Published 속성을 활용해 캡슐화로 구분되어 가져감으로 단방향으로 처리를 하는 경우도 일반적이기는 함
  - TCA는 이런 맹점들을 해소할 수 있도록 구조를 제공하고 있음
  - 즉, Action -> Reduce -> (Effect -> Action -> Reduce) -> State -> View 와 같은 흐름으로 단방향을 지킬 수 있음
  - Single Source Of Truth를 따를 수 있음
    - 단일 진실 공급원이라고 직역되는(항상 번역해오면 더 헷갈려진다) 이 SSOT는 데이터 요소에 대해 정확하고 신뢰할 수 있는 최신의 값을 하나만 존재해야한다는 의미
    - 즉 결국 데이터의 일관성과 정확성을 유지하기 위함으로 데이터 중복을 방지하자는 취지
  - 단방향을 왜 지켜야할까?
    - 1️⃣ 데이터 흐름에 대해서 예측 가능하다는것
      - 양방향은 말그대로 양방향 소통이 가능하기에 데이터 흐름을 파악할때 일관적이지 않지만 단방향이라면 상태 업데이트 자체가 일관적으로 이뤄지기에 앱의 초점인 상태 업데이트 자체를 쉽게 예측할 수 있음
    - 2️⃣ 디버깅과 테스트의 강점
      - 앱의 상태 흐름 예측이 쉽다는것은 결국 디버깅과 테스팅에 용이하다는 말과 같음
    - 3️⃣ 일관된 코드
      - 앱의 상태 변화가 한 방향으로 발생하기에 결국 코드의 일관성을 지킬 수 있어 가독성과 유지보수에 양방향보다 적합
    - 뭐 다 좋지! 근데 간단한 앱에서는 오히려 이런 구조를 다 지키면서 따르는것이 오버 엔지니어링이 될 수 도 있음 (은총알은 없다고~)
***
- ### State
  - Reducer의 현 상태를 가지는 구조체로 앱의 상태를 나타냄
  ```swift
  struct MainFeature: Reducer {
    struct State: Equatable {
      var count = 0
    }
    
    enum Action: Equatable
    
    var body: some ReducerOf<Self>
	} 
	
	struct MainView: View {
	  // 둘중 선택
	  let store: StoreOf<MainFeature>
	  let store: StoreOf<MainFeature.State, MainFeature.Action>
	  
	  var body: some View {
	    WithViewStore(self.store, observe: { $0 }) { viewStore in 
	      Text("\(viewStore.count)")
	    }
	  }
	}
	```
	와 같은 형태로 대게 사용될 수 있음
  - 사실 바닐라 SwiftUI 뷰에 WithViewStore로 감싸 옵저빙한것으로 해당 리듀서를 가진 뷰를 나타낼 수 있음
  
  - 바닐라 SwiftUI?
    - SwiftUI를 어떠한 라이브러리나 프레임워크 없이 순수한 형태로 제공된것을 사용하는것을 의미 (즉 순수 버전으로 제공된 SwiftUI의 기능만 사용하는것을 의미한다.)
    
  - State는 왜 Equatable 프로토콜을 따르며 구조체일까?
    - 결국 우리는 State를 통해 앱의 상태 변화를 업데이트하는것이 초점이기에 이 앱의 상태들이 변경되면 바인딩된 뷰를 자동으로 업데이트하고 있음
    
    - 그렇기에, State가 참조 타입이라면 객체 참조가 결국 동일하기에 이를 값의 변화로 보지 않기에 Struct 타입이 적절함
    
    - 또한 상태는 중복되지 않고 각 고유하기에 이 상태의 변화를 비교하기 위해 Equatable을 따라야함
    
    - Action은 사실 equatable하지 않아도 되지만 테스트를 위한 관용적인 사용이라고 볼 수 있음 (챕터 9장에 나온다고 한다!)
    - 근데 또 하나 안사실은 최근 버전에서는 Action에 equatable을 붙이지 않아도 되게 변경됨! (테스트 방식의 변화로 인함)
***
- ### Action
  - 액션은 TCA에서는 주로 디바이스와 사용자의 인터랙션을 받아오기 위한 타입으로 소개되지만, 사실 더 세분화하여 액션을 구성할 수도 있음
    - 사용자의 인터렉션을 받는 액션 (뷰에서)
    - 내부 상태 변화를 위한 액션
    - 사이드 이펙트 처리를 위한 액션
    - pullback한 모듈의 액션을 처리하기 위한 액션
  - 물론 위 케이스들은 프로덕트와 팀 컨벤션에 따라 당연히 필수적으로 나눌 필요는 없는 선택적인 부분이지만 핵심은 액션에서는 무조건 사용자의 인터렉션만 처리하는 액션 케이스로 한정짓지 않아도 된다는 말이 하고싶다.
    ```swift
    enum Action: Equatable {
      // 사용자 인터렉션에 대한 액션 
      case incrementButtonTapped
      case decrementButtonTapped
      // 내부 상태 변화를 위한 액션
      case _setCount
      // 사이드 이펙트 처리를 위한 액션
      case fetchCount
      // pullback한 모듈의 액션을 처리하기 위한 액션
      case subAction(SubAction)
    }
    ```
  - 액션을 통해 결국 State를 변경하거나 사이드이펙트를 처리하는 Effect를 반환하도록 트리거하는것이 목적
  - 결국 다시 또 생각해볼건 우리는 State 즉, 상태 변화를 위해 Action을 통해 처리하여 Effect를 반환한다!
  - 권장되는 액션 네이밍 컨벤션은 액션이라는것을 확실히 인지하도록 구성하는것이 좋음
  - 액션을 통해 상태를 변경한다
  ```swift
  struct MainView: View {
    let store: StoreOf<MainFeature>
    
    var body: some View {
      WithViewStore(self.sotre, observe: { $0 }) { viewStore in 
        Button("Increment") {
          viewStore.send(.incrementButtonTapped)
        }
      }
    }
  }
  ```
  위와 같이 뷰에서 해당 버튼 인터렉션 시 액션을 발행할 수 있음
  - `store.receive`는 뷰에서 직접 호출하는것은 권장되지 않고 주로 테스트할때 사용되는듯? 아직 잘몰~루~
***
- ### Reducer
  - 리듀서에서는 Action을 기반으로 현재 State를 다음 State로 어떻게 바꿀지 실제적인 구현을 해주는 역할로 프로토콜임
  - 리듀서 프로토콜을 채택하고 body나 reduce 메서드 둘 중 하나를 구현해주면 됨
    ```swift
    struct MainFeature: Reducer {
      ...
      var body: some ReducerOf<Self> {
        Reduce { state, action in 
          switch action {
            case .incrementButtonTapped:
              state.count += 1
              return .none
          }
        }
      }
      
      func reduce(into state: inout State, action: Action) -> Effect<Action> { 
        switch action {
          case .incrementButtonTapped:
            state.count += 1
            return .none
        }
      }
    }
    ```
  - 근데 최신에서는 매크로를 활용해서 아래와 같이 사용함
    ```swift
    @Reducer
    struct MainFeature {
      ...
		}
		```
  - reduce 메서드로 구현 특징
    - 기본적인 방법이고 다른 리듀서와의 결합이 필요없는 경우 주로 이용
    - 메서드기에 리듀서프로토콜 전 let reducer들을 구현해서 pullback해서 결합해서 사용하는것처럼 할 수 없는 느낌적인 느낌
    - 리듀서의 로직을 직접 해당 메서드 내에서 구현
    - 간단하고 정말 결합될 일이 없다고 판단될때 라이트하게 쓰면 적절할듯?
  - body 연산 프로퍼티로 구현 특징
    ```swift
    public protocol Reducer<State, Action> {
      func reduce(into state: inout State, action: Action) -> Effect<Action>
      
      @ReducerBuilder<State, Action>
      var body: Body { get }
    }
    ```
    - 조금 더 고수준의 방법으로 body 속성 내 직접 상태 변경이나 이펙트 로직 수행을 하지 않고 여러 리듀서를 조합할 경우 적절하다고 함
    - 추후 해당 리듀서가 잘게 작은 단위로 나눠질 여지가 있으면 body를 이용하는것이 편리
    - ReducerBuilder를 살펴보자
      ```swift
      @resultBuilder
      enum ReducerBuilder<State, Action>
      ```
      - resultBuilder 속성을 사용하고 있다.
      - 차례대로 실행하고 Effect를 병합해 리듀서를 단일 리듀서로 결합하는 결과 빌더라는 소리
      - SwiftUI의 body와 그냥 거의 복붙처럼 유사
      - 내부적으로 buildBlock을 사용하여 결합하는등 너무 닮아있다!
  - 헷갈린다~ 예시로 한번 더 자세히 봐볼까!?
    ```swift
    struct MainFeature: Reducer {
      struct State: Equatable {
        var reducerA: ReducerA.State
        var reducerB: ReducerB.State
      }
      enum Action: Equatable {
      	case reducerA(ReducerA.Action)
      	case reducer
      }
    }
    var body: some Reducer<State, Action> {
      Scope(state: \.reducerA, action: \.reducerA) {
        ReducerA()
      }
      Scope(state: \.reducerB, action: \.reducerB) {
        ReducerB()
      }
      
      Reduce { state, action in 
        switch action { }
     }
    }
    ```
    - 이렇게 여러 다른 하위 리듀서나 바인딩 리듀서들이 결합된다면 이렇게 사용해야함!
    - 본 리듀서보다 먼저 선언하는걸 권장
***
- ### Dependency
  - 흔히 의존성을 나타내는 이 Dependency는 사이드이펙트 처리에 적합
  - 네트워크 통신을 하거나 디바이스를 건드리거나 하는 등의 모든 부수 작업에 해당할 수 있음
  - 이후 챕터에서 따로 다룰 예정이라 디펜던시를 처음부터 설정하고 하는 과정보다는 현재에선 디펜던시가 무엇이고 어떻게 리듀서에서 활용되는지를 보면 좋을것 같음
  - 아래 예시를 보자
    ```swift
    struct CounterFeature: Reducer {
    @Dependency(\.continuousClock) var clock
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .toggleTimerButtonTapped:
                state.isTimerOn.toggle()
                if state.isTimerOn {
                    return .run { send in
												// 주입된 의존성 활용
                        for await _ in self.clock.timer(interval: .seconds(1)) {
                          await send(.timerTicked)
                        }
                    }
                    .cancellable(id: CancelID.timer)
                } else {
                    // Stop the timer
                    return .cancel(id: CancelID.timer)
                }
            }
        }
    }
    }
    ```
    - 예시에서 토글버튼을 누르면 isTimerOn이 true라면 다음 Effect를 발행하기 위해 .run을 시키면서 내부에서 디펜던시를 활용하고 있음
    - 1초마다 timerTicked를 send 즉, 방출하고 있음
    - 비동기적으로 처리하기에 await를 사용한것을 볼 수 있음
    - 여기서 사용된 run 등 Effect와 관련된것들도 바로 이후 챕터에서 확인해보자 😃
    - 리듀서 프로토콜 등장 이전 Environment의 역할이라고 이해할 수도 있음
    - Environment가 @Dependency 프로퍼티 래퍼로 대체된것!
***
- ### Reducer가 프로토콜로 바뀐 이유 🙋🏻
  - 사실 제일 궁금하고 가장 중요한 부분이지 않을까 싶음
  - 이전에는 reducer가 프로토콜이 아니고 reducer라는 상수로 지정하여 제네릭하게 State, Action, Environment를 받아왔음
  - Swift 5.7에서 발표한 Opaque Type의 영향으로 해당 Opaque Type을 파라미터로 사용함으로 TCA에서는 추상화 수준을 높이고 조금 더 쉽게 모듈화할 수 있도록 개선되었음
  - 근데 사실 Opaque Type은 Swift 5.1에서 나온 기능이고 iOS 13부터 적용할 수 있음
  - https://green1229.tistory.com/320 (참고해도 좋음!)
  - Opaque Type이란?
    - 메서드에서 반환하는 값의 타입이 무엇인지 숨기면서 그 타입이 특정 프로토콜을 준수하도록 보장하는 역할
    - some 키워드를 통해 선언하여 사용
      ```swift
      protocol Person { }
      
      struct Green: Person {}
      struct NamS: Person {}
      
      func makePerson() -> some Person {
        return Green()
      }
      ```
    - 기본적으로 이처럼 사용될 수 있음
    - 이로인해 구체적인 타입을 숨기기에 캡슐화에 더 이점을 얻을 수 있고 구현 변경에 따른 영향을 최소화할 수 있음
  - 결국 Opaque Type을 통해 프로토콜로 가져감으로 추상화 수준 자체를 높일 수 있다는점
  - 프로토콜의 이점인 잘게 쪼개는것을 적극적으로 활용함으로 TCA의 의도와 어울림
***
# 소감
존잼 궁금한 부분들이 하나씩 채워지는 이느낌 ⭐️