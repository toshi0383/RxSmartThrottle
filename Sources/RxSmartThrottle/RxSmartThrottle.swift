import Foundation
import RxSwift

extension ObservableType {

    /**
     Returns an Observable that emits the first and the latest item emitted by the source Observable during sequential time windows of a specified duration.

     This operator makes sure that no two elements are emitted in less then each consulted dueTime.

     - seealso: [debounce operator on reactivex.io](http://reactivex.io/documentation/operators/debounce.html)

     - parameter dueTime: Throttling duration for each element. Consulted after each next event for next throttle.
     - parameter until: dueTime interval resets to 0 at each next event of this stream.
     - parameter latest: Should latest element received in a dueTime wide time window since last element emission be emitted.
     - parameter scheduler: Scheduler to run the throttle timers on.
     - returns: The throttled sequence.
     */
    public func throttle<O: ObservableType, U>(dueTime: @escaping (E, RxTimeInterval) -> RxTimeInterval, until: O, latest: Bool = false, scheduler: SchedulerType)
        -> Observable<E> where O.E == (U) {

            return Observable.create { (observer: AnyObserver<E>) -> Disposable in
                let _until: Observable<U> = until.asObservable()

                // state
                var _lastUnsentElement: E? = nil
                var _lastSentTime: Date? = nil
                var _completed: Bool = false
                var _currentDueTime: RxTimeInterval = 0
                let cancellable = SerialDisposable()

                let _lock = NSRecursiveLock()

                func sendNow(element: E) {
                    _lastUnsentElement = nil
                    observer.onNext(element)
                    // in case element processing takes a while, this should give some more room
                    _lastSentTime = scheduler.now
                }

                func propagate(_: Int) -> Disposable {
                    _lock.lock(); defer { _lock.unlock() }

                    if let lastUnsentElement = _lastUnsentElement {
                        _currentDueTime = dueTime(lastUnsentElement, _currentDueTime)
                        sendNow(element: lastUnsentElement)
                    }

                    if _completed {
                        observer.onCompleted()
                    }

                    return Disposables.create()
                }

                let untilSubscription = _until.subscribe(onNext: { _ in
                    _lock.lock(); defer { _lock.unlock() }

                    cancellable.disposable.dispose()
                    _currentDueTime = 0
                    _lastSentTime = nil

                    if latest, let element = _lastUnsentElement {
                        sendNow(element: element)
                    }

                    _lastUnsentElement = nil
                })

                let subscription = self.subscribe({ event in
                    _lock.lock(); defer { _lock.unlock() }

                    switch event {
                    case .next(let element):
                        let now = scheduler.now

                        let timeIntervalSinceLast: RxTimeInterval

                        if let lastSendingTime = _lastSentTime {
                            timeIntervalSinceLast = now.timeIntervalSince(lastSendingTime)
                        }
                        else {
                            timeIntervalSinceLast = _currentDueTime
                        }

                        let couldSendNow = timeIntervalSinceLast >= _currentDueTime

                        if couldSendNow {
                            _currentDueTime = dueTime(element, _currentDueTime)
                            sendNow(element: element)
                            return
                        }

                        if !latest {
                            return
                        }

                        let isThereAlreadyInFlightRequest = _lastUnsentElement != nil

                        _lastUnsentElement = element

                        if isThereAlreadyInFlightRequest {
                            return
                        }

                        let d = SingleAssignmentDisposable()
                        cancellable.disposable = d

                        d.setDisposable(scheduler.scheduleRelative(0, dueTime: _currentDueTime - timeIntervalSinceLast, action: propagate))
                    case .error:
                        _lastUnsentElement = nil
                        observer.on(event)
                    case .completed:
                        if let _ = _lastUnsentElement {
                            _completed = true
                        }
                        else {
                            observer.onCompleted()
                        }
                    }
                })

                return Disposables.create(subscription, untilSubscription)
            }
    }
}
