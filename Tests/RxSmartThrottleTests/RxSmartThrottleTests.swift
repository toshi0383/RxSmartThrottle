import RxSwift
import RxTest
import XCTest

@testable import RxSmartThrottle

final class RxSmartThrottleTests: XCTestCase {
    static var allTests = [
        ("test_Throttle__customInterval__ExponentialBackoff", test_Throttle__customInterval__ExponentialBackoff),
        ("test_Throttle__customInterval__latest__false", test_Throttle__customInterval__latest__false),
        ("test_Throttle__customInterval__throttleUntil", test_Throttle__customInterval__throttleUntil),
    ]
}

extension RxSmartThrottleTests {
    func test_Throttle__customInterval__ExponentialBackoff() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            .next(120, 0),
            .next(150, 1),
            .next(210, 2),
            .next(250, 3),
            .next(310, 4),
            .next(350, 5),
            .next(570, 6),
            .next(960, 7),
            .completed(990)
            ])

        let takeUntilTrigger = Observable<Void>.empty()

        let res = scheduler.start {
            xs.throttle(dueTime: { max($1 * 2, 100) },
                        until: takeUntilTrigger,
                        latest: true,
                        scheduler: scheduler)
        }

        let correct = Recorded.events(
            .next(210, 2),
            .next(310, 4),
            .next(510, 5),
            .next(910, 6)
        )

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 990)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle__customInterval__latest__false() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            .next(120, 0),
            .next(150, 1),
            .next(210, 2),
            .next(250, 3),
            .next(310, 4),
            .next(350, 5),
            .next(570, 6),
            .next(960, 7),
            .completed(1000)
            ])

        let takeUntilTrigger = Observable<Void>.empty()

        let res = scheduler.start {
            xs.throttle(dueTime: { max($1 * 2, 100) },
                        until: takeUntilTrigger,
                        latest: false,
                        scheduler: scheduler)
        }

        let correct = Recorded.events(
            .next(210, 2),
            .next(310, 4),
            .next(570, 6),
            .completed(1000)
        )

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 1000)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle__customInterval__throttleUntil() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            .next(120, 0),
            .next(150, 1),
            .next(210, 2),
            .next(250, 3),
            .next(310, 4),
            .next(350, 5),
            .next(570, 6),
            .next(580, 7),
            .next(960, 8),
            .completed(1000)
            ])

        let takeUntilTrigger = scheduler.createHotObservable([
            .next(500, 2),
            .completed(1000)
            ])

        let res = scheduler.start {
            xs.throttle(dueTime: { max($1 * 2, 100) },
                        until: takeUntilTrigger,
                        latest: true,
                        scheduler: scheduler)
        }

        let correct = Recorded.events(
            .next(210, 2),
            .next(310, 4),
            .next(570, 6),
            .next(670, 7),
            .next(960, 8),
            .completed(1000)
        )

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 1000)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle__errorOnSource__errors() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            .next(120, 0),
            .next(150, 1),
            .next(210, 2),
            .next(250, 3),
            .next(310, 4),
            .next(350, 5),
            .error(500, RxError.timeout),
            .next(570, 6),
            .next(580, 7),
            .next(960, 8),
            .completed(1000)
            ])

        let takeUntilTrigger = Observable<Void>.empty()

        let res = scheduler.start {
            xs.throttle(dueTime: { max($1 * 2, 100) },
                        until: takeUntilTrigger,
                        latest: true,
                        scheduler: scheduler)
        }

        let correct = Recorded.events(
            .next(210, 2),
            .next(310, 4),
            .error(500, RxError.timeout)
        )

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 500)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle__eventAfterComplete() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            .next(120, 0),
            .next(150, 1),
            .next(210, 2),
            .next(220, 3),
            .next(230, 4),
            .completed(250),
            .next(300, 5),
            ])

        let takeUntilTrigger = Observable<Void>.empty()

        let res = scheduler.start {
            xs.throttle(dueTime: { max($1 * 2, 100) },
                        until: takeUntilTrigger,
                        latest: true,
                        scheduler: scheduler)
        }

        let correct = Recorded.events(
            .next(210, 2),
            .next(310, 4),
            .completed(310)
        )

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 250)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle__no_onFlightRequest_onComplete() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            .next(120, 0),
            .next(150, 1),
            .next(210, 2),
            .completed(250),
            ])

        let takeUntilTrigger = Observable<Void>.empty()

        let res = scheduler.start {
            xs.throttle(dueTime: { max($1 * 2, 100) },
                        until: takeUntilTrigger,
                        latest: true,
                        scheduler: scheduler)
        }

        let correct = Recorded.events(
            .next(210, 2),
            .completed(250)
        )

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 250)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }

    func test_Throttle__error_on_until() {
        let scheduler = TestScheduler(initialClock: 0)

        let xs = scheduler.createHotObservable([
            .next(120, 0),
            .next(150, 1),
            .next(210, 2),
            .completed(250),
            ])

        let takeUntilTrigger = scheduler.createHotObservable([
            Recorded<Event<Void>>.error(240, RxError.timeout),
            ])

        let res = scheduler.start {
            xs.throttle(dueTime: { max($1 * 2, 100) },
                        until: takeUntilTrigger,
                        latest: true,
                        scheduler: scheduler)
        }

        let correct = Recorded.events(
            .next(210, 2),
            .completed(250)
        )

        XCTAssertEqual(res.events, correct)

        let subscriptions = [
            Subscription(200, 250)
        ]

        XCTAssertEqual(xs.subscriptions, subscriptions)
    }
}
