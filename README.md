# RxSmartThrottle

`Observable.throttle` with custom interval.

## Example: Exponential Backoff
```swift
source
    .throttle(dueTime: { max($1 * 2, 1) }, // (E, RxTimeInterval) -> RxTimeInterval
              until: takeUntilTrigger,     // Observable<U>
              latest: true,
              scheduler: scheduler)
    .disposed(by: disposeBag)
```

With the parameters above,

- throttle interval increases exponentially (1, 2, 4, 8...),
- until the `until`'s next event.

After `until`, throttle interval is reset to 0 (meaning that next `source`'s event will be forwarded immediately)

# Install
Copy paste source file to your project for now. 👌

I'm just too lazy to support Carthage or CocoaPods. It's Saturday afternoon.

# LICENSE
MIT
