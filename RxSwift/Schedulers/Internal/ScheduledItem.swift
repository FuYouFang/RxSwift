//
//  ScheduledItem.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 9/2/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

// 将需要被调度的方法和参数进行封装
// 通过调用 invoke 开始执行
struct ScheduledItem<T>: ScheduledItemType, InvocableType {
    typealias Action = (T) -> Disposable
    
    private let _action: Action
    private let _state: T

    private let _disposable = SingleAssignmentDisposable()

    var isDisposed: Bool {
        return self._disposable.isDisposed
    }
    
    init(action: @escaping Action, state: T) {
        self._action = action
        self._state = state
    }
    
    func invoke() {
         self._disposable.setDisposable(self._action(self._state))
    }
    
    func dispose() {
        self._disposable.dispose()
    }
}
