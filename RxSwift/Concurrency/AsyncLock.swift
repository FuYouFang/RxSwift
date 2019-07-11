//
//  AsyncLock.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 3/21/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

/**
In case nobody holds this lock, the work will be queued and executed immediately
on thread that is requesting lock.

In case there is somebody currently holding that lock, action will be enqueued.
When owned of the lock finishes with it's processing, it will also execute
and pending work.

That means that enqueued work could possibly be executed later on a different thread.
*/
final class AsyncLock<I: InvocableType> : Disposable, Lock, SynchronizedDisposeType {
    typealias Action = () -> Void
    
    var _lock = SpinLock()
    
    private var _queue: Queue<I> = Queue(capacity: 0)

    private var _isExecuting: Bool = false
    private var _hasFaulted: Bool = false

    // lock {
    func lock() {
        self._lock.lock()
    }

    func unlock() {
        self._lock.unlock()
    }
    // }

    private func enqueue(_ action: I) -> I? {
        self._lock.lock(); defer { self._lock.unlock() } // {
            if self._hasFaulted {
                return nil
            }

            if self._isExecuting {
                self._queue.enqueue(action)
                return nil
            }

            self._isExecuting = true

            return action
        // }
    }

    private func dequeue() -> I? {
        self._lock.lock(); defer { self._lock.unlock() } // {
            if !self._queue.isEmpty {
                return self._queue.dequeue()
            } else {
                self._isExecuting = false
                return nil
            }
        // }
    }

    // enqueue 和 dequeue 都是 private
    // 这个锁被持有的时候，加入队列
    // 没有别持有的时候，执行队列中的所有方法
    // 加入队列中的方法，可能在其他线程上执行
    func invoke(_ action: I) {
        if let firstEnqueuedAction = self.enqueue(action) {
            firstEnqueuedAction.invoke()
        } else {
            // action is enqueued, it's somebody else's concern now
            return
        }
        
        while true {
            if let nextAction = self.dequeue() {
                nextAction.invoke()
            } else {
                return
            }
        }
    }
    
    func dispose() {
        self.synchronizedDispose()
    }

    func _synchronized_dispose() {
        self._queue = Queue(capacity: 0)
        self._hasFaulted = true
    }
}
