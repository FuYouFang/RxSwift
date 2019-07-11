//
//  SubscriptionDisposable.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 10/25/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

// 同步
// 1. 将需要特殊操作的类型，转化为同一个操作，
// 2. 将不同的类型转化为同一个 struct
struct SubscriptionDisposable<T: SynchronizedUnsubscribeType> : Disposable {
    private let _key: T.DisposeKey
    private weak var _owner: T?

    init(owner: T, key: T.DisposeKey) {
        self._owner = owner
        self._key = key
    }

    func dispose() {
        self._owner?.synchronizedUnsubscribe(self._key)
    }
}
