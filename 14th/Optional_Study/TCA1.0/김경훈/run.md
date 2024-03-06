# .run

```swift
 public static func run(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable (_ send: Send<Action>) async throws -> Void,
    catch handler: (@Sendable (_ error: Error, _ send: Send<Action>) async -> Void)? = nil,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    withEscapedDependencies { escaped in
      Self(
        operation: .run(priority) { send in
          await escaped.yield {
            do {
              try await operation(send)
            } catch is CancellationError {
              return
            } catch {
              guard let handler = handler else {
                #if DEBUG
                  var errorDump = ""
                  customDump(error, to: &errorDump, indent: 4)
                  runtimeWarn(
                    """
                    An "Effect.run" returned from "\(fileID):\(line)" threw an unhandled error. …

                    \(errorDump)

                    All non-cancellation errors must be explicitly handled via the "catch" parameter \
                    on "Effect.run", or via a "do" block.
                    """
                  )
                #endif
                return
              }
              await handler(error, send)
            }
          }
        }
      )
    }
  }
```

TaskPriority

GCD에서 설정해주는 것처럼 high, medium, low, UI, utility, background 등이 있다.

쓰레드 우선순위를 정해줄 수 있다

yield

```swift
public func yield<R>(_ operation: () async throws -> R) async rethrows -> R {
      try await withDependencies {
        $0 = self.dependencies
      } operation: {
        try await operation()
      }
    }
```

비동기 상황에서 하위 의존에 접근한다.