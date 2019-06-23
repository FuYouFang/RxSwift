//
//  Result.swift
//  RxExample
//
//  Created by Krunoslav Zaher on 3/18/17.
//  Copyright © 2017 Krunoslav Zaher. All rights reserved.
//

// 服务请求结果
enum Result<T, E: Error> {
    case success(T)
    case failure(E)
}
