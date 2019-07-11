//
//  ObservableType+Extensions.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 2/21/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if DEBUG
    import Foundation
#endif

extension ObservableType {
    /**
     Subscribes an event handler to an observable sequence.
     
     - parameter on: Action to invoke for each event in the observable sequence.
     - returns: Subscription object used to unsubscribe from the observable sequence.
     
     将代码块转化成类，然后对时间进行订阅
     */
    public func subscribe(_ on: @escaping (Event<Element>) -> Void)
        -> Disposable {
            let observer = AnonymousObserver { e in
                on(e)
            }
            return self.asObservable().subscribe(observer)
    }
    
    
    /**
     Subscribes an element handler, an error handler, a completion handler and disposed handler to an observable sequence.
     
     - parameter onNext: Action to invoke for each element in the observable sequence.
     - parameter onError: Action to invoke upon errored termination of the observable sequence.
     - parameter onCompleted: Action to invoke upon graceful termination of the observable sequence.
     - parameter onDisposed: Action to invoke upon any type of termination of sequence (if the sequence has
     gracefully completed, errored, or if the generation is canceled by disposing subscription).
     - returns: Subscription object used to unsubscribe from the observable sequence.
     */
    public func subscribe(onNext: ((Element) -> Void)? = nil,
                          onError: ((Swift.Error) -> Void)? = nil,
                          onCompleted: (() -> Void)? = nil,
                          onDisposed: (() -> Void)? = nil)
        -> Disposable {
            let disposable: Disposable
            
            if let disposed = onDisposed {
                disposable = Disposables.create(with: disposed)
            }
            else {
                disposable = Disposables.create()
            }
            
            #if DEBUG
                let synchronizationTracker = SynchronizationTracker()
            #endif
            
            // 给 callStack 赋值的是两种类型，一种是  () -> [String], 一种是 []
            // 结果相同时，可以相互转化
            // Hooks.customCaptureSubscriptionCallstack()
            // []
            let callStack = Hooks.recordCallStackOnError ? Hooks.customCaptureSubscriptionCallstack() : []
            
            let observer = AnonymousObserver<Element> { event in
                
                #if DEBUG
                    synchronizationTracker.register(synchronizationErrorMessage: .default)
                    defer { synchronizationTracker.unregister() }
                #endif
                
                switch event {
                case .next(let value):
                    onNext?(value)
                case .error(let error):
                    if let onError = onError {
                        onError(error)
                    }
                    else {
                        Hooks.defaultErrorHandler(callStack, error)
                    }
                    disposable.dispose()
                case .completed:
                    onCompleted?()
                    disposable.dispose()
                }
            }
            // 返回的 disposable
            // 1. 取消订阅的 disposable
            // 2. 外界传过来的在取消订阅时需要调用的 onDisposed
            // 在取消订阅时，需要同时调用这两个的 dispose 方法
            return Disposables.create(self.asObservable().subscribe(observer), disposable)
    }
}

import class Foundation.NSRecursiveLock


extension Hooks {
    public typealias DefaultErrorHandler = (_ subscriptionCallStack: [String], _ error: Error) -> Void
    public typealias CustomCaptureSubscriptionCallstack = () -> [String]

    fileprivate static let _lock = RecursiveLock()
    // 调用错误堆栈的处理方式
    fileprivate static var _defaultErrorHandler: DefaultErrorHandler = { subscriptionCallStack, error in
        #if DEBUG
            let serializedCallStack = subscriptionCallStack.joined(separator: "\n")
            print("Unhandled error happened: \(error)\n subscription called from:\n\(serializedCallStack)")
        #endif
    }
    
    // 自定义获取调用堆栈信息
    fileprivate static var _customCaptureSubscriptionCallstack: CustomCaptureSubscriptionCallstack = {
        #if DEBUG
            return Thread.callStackSymbols
        #else
            return []
        #endif
    }

    /// Error handler called in case onError handler wasn't provided.
    public static var defaultErrorHandler: DefaultErrorHandler {
        get {
            _lock.lock(); defer { _lock.unlock() }
            return _defaultErrorHandler
        }
        set {
            _lock.lock(); defer { _lock.unlock() }
            _defaultErrorHandler = newValue
        }
    }
    
    /// Subscription callstack block to fetch custom callstack information.
    public static var customCaptureSubscriptionCallstack: CustomCaptureSubscriptionCallstack {
        get {
            _lock.lock(); defer { _lock.unlock() }
            return _customCaptureSubscriptionCallstack
        }
        set {
            _lock.lock(); defer { _lock.unlock() }
            _customCaptureSubscriptionCallstack = newValue
        }
    }
}

