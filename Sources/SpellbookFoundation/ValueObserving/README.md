# Value Observing

Small, `Sendable` building blocks for sharing state and events between components without Combine or KVO.

## Quick reference

| Type | Use it for | Read `.value` | Send in | Observe | Observers / caller get | Create with |
| --- | --- | :---: | --- | :---: | --- | --- |
| `ValueStore<Value>` | Mutable, thread-safe source of truth for a piece of state | Yes | `update(...)` | Yes | `ValueChange<Value>` on every update | `ValueStore(initialValue:)`, `store.scope(\.x)` |
| `ValueObservable<Value>` | Read + observe access to state, without write access | Yes | — | Yes | `ValueChange<Value>` | `store.observable`, `observable.scope(\.x)`, `ValueObservable(view:observe:)`, `.constant(_:)` |
| `ValueView<Value>` | Reading the current value on demand, without observing | Yes | — | No | — | `store.view`, `observable.view`, `ValueView { ... }`, `.constant(_:)`, `.weak(_:)` |
| `ValueBroadcast<Value>` | Fire-and-forget events that have no "current value" | No | `notify(_:)` | Yes | `Value` per `notify` | `ValueBroadcast()` |
| `ValueAsk<Request, Response>` | Asking every attached responder and collecting their answers | No | `ask(_:)`, `stream(_:)` | No | `[Response]` or `AsyncStream<Response>` | `ValueAsk()` + `attach(_:)` |

## How they fit together

```
                         update(...)
           writer ---------------------+
                                       v
                           +-----------------------+
                           |   ValueStore<Value>   |   source of truth
                           +-----------------------+
                             |          |          |
               .observable   |    .view |          |  .scope(\.child)
                             v          v          v
     +------------------------+  +-----------+  +------------------------+
     | ValueObservable<Value> |  | ValueView |  |   ValueStore<Child>    |
     | read + observe         |  | read only |  | read + write + observe |
     +------------------------+  +-----------+  | writes go to parent    |
                                                +------------------------+

     ValueBroadcast<Value>          notify(v) ---> every observer gets v
     ValueAsk<Request, Response>    ask(r)    ---> every responder answers ---> [Response]
```

## ValueStore

```
   update { ... }       +-------------------+ -- ValueChange(old, new, context) --> observer A
  --------------------> | ValueStore<Value> | -- ValueChange(old, new, context) --> observer B
  <------ value ------- +-------------------+
                           |            ^
             .scope(\.name)|            | writes are merged into the parent,
                           v            | then parent and child notify their observers
                        +--------------------+
                        | ValueStore<String> |
                        +--------------------+
```

```swift
let store = ValueStore(initialValue: Settings())
let subscription = store.observe(.sync { change in
    print("isEnabled: \(change.old.isEnabled) -> \(change.new.isEnabled)")
})
store.update(\.isEnabled, true)
store.update { $0.name = "Main" }

let nameStore = store.scope(\.name)  // ValueStore<String>
nameStore.update("Renamed")          // store.name == "Renamed"
```

- Every `update` notifies observers, even if the value didn't change. Filter no-op updates with `.filter { $0.old != $0.new }`.
- `update(..., context:)` passes any value to observers in `ValueChange.context`, e.g. to recognise your own writes.
- With `options: .currentValue`, the observer immediately gets `ValueChange(old: value, new: value)` with a `ValueChangeContextCurrentValue` context.
- Sync observers run on the updating thread while the store's update lock is held. Calling `update` on the same store (or one of its scopes) from such an observer crashes. Move the work off the lock with `.queue(q).sync { ... }` or `.async { ... }`.
- When the root store is deallocated, observers get a termination (`onTermination` is called, streams finish).
- For optionals: `unwrapped(default:mergeIntoNil:)` and `optional(fallback:)`. For custom projections: `scope(transform:merge:)`.

## ValueObservable

