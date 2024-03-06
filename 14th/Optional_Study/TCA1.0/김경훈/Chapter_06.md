# Part 6

동시성 프로그래밍은 Task의 병렬 처리를 위해 등장했다.

Combine의 비동기 작업(Publisher, Subscriber)은 데이터의 흐름에 반응하므로 사용성이 다르다.

동시성 프로그래밍은 작업 자체에 대한 비동기적 처리를 지원한다.

### TCA와 비동기 처리

TCA에서 비동기 처리는 Effect<Action>를 통해 하며 Application의 상태를 제어한다.

하나의 Effect<Action>는 하나의 Reducer 내부에서 State를 변형하고 관리할 수 있으며 떄에 따라 외부 환경에서의 Effect를 Application에 피드백할 수 있다. 후자의 경우 Side Effect라고 한다.

.**run(priority:operation:catch:fileID:line:)**

Side Effect를 처리하기 위한 메서드

```swift
var body: some ReducerOf<Self> {
	Reduce { state, action in
		switch action {
		case .onViewAppearing:
			return .none
		case .onServerRequestButtonTapped:
			return .run { send in
				// 1️⃣ 비동기 코드 실행
			} catch: {
				// 2️⃣ non-cancellation 에 대한 에러 처리
			}
		}
}
```

1에서 비동기 코드를 실행하고, 이것이 실패했을 때 catch를 통해 에러 처리를 해주고 있다.

필요하다면 코드 블록의 비동기 처리에 대한 priority를 설정해줄 수 있다.

또한 send 라는 로컬 상수가 전달값이 되며 이것을 통해 Side Effect에서 받아온 결과를 Action 및 Reduce의 흐름으로 사용할 수 있다.

### run의 역할 살펴보기

Image를 비동기로 가져오는 코드를 예시로 보면,

```swift
/* code */

case .requestButtonTapped:
		// Main Thread
    return .run { send in
				// Task Thread
        let fetchedImage = try await requestImages()
        await send(.requestResponse(fetchedImage))
    } catch: { error, send in
        print(error)
    }
    
case let .requestResponse(image):
    state.image = image
    return .none

/* code */

private func requestImages() async throws -> Image {
    Task { try! await Task.sleep(for: .seconds(1)) }
    return Image(systemName: "checkmark.circle.fill")
}
```

requestImages를 통해 비동기 통신을 한다. 이곳에서 실패하게 되면 catch로 가고 성공하면 내부의 또 다른 response action를 호출하여 state의 값을 주입해준다.

.run의 operation 클로저 내부의 작업은 새로운 스레드에서 처리되며 각 비동기 작업의 결과는 main 스레드로 다시 돌아와야 한다.

### MainActor, send

send는 MainActor로 Send<Action>의 인스턴스다.

Reducer가 state에 Side Effect 결과를 피드백하기 위해 각 작업이 main 스레드에서 일어나야 한다.

그래서 send 구조체로 우리는 Action를 호출할 수 있다.

actor는 다른 스레드의 작업이 정지될 수 있음을 표시하기 위해 await 키워드와 함께 호출

위에서

```swift
await send(.requestResponse(fetchedImage))
```

이 코드는, state의 변형을 위해 정의된 MainActor 인스턴스 send가 fetchedImage 라는 값을 Application의 주된 흐름에 돌려준다.

그러니까 새로운 스레드에서 비동기 작업을 한 다음, 위의 코드를 통해 main 스레드 흐름으로 다시 편입시키는 것이다.

왜그럴까?

### TCA 비동기 처리의 맥락 이해하기

TCA에서 제공하는 send 활용하지 않고 바로 State에 접근하면 더 편할거같은데 Swift에서는 이를 허용하고 있지 않다.

```swift
func doAsyncBar() async {
	var foo = ""
	Task {
		foo = "TASK"
	}
}
```

![Untitled](Part%206%20e357271db0d244818963246a0568d4ff/Untitled.png)

에러가 나는 이유

- 변수가 Task 생성한 새 스레드에서 새로운 값을 할당하려고 시도
- 할당이 어느 시점에 이루어질지 미확정

만약 다른 스레드에서 값 할당이 문제가 생기는걸 해결하려면 변수 → 상수로 변경

```swift
func doAsyncBar() async {
	let foo = ""
	Task {
		/* Build는 성공했으나 mutate할 수 없다. */ 
		print("foo")
	}
}
```

