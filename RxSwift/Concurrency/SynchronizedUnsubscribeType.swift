//
//  SynchronizedUnsubscribeType.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 10/25/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

protocol SynchronizedUnsubscribeType : class {
    associatedtype DisposeKey

    // 同步取消订阅
    func synchronizedUnsubscribe(_ disposeKey: DisposeKey)
}
