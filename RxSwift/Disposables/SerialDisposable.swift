//
//  SerialDisposable.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 3/12/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

/// Represents a disposable resource whose underlying disposable resource can be replaced by another disposable resource, causing automatic disposal of the previous underlying disposable resource.
///
public final class SerialDisposable : DisposeBase, Cancelable {
    private var _lock = SpinLock()
    
    // state
    private var _current = nil as Disposable?
    private var _isDisposed = false
    
    /// - returns: Was resource disposed.
    public var isDisposed: Bool {
        return self._isDisposed
    }
    
    /// Initializes a new instance of the `SerialDisposable`.
    override public init() {
        super.init()
    }
    
    /**
    Gets or sets the underlying disposable.
    
    Assigning this property disposes the previous disposable object.
    
    If the `SerialDisposable` has already been disposed, assignment to this property causes immediate disposal of the given disposable object.
    */
    public var disposable: Disposable {
        get {
            return self._lock.calculateLocked {
                return self._current ?? Disposables.create()
            }
        }
        // 不仅可以使用 newValue
        // 也可以指定新值得名称，此处使用了 new + 属性名
        set (newDisposable) {
            
            // 如果已经调用了释放方法，再设置新值的时候，就直接释放掉
            // 如果之前没有调用
            let disposable: Disposable? = self._lock.calculateLocked {
                if self._isDisposed {
                    return newDisposable
                } else {
                    let toDispose = self._current
                    self._current = newDisposable
                    return toDispose
                }
            }
            
            if let disposable = disposable {
                disposable.dispose()
            }
        }
    }
    
    /// Disposes the underlying disposable as well as all future replacements.
    // 将多个条件判断的，分成两个函数，将功能进行拆分
    public func dispose() {
        self._dispose()?.dispose()
    }

    private func _dispose() -> Disposable? {
        self._lock.lock(); defer { self._lock.unlock() }
        if self._isDisposed {
            return nil
        } else {
            self._isDisposed = true
            let current = self._current
            self._current = nil
            return current
        }
    }
}
