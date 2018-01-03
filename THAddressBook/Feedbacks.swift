//
//  Feedbacks.swift
//  THAddressBook
//
//  Created by 希达 on 2017/12/28.
//  Copyright © 2017年 Tan.huang. All rights reserved.
//

import RxSwift
import RxCocoa

// Taken from RxFeedback repo

/**
 * State: State type of the system.
 * Query: Subset of state used to control the feedback loop.

 When `query` returns a value, that value is being passed into `effects` lambda to decide which effects should be performed.
 In case new `query` is different from the previous one, new effects are calculated by using `effects` lambda and then performed.

 When `query` returns `nil`, feedback loops doesn't perform any effect.

 - parameter query: Part of state that controls feedback loop.
 - parameter areEqual: Part of state that controls feedback loop.
 - parameter effects: Chooses which effects to perform for certain query result.
 - returns: Feedback loop performing the effects.
 //采取RxFeedback回购

 *状态：系统的状态类型。
 *查询：用于控制反馈回路的状态子集。

 当`query`返回一个值时，该值被传递给`effects` lambda来决定应该执行哪些效果。
 如果新查询与前一个不同，则使用效果lambda计算新的效果，然后执行。

 当`query`返回`nil`时，反馈循环不起作用。

 - 参数查询：控制反馈回路的状态的一部分。
 - 参数areEqual：控制反馈回路的部分状态。
 - 参数效果：选择对某些查询结果执行哪些效果。
 - 返回：执行效果的反馈循环。
 */

public func react<State, Query, Event>(
    query: @escaping (State) -> Query?,
    areEqual: @escaping (Query, Query) -> Bool,
    effects: @escaping (Query) -> Observable<Event>
    ) -> (ObservableSchedulerContext<State>) -> Observable<Event> {
    return { state in
        return state.map(query)
            .distinctUntilChanged({ (lhs, rhs) -> Bool in
                switch (lhs, rhs) {
                case (.none, .none): return true
                case (.none, .some): return true
                case (.some, .none): return true
                case (.some(let lhs), .some(let rhs)): return areEqual(lhs, rhs)
                }
            })
            .flatMapLatest({ (control: Query?) -> Observable<Event> in
                guard let control = control else {
                    return Observable<Event>.empty()
                }

                return effects(control).enqueue(state.scheduler)
        })
    }
}

/**
 * State: State type of the system.
 * Query: Subset of state used to control the feedback loop.

 When `query` returns a value, that value is being passed into `effects` lambda to decide which effects should be performed.
 In case new `query` is different from the previous one, new effects are calculated by using `effects` lambda and then performed.

 When `query` returns `nil`, feedback loops doesn't perform any effect.

 - parameter query: Part of state that controls feedback loop.
 - parameter effects: Chooses which effects to perform for certain query result.
 - returns: Feedback loop performing the effects.
 *状态：系统的状态类型。
 *查询：用于控制反馈回路的状态子集。

 当`query`返回一个值时，该值被传递给`effects` lambda来决定应该执行哪些效果。
 如果新查询与前一个不同，则使用效果lambda计算新的效果，然后执行。

 当`query`返回`nil`时，反馈循环不起作用。

 - 参数查询：控制反馈回路的状态的一部分。
 - 参数效果：选择对某些查询结果执行哪些效果。
 - 返回：执行效果的反馈循环。
 */

public func react<State, Query: Equatable, Event> (
    query: @escaping (State) -> Query?,
    effects: @escaping (Query) -> Observable<Event>
    ) -> (ObservableSchedulerContext<State>) -> Observable<Event> {
    return react(query: query, areEqual: { $0 == $1 }, effects: effects)
}

/**
 * State: State type of the system.
 * Query: Subset of state used to control the feedback loop.

 When `query` returns a value, that value is being passed into `effects` lambda to decide which effects should be performed.
 In case new `query` is different from the previous one, new effects are calculated by using `effects` lambda and then performed.

 When `query` returns `nil`, feedback loops doesn't perform any effect.

 - parameter query: Part of state that controls feedback loop.
 - parameter areEqual: Part of state that controls feedback loop.
 - parameter effects: Chooses which effects to perform for certain query result.
 - returns: Feedback loop performing the effects.
 *状态：系统的状态类型。
 *查询：用于控制反馈回路的状态子集。

 当`query`返回一个值时，该值被传递给`effects` lambda来决定应该执行哪些效果。
 如果新查询与前一个不同，则使用效果lambda计算新的效果，然后执行。

 当`query`返回`nil`时，反馈循环不起作用。

 - 参数查询：控制反馈回路的状态的一部分。
 - 参数areEqual：控制反馈回路的部分状态。
 - 参数效果：选择对某些查询结果执行哪些效果。
 - 返回：执行效果的反馈循环。
 */