에러를 처리했으나 값 수정이 불가능하다.

그러나 Task는 하나의 클로저로 Task의 처리 결과를 Task<Result, Never> 등의 타입으로 반환함

```swift
func doAsyncBar() async {
    let foo = ""
		/// Task가 상수를 안전하게 capture 할 수 있고
		/// Task의 결과를 클로저 블록으로 피드백할 수 있다.
		let result = Task {
		    let task = "Task"
		    return task + foo
		}
    
    print(await result.value)
}

Task {
    await doAsyncBar()
}

/* PRINT
"Task_Foo"
*/
```

이렇게 하면 Task의 처리값과 상수를 하나의 클로저 블록에서 만날 수 있음

foo는 상수지만 Task 결과로 변형해서 사용할 수 있지만 foo자체를 바꾸지 못함

Task의 결과로 foo로 하기 위해서 전역변수로 대체하고 inout 파라미터로 받아와서 처리해보려고 한다.

inout 키워드로 copy-in copy-out 방식 변형 일으킬 수 있다.

```swift
// inout 으로 변형할 수 있도록 변수로 선언을 수정합니다.
var foo = "_Foo"

func doAsyncBar(_ foo: inout String) async {
    let result = Task {
        let task = "Task"
        return task + foo
    }
  
    print(await result.value)
}
```

![Untitled](Part%206%20e357271db0d244818963246a0568d4ff/Untitled%201.png)

inout으로 변형될 것이 분명한 foo를 스레드에서 호출하는 로직은 수행할 수 없다고 한다.

동일한 맥락의 에러

이제까지 알게된 사실

- 외부 변수를 비동기 맥락 내에서 변형할 수 없기에 전역 상수로 처리
- 상수를 전달하여 비동기 맥락 내에서 로직을 처리하고 값을 반환할 수 있음
- 변형 가능성을 갖는 inout 파라미터는 비동기 맥락 내에서 사용할 수 없음

변형이 불가능하므로 Task 맥락이 아닌 main 에서 수행할 방법을 찾아야함.

그래서 TCA에서는 MainActor, Send를 도입하게 된것!

먼저 그전에 inout 전달받은 foo가 Task에서 안전하게 사용될 수 있도록 값을 캡쳐해서 변경불가능으로 바꿔야한다.

```swift
// 값을 캡처하면 캡처하는 시점의 foo의 copy를 상수로서 해당 클로저에서 사용할 수 있게 된다.
Task { [foo = foo] in
    let task = "Task"
		// TODO: actor를 활용하여 main으로 피드백
}
```

변형이 불가능하기 때문에 이처럼 수정할 수 있다.

```swift
Task { [foo = foo] in
    let taskResult = "Task" + foo
		// TODO: actor를 활용하여 main으로 피드백
}
```

이제 여기에서 main으로만 편입해서 사용하면 목적 달성이 된다.

메서드의 파라미터를 수정하면,

```swift
var foo = "_Foo"

func doAsyncBar(
    _ foo: inout String,
    mainCompletion: @escaping @MainActor (String) -> Void
) async {
    Task { [foo = foo] in
        let taskResult = "Task" + foo
        await mainCompletion(taskResult)
    }
}

Task {
    await doAsyncBar(&foo) { result in
        print("Result :", result)
        foo = result
        print("Foo :", foo)
    }
}

/* PRINT
Result : Task_Foo
Foo : Task_Foo
*/
```

mainCompletion 파라미터는 main 스레드에서의 작업이 보장되며 Task의 결과인 String 받아서 편입해줄 수 있다.

마지막으로 main에서 수행될 클로저를 정의하여 전달하면 Task 내에서의 inout 캡처 상수를 사용할 수 있게 되는 것은 물론이고, 해당 값을 꺼내와서 main에서 처리 중인 inout 파라미터 foo에도 즉시 할당할 수 있다.

TCA에서는 이 문제를 고민하지 않으려고 MainActor, send를 제공하고 있다.

위의 방식이 .run 의 비동기 처리와 피드백코드 형태도 유사한 것을 알 수 있다.

### 구조화된 Task

`.run(priority:operation:catch:fileID:line:)`의 코드 블록 내부에서 우리는 작업을 취소할 수 있고, `throw` 메서드의 에러를 `catch` 할 수 있다.

에러에 대한 액션을 다른 액션으로 곧바로 피드백할 수 있다.

