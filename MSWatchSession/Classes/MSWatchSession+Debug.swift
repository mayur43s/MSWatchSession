//
//  MSWatchSession+Debug.swift
//  https://github.com/mayur43s/MSWatchSession
//  Copyright (c) 2013-24 Mayur Shrivas.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

internal extension MSWatchSession {

    nonisolated func print(title: String, message: WatchMessage, error: Error? = nil) {
        print(title: title, info: message.json, error: error)
    }

    nonisolated func print(title: String, info: [String: Any], error: Error? = nil) {

        if JSONSerialization.isValidJSONObject(info),
           let data = try? JSONSerialization.data(withJSONObject: info, options: .prettyPrinted),
           let prettyString = String(data: data, encoding: .utf8) {
            print(title: title, string: prettyString, error: error)
        } else {
            print(title: title, string: "", error: error)
        }
    }

    nonisolated func print(title: String, string: String, error: Error? = nil) {

        if let error = error {
            Swift.print("\(self.deviceType): \(title): \(string), error: \(error)")
        } else {
            Swift.print("\(self.deviceType): \(title): \(string)")
        }
    }
}