public func react<State, Query, Event>(
    query: @escaping (State) -> Query?,
    areEqual: @escaping (Query, Query) -> Bool,
    effects: @escaping (Query) -> Signal<Event>
    ) -> (Driver<State>) -> Signal<Event> {
    return { state in
        let observableSchedulerContext = ObservableSchedulerContext<State>(source: state.asObservable(), scheduler: Signal<Event>.SharingStrategy.scheduler.async)
        return react(query: query, areEqual: areEqual, effects: { (effect) -> Observable<Event> in
            return effects(effect).asObservable()
        })(observableSchedulerContext).asSignal(onErrorSignalWith: SharedSequence<SignalSharingStrategy, Event>.empty())
    }
}


public func react<State, Query, Event> (
    query: @escaping (State) -> Query?,
    effects: @escaping (Query) -> Observable<Event>
    ) -> (ObservableSchedulerContext<State>) -> Observable<Event> {
    return { state in
        return state.map(query)
            .distinctUntilChanged({ $0 != nil })
            .flatMapLatest({ (control: Query?) -> Observable<Event> in
                guard let control = control else {
                    return Observable<Event>.empty()
                }

                return effects(control).enqueue(state.scheduler)
        })
    }
}

public func react<State, Query, Event>(
    query: @escaping (State) -> Query?,
    effects: @escaping (Query) -> Signal<Event>
    ) -> (Driver<State>) -> Signal<Event> {
    return { state in
        let observableSchedulerContext = ObservableSchedulerContext<State>(
            source: state.asObservable(),
            scheduler: Signal<Event>.SharingStrategy.scheduler.async
        )
        return react(query: query, effects:
            { effects($0).asObservable() })(observableSchedulerContext)
            .asSignal(onErrorSignalWith: .empty())
    }
}

public func react<State, Query, Event>(
    query: @escaping (State) -> Set<Query>,
    effects: @escaping (Query) -> Observable<Event>
    ) -> (ObservableSchedulerContext<State>) -> Observable<Event> {
    return { state in
        let query = state.map(query).share(replay: 1)
        let newQueries = Observable.zip(query, query.startWith(Set()))
            { $0.subtracting($1) }
        let asyncScheduler = state.scheduler.async

        return newQueries.flatMap({ controls in
            return Observable<Event>.merge(controls.map({ control -> Observable<Event> in
                return effects(control)
                    .enqueue(state.scheduler)
                    .takeUntilWithCompletedAsync(query.filter { !$0.contains(control) }, scheduler: asyncScheduler)
            }))
        })
    }
}


extension ObservableType {
    // This is important to avoid reentrancy issues. Completed event is only used for cleanup
    //这对避免重入问题非常重要。 已完成的事件仅用于清理
    fileprivate func takeUntilWithCompletedAsync<O>(_ other: Observable<O>, scheduler: ImmediateSchedulerType) -> Observable<E> {
        // this little piggy will delay completed event
        //这个小猪会延迟完成的事件
        let completeAsSoonPossible = Observable<E>.empty().observeOn(scheduler)
        return other.take(1).map {_ in completeAsSoonPossible}
            // this little piggy will ensure self is being run first
            //这个小猪会保证自己先跑
            .startWith(self.asObservable())
            // this little piggy will ensure that new events are being blocked immediatelly
            //这个小猪会确保新的事件被立即封锁
            .switchLatest()
    }
}

public func react<State, Query, Event>(
    query: @escaping (State) -> Set<Query>,
    effects: @escaping (Query) -> Signal<Event>
    ) -> (Driver<State>) -> Signal<Event> {
    return { (state: Driver<State>) -> Signal<Event> in
        let observalbeSchedulerContext = ObservableSchedulerContext(
            source: state.asObservable(),
            scheduler: Signal<Event>.SharingStrategy.scheduler.async
        )
        return react(query: query, effects:{ effects($0).asObservable() }) (observalbeSchedulerContext)
            .asSignal(onErrorSignalWith: .empty())
    }
}