또한 진행 중인 비동기 작업의 취소가 가능하다.

TCA 내부의 `send` 메서드에서 `Task.isCancelled` 로 취소를 확인해 주고 처리를 도와준다. 만약 하나의 `Task`가 취소될 때, 다른 `Task`도 동시에 취소되어야 한다면 `withTaskCancellation`을 사용할 수 있다.

취소해야 하는 비동기 작업의 `Effect` 끝에 `.cancellable` 을 추가하여 취소할 작업 `ID`를 지정해 줄 수 있다. 후에 다른 `Action`에서 `.cancel`을 취소할 작업 `ID`와 함께 호출하여 작업을 취소한다.

```swift
struct CancelFeat: Reducer {
    enum CancelKey {
        static let cancelAsync = "CANCEL_ASYNC"
    }

    struct State: Equatable { /* code */ }
    
    enum Action: Equatable {
        case runAsync
        case cancelAsync
        case asyncResponse
    }
    
    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .runAsync:
                return .run {
                    try await Task.sleep(for: .seconds(3))
                    await $0(.asyncResponse, animation: .easeInOut)
                } catch: { error, send in
                    print(error)
                    await send(.asyncResponse)
                }
                .cancellable(id: CancelKey.cancelAsync)
            
            case .asyncResponse:
                return .none
                
            case .cancelAsync:
                return .cancel(id: CancelKey.cancelAsync)
            }
        }
    }
}
```

### 부록: Swift Concurrency 역사 훑어보기

GCD에 대한 이해 및 한계

스레드 - 프로세스에서 실행 및 처리하는 단위

Thread - Swift에서 Obj-C의 NSThread를 초기화하고 각 스레드에서 실행시킬 코드를 관장하는 객체

GCD 방식의 동시성 프로그래밍

과거에는 개발자가 직접 어떤 작업을 어떤 스레드로 할지 결정하고 Thread를 생성하고 클로저에 특정 작업을 호출 할 수 있었다.

```swift
Thread.detachNewThread {
  print(Thread.current)
}
```

`Thread`를 생성하고 호출하는 방식은 다른 `Thread`의 작업이 언제 끝나는지, 끝난 이후에 어떻게 하나의 스레드에 다시 병합할 수 있는지에 대한 API를 지원하지는 않았다.

또한 코드에 의해 `Thread` 자체를 무한하게 생성하는 것도 가능했는데, 이는 CPU에 대한 경쟁 상태를 초래했다. 이는 `Thread`가 Non-blocking을 지원하지 않기 때문이다. `Thread`를 활용한 방식은 실제로는 아무런 작업이 진행되지 않은 채 죽어있는 시간을 만들 위험을 동반한다.

이러한 문제들을 극복하기 위해 등장한 개념이 바로 GCD 방식의 동시성 프로그래밍이다.

스레드 관점이 아닌 Queue 관점으로 동시성 프로그래밍을 설계한다.

```swift
let queue = DispatchQueue(label: "TCA_QUEUE")

queue.async {
	// code
}
```

DispatchQueue는 그 자체로 동시적이지 않고 순차적이다. 동시적으로 하고 싶으면 아래처럼 queue를 선언해야함

```swift
let queue = DispatchQueue(label: "TCA_QUEUE", attributes: .concurrent)
```

DispatchQueue는 non-blocking 방식으로 작업을 설계할 수 있어서 성능면에서 더 높은 효율성을 유지할 수 있다.

GCD를 통해 더 편리하게 동시성 프로그래밍을 구출할 수 있고 스레드의 개수, 죽어있는 스레드에 대한 직접적 개입이 필요없어졌다.

DispatchQueue는 target과 DispatchGroup으로 서로 다른 큐의 작업을 하나의 그룹에서 관리하여 각 작업을 기다리고 통합할 수 있다.

또 다른 큐의 작업에 의존적인 큐를 생성할 수도 있다.

