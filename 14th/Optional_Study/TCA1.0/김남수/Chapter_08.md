## 트리기반

drill-down(sheet, popovers, fullscreen cover, alert 등)

State 변수를 옵셔널 타입으로 선언하고 PresentationState 프로퍼티 래퍼를 적용합니다.

```swift
struct InventoryFeature: Reducer {
  struct State {
    @PresentationState var detailItem: DetailItemFeature.State?
    /* code */
  }
  /* code */
}
```

이러한 작업은 앱에 존재하는 Navigation의 계층 수만큼 계속될 수 있습니다.

```swift
InventoryView(
  store: Store(
    initialState: InventoryFeature.State(
      detailItem: DetailItemFeature.State(      // Drill-down to detail screen
        editItem: EditItemFeature.State(        // Open edit modal
          alert: AlertState {                   // Open alert
            TextState("This item is invalid.")
          }
        )
      )
    )
  ) {
    InventoryFeature()
  }
```

새로운 기능으로 이동하는 행위는 또 다른 중첩된 `State`를 구축하는 것에 해당합니다. 이것이 트리 기반 Navigation의 기본입니다

## 스택기반

‘상태 존재’ 여부를 코드로 정의할 때, Swift의 옵셔널이나 열거형 타입을 사용하여 Navigation 기법을 트리 기반 Navigation으로 정의했습니다.

 ‘상태 존재’ 여부를 표현하는 또 다른 방식이 있는데, 바로 컬렉션 입니다. 이는 주로 SwiftUI의 NavigationStack View에서 활용되며, 스택 전체에 있는 기능들이 데이터 컬렉션으로 표현됩니다. Item이 컬렉션에 추가되면 스택에 새로운 기능이 추가되는 것을 의미하고, Item이 컬렉션에서 제거되면 스택에서 기능이 팝업 되는 것을 의미합니다.

일반적으로 스택 내에서 Navigation 가능한 모든 기능들을 포함하는 열거형(enum)을 정의합니다.

따라서, 트리 기반 Navigation에서 사용한 예시를 스택 기반 Navigation에 적용하면, Inventory 리스트가 Item에 대한 상세 정보 기능으로 이동하고 그 후에 Edit 화면으로 이동할 수 있음을 다음과 같은 방식으로 나타낼 수 있습니다.

```swift
enum Path {
  case detail(DetailItemFeature.State)
  case edit(EditItemFeature.State)
  /* code */
}

let path: [Path] = [
  .detail(DetailItemFeature.State(item: item)),
  .edit(EditItemFeature.State(item: item)),
  /* code */
]
```

이것이 바로 스택 기반 Navigation의 기본입니다. 

> 트리기반 장점
> 
- 트리 기반 Navigation은 매우 간결한 Navigation 모델링 방식을 제공합니다.
- 앱에서 가능한 모든 Navigation 경로를 정적으로 설명할 수 있으며, 이는 앱에서 유효하지 않은 Navigation 경로를 사용하지 않도록 보장합니다.

```swift
struct State {
  @PresentationState var editItem: EditItemFeature.State?
  /* code */
}
```

이렇게 필요한 이동경로만 정의함

> 트리기반 단점
> 

재귀적인 경로

> 스택기반 장점
> 

재귀경로를 쉽게처리가능(배열형태이기때문에 배열선언으로끝남)

> 스택기반 단점
> 

비논리적인 경로표현 가능

배열순서에 따라서 정해지므로 비논리적으로 선언할 여지가잇음

## 트리기반 살펴보기

옵셔널과 열거형 상태를 사용

 nil이 아닌 값으로 반전되면 sheet가 표시되고, nil 값인 경우 sheet가 해제됩니다.

dismiss시 TCA에서 제공하는 DismissEffect를 사용합니다.

## 스택기반 살펴보기

앱의 어느 상태든지 직접 접근할 수 있는 딥링크를 가능하게 합니다.

dismiss시 TCA에서 제공하는 DismissEffect를 사용합니다.

<aside>
💡 **Warning**
SwiftUI의 환경 변수 `@Environment(\.dismiss)`와 TCA의 의존성 변수 `@Dependency`는 비슷한 용도로 사용되지만, 완전히 다른 타입입니다. SwiftUI의 환경 변수는 SwiftUI View에서만 사용할 수 있고, 이 라이브러리의 의존성 변수는 Reducer 내부에서만 사용 가능합니다.

</aside>

## StackState VS NavigationPath

SwiftUI navigation은 기본적인 데이터가 타입-제거 되어있기 때문에, SwiftUI는 이 데이터 타입에 대해 많은 API를 제공하지 않습니다. 예를 들어, Path에서 수행할 수 있는 작업은 주로 그 끝에 데이터를 추가하거나, 반대로 그 끝에서 데이터를 제거하는 것뿐입니다.또는 Path의 개수를 확인할 수 있습니다.

스택 끝을 제외한 다른 곳에서는 항목을 삽입하거나 제거할 수 없으며 Path 내부 항목을 순환할 수도 없습니다.

> SwiftUI기본타입 네비를 사용함으로써 생기는 문제는 있을까?? TCA가 더 복잡한거같은데..!
>