extension Observable {
    fileprivate func enqueue(_ scheduler: ImmediateSchedulerType) -> Observable<Element> {
        return self
            // observe on is here because results should be cancelable
            //在这里观察是因为结果应该是可以取消的
            .observeOn(scheduler.async)
            // subscribe on is here because side-effects also need to be cancelable
            // (smooths out any glitches caused by start-cancel immediatelly)
            //订阅就在这里，因为副作用也需要被取消
            //（消除由立即取消启动引起的任何故障）
            .subscribeOn(scheduler.async)
    }
}

/**
 Contains subscriptions and events.
 - `subscriptions` map a system state to UI presentation.
 - `events` map events from UI to events of a given system.
 包含订阅和事件。
 - “订阅”将系统状态映射到UI呈现。
 - 事件从UI映射到给定系统的事件。
 */
public class Bindings<Event>: Disposable {
    fileprivate let subscriptions: [Disposable]
    fileprivate let events: [Observable<Event>]

    /**
     - parameters:
     - subscriptions: mappings of a system state to UI presentation. 系统状态到UI展示的映射。
     - events: mappings of events from UI to events of a given system 从用户界面到给定系统事件的映射
     */
    public init(subscriptions: [Disposable], events: [Observable<Event>]) {
        self.subscriptions = subscriptions
        self.events = events
    }
    /**
     - parameters:
     - subscriptions: mappings of a system state to UI presentation. 系统状态到UI展示的映射。
     - events: mappings of events from UI to events of a given system 从用户界面到给定系统事件的映射
     */
    public init(subscriptions: [Disposable], events: [Signal<Event>]) {
        self.subscriptions = subscriptions
        self.events = events.map { $0.asObservable()}
    }

    public func dispose() {
        for subscription in subscriptions {
            subscription.dispose()
        }
    }
}

/**
 Bi-directional binding of a system State to external state machine and events from it.
 将系统状态双向绑定到外部状态机和来自它的事件。
 */

public func bind<State, Event> (_ bingings: @escaping (ObservableSchedulerContext<State>) -> (Bindings<Event>)) -> (ObservableSchedulerContext<State>) -> Observable<Event> {
    return { (state: ObservableSchedulerContext<State>) -> Observable<Event> in
        return Observable<Event>.using({ () -> Bindings<Event> in
            return bingings(state)
        }, observableFactory: { (bindings: Bindings<Event>) -> Observable<Event> in
            return Observable<Event>.merge(bindings.events)
                .enqueue(state.scheduler)
        })
    }
}

/**
 Bi-directional binding of a system State to external state machine and events from it.
 Strongify owner.
 将系统状态双向绑定到外部状态机和来自它的事件。
 强化所有者。
 */
public func bind<State, Event, WeakOwner>(_ owner: WeakOwner, _ bindings: @escaping (WeakOwner, ObservableSchedulerContext<State>) -> (Bindings<Event>)) ->
    (ObservableSchedulerContext<State>) -> Observable<Event> where WeakOwner: AnyObject {
    return bind(bindingsStrongify(owner, bindings))
}


public func bind<State, Event>(_ bindings: @escaping (Driver<State>) ->(Bindings<Event>)) -> (Driver<State>) -> Signal<Event> {
    return { (state: Driver<State>) -> Signal<Event> in
        return Observable<Event>.using({ () -> Bindings<Event> in
            return bindings(state)
        }, observableFactory: { (bindings: Bindings<Event>) -> Observable<Event> in
            return Observable<Event>.merge(bindings.events)
        })
            .enqueue(Signal<Event>.SharingStrategy.scheduler)
            .asSignal(onErrorSignalWith: .empty())
    }
}



/**
 Bi-directional binding of a system State to external state machine and events from it.
 Strongify owner.
 将系统状态双向绑定到外部状态机和来自它的事件。
 强化所有者。
 */
public func bind<State, Event, WeakOwner>(_ owner: WeakOwner, _ bindings: @escaping (WeakOwner, Driver<State>) -> (Bindings<Event>)) -> (Driver<State>) -> Signal<Event> where WeakOwner: AnyObject {
    return bind(bindingsStrongify(owner, bindings))
}

public func bindingsStrongify<Event, O, WeakOwner>(_ owner: WeakOwner, _ bindings: @escaping (WeakOwner, O) -> (Bindings<Event>)) -> (O) -> (Bindings<Event>) where WeakOwner: AnyObject {
    return { [weak owner] state -> Bindings<Event> in
        guard let strongOwner = owner else {
            return Bindings(subscriptions: [], events: [Observable<Event>]())
        }
        return bindings(strongOwner, state)
    }
}
