```swift
func foo() {
    // 각 Queue의 작업을 통합하는 DispatchGroup
    let dispatchGroup = DispatchGroup()

    // 각각의 작업을 진행할 Queue
    let barQueue = DispatchQueue(label: "bar")
    let bazQueue = DispatchQueue(label: "baz")
    
    barQueue.async(group: dispatchGroup) {
        print("Start Bar Queue")
        Thread.sleep(forTimeInterval: 3)
        print("End Bar Queue")
    }

    bazQueue.async(group: dispatchGroup) {
        print("Start Baz Queue")
        Thread.sleep(forTimeInterval: 1)
        print("End Baz Queue")
    }

    dispatchGroup.wait()
}

func runConcurrentQueue() {
    let concurrentQueue = DispatchQueue(
        label: "qux",
        attributes: .concurrent
    )
    
    concurrentQueue.async {
        print("START CONCURRENT QUEUE")
        self.foo()
        print("CONCURRENT END")
    }
}

/* PRINT
START CONCURRENT QUEUE
Start Bar Queue
Start Baz Queue
End Baz Queue
End Bar Queue
CONCURRENT END
*/
```

concurrentQueue는 동시적으로 클로저 내부의 메서드들을 호출한다.

foo() 내부의 2개의 queue는 작업을 동시적으로 시작한다.

dispatchGroup으로 통합된 각각의 queue의 작업이 완료되기 전까지 return 되지 않으며 두 작업이 다 끝나면 concurrentQueue의 마지막이 출력된다.

ConcurrentQueue 자체도 동시적 선언되어 있으므로 main 스레드의 작업에 blocking 되지 않는다.

### GCD의 한계

GCD는 여전히 각 스레드가 data race를 유발할 위험이 있고 기존의 Thread 방식처럼 수많은 스레드를 생성시킬 수도 있다.

큐를 제한하는 것으로 몇 백개의 스레드 생성을 방지할 수 있지만 하나의 큐에서 오랜시간 걸리는 작업을 하면 CPU 자체의 한계로 인해 다른 작업은 실행되지 못할 가능성이 크다.

```swift
func explodingCPU() {
	let queue = DispatchQueue(label: "CPU_EXPLODED!", attributes: .concurrent)

	for n in 0..<1000 {
		queue.async {
			print(Thread.current)
			while true { }
		}
	}
}
```

![Untitled](Part%206%20e357271db0d244818963246a0568d4ff/Untitled%202.png)

실제로 print()가 전부 호출되지 않는다.

그리하여 해당 스레드 특정 작업의 응답을 기다리는 동안 다른 작업을 진행할 수 있어야되는데 이를 Swift Concurrency에서 알아보자.

### Swift Concurrency 등장

WWDC 2021에서 등장한 async await로 우리는 Swift Concurrency 코드를 작성할 수 있게 되었다.

async는 이 함수가 동시성 맥락을 갖고 있음을 컴파일러에 알려주는 역할

await은 async로 정의된 함수가 어느 시점에 일시정지되어야하는지 컴파일러에 알려주는 역할

Swift Concurrency가 도입되며 스레드 제어권에 대해 개발자의 직접적인 개입을 피할 수 있다.

위에서의 일시정지, Swift Concurrency에서 제안하는 suspension의 개념을 보자

**Suspension**

일시 중지된 메서드는 시스템에 스레드 제어권을 돌려주고 시스템은 일시 정지되는 동안 다른 작업을 자유롭게 실행할 수 있다.

시스템에 의해 그리하여 다른 작업을 수행하게 된다.

await가 완료되기 전까지는 그 다음 줄의 코드는 호출되지 않는다.

await 다음으로 넘어가기 위해 asyncFoo() 호출이 마무리 되어야한다.

```swift
func asyncFoo() async {
    print(#function, "RUN")
    print(Thread.current)
    try! await Task.sleep(for: .seconds(1))
    print(#function, "END")
}

await asyncFoo()
print("Do Other Thing")

/* PRINT
asyncFoo() RUN
<NSThread: 0x600003955540>{number = 6, name = (null)}
asyncFoo() END
Do Other Thing
*/
```

지금 상황에서 Multi-Thread에서 작동하는 동시성 코드를 작성하기 위해서는 다른 개념이 필요한 것 같다.

위 예시에서 asyncFoo() 와 동시에 print()를 출력할 수는 없을지 알아보기 위해서 이 작업을 각각의 작업으로 분리해서 생각하고 관리할 수 있는 개념인 Task에 대해 알아보자!

### Task의 다재다능함

Task 블록 내부는 이전에 작성하던 동기 코드와 동일한 순서로 읽을 수 있고 처리한다.