```
  +------------+  .observable   +------------------------+  observe(...)
  | ValueStore | -------------> | ValueObservable<Value> | -------------> ValueChange<Value>
  +------------+                | value (read only)      |
                                +------------------------+
                                      | .scope(\.x)
                                      v
                                +------------------------+
                                | ValueObservable<X>     | -------------> ValueChange<X>
                                +------------------------+
```

```swift
let observable = store.observable              // hand this out instead of the store
let isEnabled = observable.scope(\.isEnabled)  // ValueObservable<Bool>
let subscription = isEnabled.observe(options: .currentValue, .sync { change in
    print("isEnabled is now \(change.new)")
})
```

- A scoped observable is notified on every parent change, even if its own part didn't change.
- `ValueObservable(view:observe:)` adapts any other source. `.constant(_:)` never changes and only delivers the `.currentValue` change.
- `optional()` and `unwrapped(default:)` convert between optional and non-optional values.

## ValueView

```
  +------------+    .view    +------------------+
  | ValueStore | ----------> | ValueView<Value> | -- value --> reads the store right now
  +------------+             +------------------+
                             no observers, no events
```

```swift
let view = store.view
print(view.value.name, view.name)  // dynamic member lookup
```

- The accessor closure runs on every `value` read, so the result is always current and never cached.
- Useful to inject "read the current config" into a component that doesn't need change events.
- `ValueView { ... }` wraps any accessor. `.constant(_:)` returns a fixed value, and `.weak(_:)` returns a `Sendable` object without retaining it.

## ValueBroadcast

```
               notify(v)   +-----------------------+   on notifyQueue
  sender ----------------> | ValueBroadcast<Value> | --+--> observer A gets v
                           +-----------------------+   +--> observer B gets v

           nothing is stored: observers that subscribe later miss earlier events
```

```swift
let events = ValueBroadcast<String>()
let subscription = events.observe(.sync { print("event: \($0)") })
events.notify("connected")
```

- Observers get the plain `Value`, not a `ValueChange`. `.currentValue` has no effect.
- Delivery goes through `notifyQueue`, which defaults to `.global()`. That queue is concurrent, so back-to-back events can arrive out of order. Use a serial queue, or `nil` to notify synchronously on the caller's thread.
- Deallocating the broadcast doesn't send a termination to observers.

## ValueAsk

```
               ask(request)   +----------+ -- request --> responder A --+
  asker --------------------> | ValueAsk | -- request --> responder B --+  run concurrently
        <--- [Response] ----- +----------+ -- request --> responder C --+
             in completion order
```

```swift
let canQuit = ValueAsk<Void, Bool>()
let a = canQuit.attach(.init { _ in true })
let b = canQuit.attach(.init(queue: .main) { _, reply in reply(false) })

let answers = await canQuit.ask(())           // [true, false]
let untilVeto = await canQuit.ask(()) { $0 }  // stops collecting after the first `false`
```

- Responders are `ValueResponder`s: an `async` closure, or a callback on a queue that answers with `reply(_:)`.
- `ask(_:next:)` returns responses in completion order. When `next` returns `false`, it stops collecting and returns what it has, including that response. The remaining responders still run, but their answers are dropped.
- `stream(_:)` yields responses as they arrive. With no responders attached, `ask` returns `[]`.

## Observing API

`ValueStore`, `ValueObservable` and `ValueBroadcast` conform to `ValueObserving`, so they share one way to subscribe:

```swift
store.observe(.sync { change in ... })                    // on the notifying thread
store.observe(.async { change in await ... })             // one at a time, on the caller's isolation
store.observe(.queue(.main).map(\.new).sync { ... })      // map / compactMap / filter, then deliver
store.observe(options: .currentValue, .sync { ... })      // start with the current value
for await change in store.stream() { ... }                // AsyncStream
```

- `observe` and `attach` return a `Cancellation`. Observation stops when it's cancelled **or deallocated**, so keep it, for example with `.store(in: &cancellables)`.
- `@ValueStored`, `@ValueObserved` and `@ValueViewed` property wrappers expose the store, observable or view as their projected value (`$property`). `store.observableObject` and `observable.observableObject` bridge to SwiftUI.
