//
//  Platform.Darwin.swift
//  Platform
//
//  Created by Krunoslav Zaher on 12/29/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

    import Darwin
    import class Foundation.Thread
    import protocol Foundation.NSCopying

    extension Thread {
        // 向下面的 dictionary 中存放值
        // Thread.current.threadDictionary
        static func setThreadLocalStorageValue<T: AnyObject>(_ value: T?, forKey key: NSCopying) {
            let currentThread = Thread.current
            let threadDictionary = currentThread.threadDictionary

            if let newValue = value {
                threadDictionary[key] = newValue
            }
            else {
                threadDictionary[key] = nil
            }
        }

        // 读取 dictionary 中存放值
        // Thread.current.threadDictionary
        static func getThreadLocalStorageValueForKey<T>(_ key: NSCopying) -> T? {
            let currentThread = Thread.current
            let threadDictionary = currentThread.threadDictionary
            
            return threadDictionary[key] as? T
        }
    }

#endif
