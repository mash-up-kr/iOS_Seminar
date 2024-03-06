# Chap6 Swift의 비동기 처리와 TCA에서의 응용

`.run(priority:operation:catch:fileID:line:)`의 `operation { }` 클로저 내부의 작업은 작업을 위한 새로운 스레드에서 처리되며, 각 비동기 작업의 결과는 `main` 스레드로 다시 돌아와야 합니다. 

`.run(priority:operation:catch:fileID:line:)` 클로저의 내부로 전달되는 `send` 는 `MainActor` 로서 `Send<Action>` 의 인스턴스입니다. Reducer가 state에 Side Effect의 결과를 피드백하기 위해서는 각 작업이 `main 스레드`에서 일어나야 하므로, `send` 구조체로 우리는 `Action을 호출`할 수 있습니다. 언급하였듯, `actor` 는 다른 스레드의 작업이 정지될 수 있음을 표지하기 위해 `await` 키워드와 함께 호출되고 있습니다.

<aside>
💡 1. 외부 변수를 비동기 맥락 내에서 변형할 수 없기에 전역 상수로 처리함

2. 상수를 전달하여 비동기 맥락 내에서 로직을 처리하고 값을 반환할 수 있음

3. 변형 가능성을 갖는 inout 파라미터는 비동기 맥락 내에서 사용할 수 없음

</aside>

취소해야 하는 비동기 작업의 `Effect` 끝에 `.cancellable` 을 추가하여 취소할 작업 `ID`를 지정해 줄 수 있습니다. 후에 다른 `Action`에서 `.cancel`을 취소할 작업 `ID`와 함께 호출하여 작업을 취소합니다.

### GCD…

Dispatchqueue

### Concurrency..

Task

TaskGroup

Actor