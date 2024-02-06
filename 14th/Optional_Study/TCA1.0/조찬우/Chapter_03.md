# TCA 1.0 스터디 (TCA의 기본 개념 - 2)
# 챕터 자료
- https://axiomatic-fuschia-666.notion.site/Chapter-3-TCA-2-c56b24efb2154dad9ed8e54139247024
***
#  스터디 내용
- ### Action에 따른 결과 Effect
  - Effect는 리듀서의 액션이 반환되는 타입을 의미함으로 즉, 액션을 거친 모든 결과를 Effect로 칭함
  - 여기서 네트워크 통신이나 OS를 건드는 등의 작업은 사이드 이펙트로 결국 Effect는 외부 시스템과도 상호작용하는 작업도 의미함
  - Effect를 통해 State가 변경되고 앱의 상태가 업데이트되는 흐름
  - 비동기 작업을 수행하고 해당 결과를 다시 Action으로 반환하여 State에 반영하는것으로도 사용
  - Action은 결과에 따라 새로운 Action을 생성하기도하고 이를 통해 결국 State를 업데이트 하는 역할을 가짐
  - Effect는 그래서 정리해보면 아래와 같은 기능들을 수행함
    - 1️⃣ 비동기 작업을 관리
    - 2️⃣ 사이드 이펙트 분리하여 다룸 (Effect는 순수해야하기에)
    - 3️⃣ 취소 및 에러 핸들링
    - 4️⃣ 순서 보장
      - 이펙트 자체는 순차적으로 실행되기에 순서를 보장해줌
      - 결국 순서를 보장함으로 인해 State 변화를 주는 사이드 이펙트를 처리하고 순수하게 가져감으로 보다 더 예측 가능한 결과를 제공해줌
***
- ### 순수함수의 의미로써 Effect
  - 순수함수란 항상 주어진 입력에 대해 동일한 출력을 반환해주고 외부 상태의 변경이 없는 즉, Side Effect가 없는 함수를 의미함
    ```swift
    func getNumber() -> Int {
      return 1
    }
    ```
    위 함수는 시그니쳐를 볼 때 Void를 전달받아 Int 타입을 반환해주기에 내부 구현을 보더라도 1이라는 Int 값을 리턴해주는것을 볼 수 있음
    즉 순수하다는 소리!
    
    ```swift
    func getNumber() -> Int {
      print("1")
      return 1
    }
    ```
    위 함수는 시그쳐를 볼때 Void를 전달받아 Int 타입을 반환해주는것만을 우리는 의도하는데 내부에선 print가 되고 있음
    즉, 예상과는 다른 작업을 하기에 순수하지 않음
  - 결국 TCA에서도 비동기 작업같은 Side Effect의 처리는 별도로 수행하고 그 결과를 다시 Action으로 반환하여 생성된 또 다른 Action이 리듀서에서 처리되어 State를 업데이트함으로 순수함을 가짐
  - 중요한건 Effect 자체가 순수한것이 아닌 순수하도록 Side Effect를 관리하는것으로 설계됨
    - 비동기 작업을 예를들면, Effect가 네트워크 요청을 수행하고 결과 혹은 오류에 대해 새로운 Action을 발행하여 반환하고 이 Action을 다시 리듀서에서 Action으로 받아 State를 업데이트하는 로직을 수행하는 흐름이기에 순수하게 관리됨
  - Combine에서 Publisher가 Effect로 볼 수 있고, Subsriber가 Effect의 .run으로 볼 수 있음
  - Effect의 .run은 또 뒤에서 나오겠지만 비동기 작업을 처리하고 해당 결과를 Action으로 반환하기 위해 주로 사용됨
  - TCA의 Effect도 Swift의 Combine 프레임워크를 기반으로 작성되었기에 Combine의 동작과 거의 유사
