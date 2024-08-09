//
//  MSWatchSessionWatchApp_ExampleApp.swift
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

import SwiftUI
import MSWatchSession

@main
struct WatchSessionWatchApp_Watch_AppApp: App {
    
    let watchSession = MSWatchSession.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .onAppear {
                self.watchSession.activate(withDelegate: self)
            }
            .environmentObject(watchSession)
        }
    }
}

extension WatchSessionWatchApp_Watch_AppApp: MSWatchSessionDelegate {

    func sessionBecomeReachable() {
        let command = WatchCommand.watchMessage.rawValue
        MSWatchSession.shared.send(command: command, payload: nil, replyHandler: { result in

            switch result {
            case .success(let reply):
                guard let reply = reply as? [String: AnyHashable],
                        let message = WatchMessage(message: reply) else {
                    return
                }

                self.handle(message: message, completion: { _ in })
            case .failure(let error):
                break
            }
        })
    }
    
    func handleReceivedContext(context: [String: AnyHashable], changed: Bool) {
    }

    func handle(message: WatchMessage, completion: @escaping (@Sendable(_ response: [String: AnyHashable]) -> Void)) {
        guard let command = WatchCommand(rawValue: message.command) else {
            return
        }

        switch command {
        case .phoneMessage:
            print("sendMessage")
        case .watchMessage:
            if let message = message.payload?[WatchCommand.kSessionKey] as? String {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .messageReceivedOnWatch, object: message)
                }
            }
        }
    }
}
