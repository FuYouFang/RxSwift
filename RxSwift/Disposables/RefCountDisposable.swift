//
//  RefCountDisposable.swift
//  RxSwift
//
//  Created by Junior B. on 10/29/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

/// Represents a disposable resource that only disposes its underlying disposable resource when all dependent disposable objects have been disposed.
/// 内部有一个需要管理的 disposable，
/// 所有依赖这个 disposable 的调用 dispose 方法，并且它本身调用 dispose 方法之后，才会真正的销毁个对象
public final class RefCountDisposable : DisposeBase, Cancelable {
    private var _lock = SpinLock()
    // nil 的另一种指定类型的方法
    private var _disposable = nil as Disposable?
    private var _primaryDisposed = false
    private var _count = 0

    /// - returns: Was resource disposed.
    public var isDisposed: Bool {
        self._lock.lock(); defer { self._lock.unlock() }
        return self._disposable == nil
    }

    /// Initializes a new instance of the `RefCountDisposable`.
    public init(disposable: Disposable) {
        self._disposable = disposable
        super.init()
    }

    /**
     Holds a dependent disposable that when disposed decreases the refcount on the underlying disposable.

     When getter is called, a dependent disposable contributing to the reference count that manages the underlying disposable's lifetime is returned.
     
     引用计数加一
     返回一个指向指向自己的子类，
     调用子类的释放方法，会来减少主类的索引数量
     */  
    public func retain() -> Disposable {
        return self._lock.calculateLocked {
            if self._disposable != nil {
                do {
                    _ = try incrementChecked(&self._count)
                } catch {
                    rxFatalError("RefCountDisposable increment failed")
                }

                return RefCountInnerDisposable(self)
            } else {
                return Disposables.create()
            }
        }
    }

    /// Disposes the underlying disposable only when all dependent disposables have been disposed.
    /// 引用计数为 0，也就是所有依赖都调用 dispose 之后，才会真正的销毁
    public func dispose() {
        let oldDisposable: Disposable? = self._lock.calculateLocked {
            if let oldDisposable = self._disposable, !self._primaryDisposed {
                self._primaryDisposed = true

                if self._count == 0 {
                    self._disposable = nil
                    return oldDisposable
                }
            }

            return nil
        }

        if let disposable = oldDisposable {
            disposable.dispose()
        }
    }

    fileprivate func release() {
        let oldDisposable: Disposable? = self._lock.calculateLocked {
            if let oldDisposable = self._disposable {
                do {
                    _ = try decrementChecked(&self._count)
                } catch {
                    rxFatalError("RefCountDisposable decrement on release failed")
                }

                guard self._count >= 0 else {
                    rxFatalError("RefCountDisposable counter is lower than 0")
                }

                //
                if self._primaryDisposed && self._count == 0 {
                    self._disposable = nil
                    return oldDisposable
                }
            }

            return nil
        }

        if let disposable = oldDisposable {
            disposable.dispose()
        }
    }
}

internal final class RefCountInnerDisposable: DisposeBase, Disposable
{
    private let _parent: RefCountDisposable
    private let _isDisposed = AtomicInt(0)

    init(_ parent: RefCountDisposable) {
        self._parent = parent
        super.init()
    }

    internal func dispose()
    {
        if fetchOr(self._isDisposed, 1) == 0 {
            self._parent.release()
        }
    }
}