***
- ### Effect의 주요 메서드들
  - .none
    - Action에서 Effect는 필수로 반환해야하기에 만약 상태 변경 및 로직 처리 후 이후 다른 동작을 하지 않는다면 .none을 사용
    ```swift
    case .incrementButtonTapped:
      state.count += 1
      return .none
    ```
  - .send
    - 파라미터로 Action을 넣어줌으로 현재 Action에서 로직 처리 후 추가로 다른 Action의 처리가 동기적으로 필요할 때 사용함
    - 액션을 전달하면서 애니메이션을 지정할 수 있다는데 아직 잘 모르겠다!
    - 특이한것은 로직을 공유하기 위한 목적으로 .send를 사용하지말라고 권장한다는데 (코드 중복이 발생할 수 있기에) 이는 설계하기 나름이 아닐까 싶긴함
      - 왜냐하면, 내부 상태를 변경하는 공통된 로직을 하나의 내부 액션으로 구현하고 .send를 통해 사용한다면 코드 중복을 더 줄이는 방법이 아닐까 생각이듬
  - .run
    - 앞서 말했듯, 비동기 작업을 래핑하는 메서드로 인자로 비동기 클로저를 받아 실행하고 클로저 내부에서는 send를 사용해 액션을 시스템에 전달하여 상태 처리 등 그 다음 작업을 해줌
    ```swift
    case .aButtonTapped:
      return .run { send in 
        for await event in self.events() {
          send(.event(event))
        }
      }
    ```
    해당 코드를 살펴보면 .run으로 비동기 작업의 Effect를 수행한다.
    여기서 self.events()가 어떠한 비동기 작업일 것으로 추측됨
    for await을 통해 비동기 스트림을 처리한 후에 send를 호출하여 그에 맞는 다음 해당 액션을 처리하게 되는 형식
    - 비동기 작업을 처리하는것이기에 클로저에 캡쳐리스트처럼 현재 state값을 넣어줄 수 있음
    - 이는 기존 리듀서 프로토콜 이전 방식에서 처리는 inout을 사용한다던가 내부 다른 메서드를 만들어 사용하는 등 꽤 까다로웠음
    ```swift
    case .aButtonTapped:
      return .run { [count = state.count] send in 
      	let (data, _) = try await URLSession.shared.data(from: URL(string: "\(count)")!)
      	send(.nextAction)
      }
    ```
    이처럼 사용될 수 있음
  - .cancellable(id:) & .cancel(id:)
    - 먼저 아래 예시를 보자
    ```swift
    private enum CancelID { case timer }
    case .buttonTapped:
    if state.isOn {
      return .run { send in 
        while true {
          try await Task.sleep(for: .seconds(1))
          await send(.nextAction)
        }
      } else {
        .return .cancel(id: CancelID.timer)
      }
    }
    ```
    위 코드가 있을 경우 .cancellable은 id에 Effect를 식별하는 값을 담아 Effect를 취소할 수 있게 하는 메서드
    cancelInFlight 옵션을 줄 수 있으며, 기본값은 false이고 true로 설정한다면 같은 id로 진행중인 Effect를 모두 취소하는 효과를 가짐
    cancel은 실제로 이펙트를 취소하는것
    둘의 차이가 조금 난해한것 같은데 이렇게 이해하면 좋다!
    cancellable은 스트림에 넣어두는것처럼 해당 비동기 작업을 옵저빙하며 언제든 스트림을 끊어낼 수 있다는 영역표시 같은것이고 cancel로 실제 Effect를 취소하면 해당 cancellable로 옵저빙하고 있던 녀석들을 취소해버리는것!
    즉, cancellable은 취소 가능하게 하는것이고 cancel이 그렇게 생성된 작업들을 실제로 취소하는 역할로 결국 두 메서드를 모두 함께 사용하면서 비동기 작업의 수명 주기를 관리함
  - .merge & .concatenate
    - 둘다 여러 메서드를 return하여 실행해주는것은 같지만 순서와 동시라는 개념에서 차이가 있다.
    - merge는 동시에 Effect 실행을 하기에 순서를 보장해주지 않음
    - concatenate는 선언한 순서대로 Effect를 실행하기에 순서를 보장해줌