```swift
func doAsyncFoo() async -> Void {
    // code
    print("Foo Function Run")
    try! await Task.sleep(for: .seconds(1))
    print(Thread.current)
    print("Foo Function Complete")
}

let newThreadTask = Task {
	print("Start Thread")
	await doAsyncFoo()
	print("End Thread")™
}

/* PRINT
Start Thread
Foo Function Run
<NSThread: 0x600001dc0700>{number = 7, name = (null)}
Foo Function Complete
End Thread
*/
```

### TaskGroup과 동시처리

Task는 하나의 작업에 대한 비동기 처리를 책임지므로 여러 작업 동시에 처리하려면 TaskGroup을 사용할 수 있다.

```swift
func doAsyncFoo() async -> Void {
    print("Foo Function Run")
    try! await Task.sleep(for: .seconds(1))
    print(Thread.current)
    print("Foo Function Complete")
}

func doAsyncBar() async -> Void {
    print("Bar Function Run")
    try! await Task.sleep(for: .seconds(2))
    print(Thread.current)
    print("Bar Function Complete")
}

Task {
    print(Thread.current)
    await withTaskGroup(of: Void.self) { group in
        group.addTask {
            await doAsyncFoo()
        }
        
        group.addTask {
            await doAsyncBar()
        }
        
        await group.waitForAll()
    }
}

/* PRINT
<NSThread: 0x6000009dc600>{number = 6, name = (null)}
Foo Function Run
Bar Function Run
<NSThread: 0x6000009dc600>{number = 6, name = (null)}
Bar Function Complete
<NSThread: 0x6000009d6240>{number = 5, name = (null)}
Foo Function Complete
*/
```

위에서 가장 잘하는 실수는 하나의 group에 2개의 async 로직을 전달한다.

이러면 동시적으로 진행되지 않으므로 동시성 코드로 보기 어렵다.

Structured Concurrency란 각 처리를 효율적으로 하기 위해 각 작업이 제대로 동시적으로 이루어지도록 구현하는 것

```swift
group.addTask {
	await doAsyncFoo()
  await doAsyncBar()
}

/* PRINT
<NSThread: 0x600003c19b80>{number = 7, name = (null)}
Foo Function Run
<NSThread: 0x600003c0d900>{number = 6, name = (null)}
Foo Function Complete
Bar Function Run
<NSThread: 0x600003c19b80>{number = 7, name = (null)}
Bar Function Complete
*/
```

때에 따라 async-let으로도 동시작업을 처리할 수 있다.

async-let은 반환받는 타입이므로 처리해야하는 로직이 정해졌을 때 사용하는 것이 적합하다.

```swift
func getAsyncFoo() async -> String {
    print(#function, "START")
    try! await Task.sleep(for: .seconds(1))
    print(#function, "END")
    return "FOO"
}

func getAsyncBar() async -> String {
    print(#function, "START")
    try! await Task.sleep(for: .seconds(2))
    print(#function, "END")
    return "BAR"
}

func doAsyncLet() async -> Void {
    async let a = getAsyncFoo()
    async let b = getAsyncBar()
    print(await a, await b)
}

Task {
    await doAsyncLet()
}

/* PRINT
getAsyncFoo() START
getAsyncBar() START
getAsyncFoo() END
getAsyncBar() END
FOO BAR
*/
```

### Data Race와 actor 타입

이제 우리는 간편하게 여러 스레드 활용 + 쉬고있을 때 재활용도 가능해짐

만약 여러 스레드가 동시에 하나의 변수에 접근하고 수정하려고 하면?

작업이 제대로 처리되지 않을 가능성 있다. 값에 대해 일관성을 보장받을 수없다.

이전 방식에서는 NSLock 등으로 특정 스레드에서의 접근이 상호 배제될 수 있도록 처리했다.

하지만 이에 대해 정확히 적어야만 방지가 된다.

그러나 actor가 등장하며 동시 접근되고 처리되어야 하는지 더 명확하게 파악하고 제어할 수 있게 되었다.

```swift
actor MutationValue {
	var someValue: String = ""
	func mutateValue(with: String) {
		self.someValue = with
	}
}
```

비동기 작업, 멀티 스레딩 작업에서 공유하는 가변 속성 접근하기 위해 actor를 거쳐야함

이러한 작업은 비동기 방식으로 처리된다. 현재 접근 중인 스레드가 아닌 다른 작업이 일시정지 될 수 있도록 보장한다.

actor에서 특정 스레드에서 작업 처리해야하는 경우가 있다. UI 렌더링 같이 main Thread에서 발생하게 하는 @MainActor가 있다.