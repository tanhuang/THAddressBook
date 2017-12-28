//
//  Observable+Extensions.swift
//  THAddressBook
//
//  Created by 希达 on 2017/12/28.
//  Copyright © 2017年 Tan.huang. All rights reserved.
//

import RxCocoa
import RxSwift


extension ObservableType where E == Any {
    /// Feedback loop
    public typealias Feedback<State, Event> = (ObservableSchedulerContext<State>) -> Observable<Event>
    public typealias FeedbackLoop = Feedback

    /**
     System simulation will be started upon subscription and stopped after subscription is disposed.

     System state is represented as a `State` parameter.
     Events are represented by `Event` parameter.

     - parameter initialState: Initial state of the system.
     - parameter accumulator: Calculates new system state from existing state and a transition event (system integrator, reducer).
     - parameter feedback: Feedback loops that produce events depending on current system state.
     - returns: Current state of the system.
     */
    /**
     系统模拟将在订阅后开始，并在订阅处理后停止。

     系统状态以“State”参数表示。
     事件由“Event”参数表示。

     - 参数initialState：系统的初始状态。
     - 参数累加器reduce：从现有状态和转换事件（系统集成器，减速器）计算新的系统状态。
     - 参数反馈：根据当前系统状态产生事件的反馈循环。
     - 返回：系统的当前状态。
     */
    public static func system<State, Event>(
        initialState: State,
        reduce: @escaping (State, Event) -> State,
        scheduler: ImmediateSchedulerType,
        scheduledFeedback: [Feedback<State, Event>]
        ) -> Observable<State> {
        /// 为每一个状态创建一个新的可观察序列
        return Observable<State>.deferred({ () -> Observable<State> in
            /// 当你订阅ReplaySubject的时候，你可以接收到订阅他之后的事件，但也可以接受订阅他之前发出的事件，接受几个事件取决与bufferSize的大小
            let replaySubject = ReplaySubject<State>.create(bufferSize: 1)

            let asyncScheduler = scheduler.async
            // 合并两个Observable流合成单个Observable流，根据时间轴发出对应的事件
            let events: Observable<Event> = Observable.merge(scheduledFeedback.map({ feedback in
                let state = ObservableSchedulerContext(source: replaySubject.asObservable(), scheduler: asyncScheduler)
                return feedback(state)
            }))

                // This is protection from accidental ignoring of scheduler so
                // reentracy errors can be avoided
                //这是防止意外忽略调度程序
                //可避免重入错误
            .observeOn(CurrentThreadScheduler.instance)
            /// scan就是给一个初始化的数，然后不断的拿前一个结果和最新的值进行处理操作。

            return events.scan(initialState, accumulator: reduce).do(onNext: { (output) in
                print("output = \(output)")
                replaySubject.onNext(output)
            }, onError: { (error) in
                print("error")
            }, onCompleted: {
                print("onCompleted")
            }, onSubscribe: {
                print("onSubscribe")
                replaySubject.onNext(initialState)
            }, onSubscribed: {
                print("onSubscribed")
            }, onDispose: {
                print("onDispose")
            })
            .subscribeOn(scheduler)
                /// 在发出事件消息之前，先发出某个特定的事件消息。比如发出事件2 ，3然后我startWith(1)，那么就会先发出1，然后2 ，3.
            .startWith(initialState)
            .observeOn(scheduler)
        })
    }

    public static func system<State, Event>(
        initialState: State,
        reduce: @escaping (State, Event) -> State,
        scheduler: ImmediateSchedulerType,
        scheduledFeedback: Feedback<State, Event>...
        ) -> Observable<State> {
        return system(initialState: initialState, reduce: reduce, scheduler: scheduler, scheduledFeedback: scheduledFeedback)
    }
}


extension SharedSequenceConvertibleType where E == Any, SharingStrategy == DriverSharingStrategy {

    /// Feedback loop 反馈回路
    public typealias Feedback<State, Event> = (Driver<State>) -> Signal<Event>

    /**
     System simulation will be started upon subscription and stopped after subscription is disposed.

     System state is represented as a `State` parameter.
     Events are represented by `Event` parameter.

     - parameter initialState: Initial state of the system.
     - parameter accumulator: Calculates new system state from existing state and a transition event (system integrator, reducer).
     - parameter feedback: Feedback loops that produce events depending on current system state.
     - returns: Current state of the system.
     */
    /**
     系统模拟将在订阅后开始，并在订阅处理后停止。

     系统状态以“State”参数表示。
     事件由“Event”参数表示。

     - 参数initialState：系统的初始状态。
     - 参数累加器：从现有状态和转换事件（系统集成器，减速器）计算新的系统状态。
     - 参数反馈：根据当前系统状态产生事件的反馈循环。
     - 返回：系统的当前状态。
     */
    public static func system<State, Event> (
        initialState: State,
        reduce: @escaping (State, Event) -> State,
        feedback: [Feedback<State, Event>]
    ) -> Driver<State> {
        let observableFeedbacks: [(ObservableSchedulerContext<State>) -> Observable<Event>] = feedback.map { feedback in
            return { sharedSequence in
                return feedback(sharedSequence.source.asDriver(onErrorDriveWith: Driver<State>.empty()))
                .asObservable()
            }
        }

        return Observable<Any>.system(
            initialState: initialState,
            reduce: reduce,
            scheduler: SharingStrategy.scheduler,
            scheduledFeedback: observableFeedbacks
        )
            .asDriver(onErrorDriveWith: .empty())
    }

    public static func system<State, Event>(
        initialState: State,
        reduce: @escaping (State, Event) -> State,
        feedback: Feedback<State, Event>...
        ) -> Driver<State> {
        return system(initialState: initialState, reduce: reduce, feedback: feedback)
    }

}

extension ImmediateSchedulerType {
    var async: ImmediateSchedulerType {
        // This is a hack because of reentrancy. We need to make sure events are being sent async.
        // In case MainScheduler is being used MainScheduler.asyncInstance is used to make sure state is modified async.
        // If there is some unknown scheduler instance (like TestScheduler), just use it.
        //由于重入，这是一个黑客攻击。 我们需要确保事件正在发送异步。
        //在使用MainScheduler的情况下MainScheduler.asyncInstance用于确保state被修改为异步。
        //如果有一些未知的调度器实例（如TestScheduler），就使用它。
        return (self as? MainScheduler).map { _ in MainScheduler.asyncInstance } ?? self
    }
}

/// Tuple of observable sequence and corresponding scheduler context on which that observable
/// sequence receives elements.
/// 可观察序列的元组和可观察的对应调度器上下文
/// 序列接收元素。
public struct ObservableSchedulerContext<Element>: ObservableType {

    public typealias E = Element
    /// Source observable sequence
    /// 源可观察序列
    public let source: Observable<Element>
    /// Scheduler on which observable sequence receives elements
    ///在哪个可观察序列接收元素的调度器
    public let scheduler: ImmediateSchedulerType

    /// Initializes self with source observable sequence and scheduler
    ///
    /// - parameter source: Source observable sequence.
    /// - parameter scheduler: Scheduler on which source observable sequence receives elements
    /// 使用源可观察序列和调度器初始化自己
    ///
    /// - source：源可观察序列。
    /// - scheduler：源可观察序列接收元素的调度器。
    public init(source: Observable<Element>, scheduler: ImmediateSchedulerType) {
        self.source = source
        self.scheduler = scheduler
    }
    
    public func subscribe<O>(_ observer: O) -> Disposable where O : ObserverType, Element == O.E {
        return self.source.subscribe()
    }



}