***
- ### Effect의 활용 (Side Effect)
  - 사이드이펙트는 결국 앱의 주요 로직과 별개로 순수하지 않게 발생하는 작업이기에 예상치 못한 결과를 가져올 수 있음 (외부 서비스와의 상호 작용이나 비동기 작업 같은)
  - 에러 처리 또한 이런 사이드 이펙트 중 하나
  - 그렇기에 TCA에서 Effect의 주요 메서드를 활용해 Side Effect를 다뤄줌으로 코드를 순수하게 가져가며 테스트 용이성을 향상 시킬 수 있음
  - 먼저 소개된 예시 코드를 보자!
    ```swift
    import ComposableArchitecture
    import Speech
    import SwiftUI
    
    struct RecordMeetingFeature: Reducer {
      struct State: Equatable {
        /* code */
        var durationRemaining: Duration {
          self.standup.duration - .seconds(self.secondsElapsed)
        }
      }
      enum Action: Equatable {
        case endMeetingButtonTapped
        case nextButtonTapped
        case timerTicked
      }
      /* code */
      var body: some ReducerOf<Self> {
        Reduce { state, action in
          switch action {
          case .endMeetingButtonTapped:
            return .none
    
          case .nextButtonTapped:
            return .none
    
          case .onTask:
            return .run { send in
              let status = await withUnsafeContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                  continuation.resume(with: .success(status))
                }
              }
          /* code */
            }
    
          case .timerTicked:
            state.secondsElapsed += 1
            return .none
          }
        }
      }
    }
    
    struct RecordMeetingView: View {
      let store: StoreOf<RecordMeetingFeature>
    
      var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
        /* code */
          .task { await viewStore.send(.onTask).finish() }
        }
      }
    }
    ```
    뷰에서는 .task를 이용해 뷰가 onAppear될 때 비동기 작업을 실행함
    뷰가 사라지면 비동기 작업도 자동으로 취소되도록 finish를 이용하는건가!? 요거 첨봄
    아닌가봄 그냥 .task를 통해 구현해두면 뷰가 사라지면 비동기 작업도 자동으로 취소하는듯함
    finish의 역할은 Action을 통해 전달한 모든 Effect가 완료될때까지 기다린다는 느낌? (헷갈림 사실)
    근데 요새 최신에선 레거시가 됐다라는..
    넘어가서 리듀서를 보면 .run으로 비동기 작업을 수행하고 있음
    여기서 continuation을 이용한 이유는 해당 requestAuthorization이 콜백 형식으로 비동기 함수가 아니기에 continuation을 이용하여 비동기 함수로 연결하는 역할을 가짐
    withUnsafeContinuation는 Swift Concurrency 내용일텐데, 비동기/동기 코드 간 상호 운용성을 보장하기 위함
    즉, 비동기 함수 내에서 호출되며 비동기 작업이 완료될때까지 실행을 잠시 중단하고 구체적인 결과를 반환할 수 있게 하는 역할로 이때 continuation을 제공하여 비동기 작업 결과를 반환하게함
***
- ### Store & ViewStore
  - store는 앱의 런타임 동안 리듀서의 인스턴스를 관리하는 참조 타입의 객체로 앱의 상태와 액션을 관리하며 상태 변화를 감지하고 액션을 처리하는 역할들함
    ```swift
    let store: Store<CounterFeature.State, CounterFeature.Action>
    ```
  - Store 클래스는 뷰 구조체 내에서 주어진 초기 상태와 리듀서를 사용해 초기화됨
    ```swift
    public typealias StoreOf<R: Reducer> = Store<R.State, R.Action>
    let store: StoreOf<CounterFeature>
    ```
    이렇게 StoreOf로 축약해서 사용할 수 있음
***
- ### scope(state:action:)
  - Store에서 어떻게 보면 가장 핵심인 scope 메서드!
  - 해당 메서드로 조금 더 작은 범위로 State, Action을 다루는 Store를 축소할 수 있음
    ```swift
    struct State {
      var activity: Activity.State
      var profile: Profile.State
    }
    enum Action {
    case activity(Activity.Action)
    case profile(Profile.Action)
    }
    struct AppView: View {
      let store: StoreOf<AppFeature>
      
      var body: some View {
        TabView {
          ActivityView(store: self.store.scope(state: \.activity, action: AppFeature.Action.activity))
          
          ProfileView(store: self.store.scope(state: \.profile, action: AppFeature.Action.profile))
        }
      }
    }
    ```
    위와 같이 전체 store 상수는 전체를 다루는 리듀서인데, 이를 각 뷰에 맞게 스코프를 지정하는것!
    scope는 state와 action 두 인자를 필수로 받음
    state는 상태를 지정할 키패스이고 action은 액션을 지정할 키패스
    주로 하위 상태와 액션을 상위에서 가지고 있을 경우 스코프를 지정하여 사용하는 경우가 많음
  - 이렇게 scope를 지정하는것의 장점은 뷰에서 딱 필요한 상태와 액션에만 접근함으로 불필요하게 다 가져갈 필요가 없어 모듈화와 코드 유연성 향상 -> 유닛 테스트에도 적절
