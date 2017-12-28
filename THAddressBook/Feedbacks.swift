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