***
- ### ViewStore
  - Store는 앱 상태 변화를 전체적으로 관리한다면 ViewStore는 View에 딱 필요한 상태만 구독하고 업데이트하는 역할을 가짐
  - 즉 뷰가 필요하지 않은 상태 변경에서 불필요한 뷰 업데이트를 방지함
  - 앱 규모가 커질수록 하나의 스토어로 관리하기 힘들기에 TCA의 MultiStore 개념을 도입하여 뷰에서 하위 뷰를 생성할때 상위 뷰의 상태 일부를 소유하는 별도의 스토어를 연결하게 되는데 여기서 문제가 발생함
    - 자식 뷰의 액션이 일어나면 부모 스토어에 전달하여 부모 스토어의 리듀서에서 상태 업데이트를 치는데, 이때 더 상위 스토어에서 뷰를 렌더링하는 요청이 들어오면 뷰를 여러번 렌더링하게 되는 상황이 발생
  - 결국 뷰 렌더링 관점에서 변화 중복을 방지하기 위해 ViewStore를 사용함
  - 즉 Store 상위 전체 상태에서 뷰에 필요한 부분만 추출하여 ViewStore를 사용하는 느낌
  - 근데 사실 Observation이 나오고 TCA도 또 바껴서.....
  - 이제 ViewStore도 크게 필요없고 이젠 아래처럼 쓰이면서 Store만 있어도됨
  - 그니까 이제 WithViewStore로 감싸고 viewStore를 이용하는 그런것들을 슬슬 안해도됨 ㅠ
    ```swift
    @Reducer
    struct Feature {
      @ObservableState
      struct State { }
      enum Action { }
      var body: some ReducerOf<Self> { }
    }
    
    struct FeatureView: View {
      let store: StoreOf<Feature>
      
      var body: some View {
        Text(store.count.description)
        Button("+") { store.send(.incrementButtonTapped) }
      }
    }
    ```
    요선에서 사실 최신 정리 끝남ㅎ
    viewStore나 withViewStore도 필요없어~
    근데 이건 iOS 17 이상이고 TCA도 1.7 최신 버전에서만 가능
    만약 TCA는 최신 버전인데 iOS가 17이 아니면 이렇게도 사용할 수 있음
    ```swift
    @Reducer
    struct Feature {
      @ObservableState
      struct State { }
      enum Action { }
      var body: some ReducerOf<Self> { }
    }
    
    struct FeatureView: View {
      let store: StoreOf<Feature>
      
      var body: some View {
        WithPerceptionTracking {
          Text(store.count.description)
          Button("+") { store.send(.incrementButtonTapped) }
        }
      }
    }
    ```
    - 더 알고싶으면 이거 참고하자!
    - https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/migratingto1.7/#Using-ObservableState
***
- ### WithViewStore
  - TCA 1.7 이상에선 사실 이제 레거신데 알아야될까 싶지만 알아보자ㅎ..
  - WithViewStore는 Store를 뷰 빌더에 사용할 수 있도록 하는 역할로 즉, 스토어와 뷰를 연결해주는것
  - 근데 WithViewStore로 감싼 뷰가 복잡해질수록 당연하겠지만 컴파일러 추론 성능이 저하됨
    - 이에 대해 타입을 명확하게 명시하거나 이니셜라이저를 통해 Store를 주입받아 그 안에서 뷰스토어를 생성해버린다.
    ```swift
    WithViewStore(self.store, observe: { $0 }) { viewStore: ViewStoreOf<CounterFeature> in
        /* View code */
    }
    
    let store: StoreOf<CounterFeature>
    @ObservedObject var viewStore: ViewStoreOf<CounterFeature>
    
    init(store: StoreOf<CounterFeature>) {
      self.store = store
      self.viewStore = ViewStore(self.store, observe: { $0 })
    }
    ```
    근데 아까도 말했지만, 이제 WithViewStore 크게 필요없다..
***
- ### Store가 Thread Safe하지 않는 이유
  - Store는 참조 타입이고 Thread Safe하지 않음
  - 여기서 Thread Safe하다는건 여러 스레드에서 동시에 접근이 이뤄져도 실행에 문제가 없어야되는것임
  - 결국 Store는 참조 타입이고 모든 Store의 상호 작용 자체는 Store가 생성된 동일한 스레드에서 수행되어야 함
  - Store에 액션이 전달될 때 현재 State에서 리듀서가 실행되는데, 만약 State의 변경이 동시에 발생하게 된다면?
     - Thread Safe하지 않음
     - 결국 이를 락을 걸어 해결할 수도 있겠지만, 또 다른 사이드이펙트를 발생시킬 수 있어서 주의해야함
  - 결국 Store는 Thread Safe하지 않기에 모든 액션 자체는 동일한 스레드에서 보내야함
***
# 소감
- 어찌저찌 TCA 기본 개념에 대해 알아봤는데, 최신인 TCA 1.7에서 Observation의 도입으로 많은것이 바뀌어서 조금 의욕이 사라짐 