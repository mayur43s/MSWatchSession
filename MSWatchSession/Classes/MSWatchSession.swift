//
//  MSWatchSession.swift
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
@preconcurrency import WatchConnectivity

public protocol MSWatchSessionDelegate {
    func handleReceivedContext(context: [String: AnyHashable], changed: Bool)
    func sessionBecomeReachable()
    func handle(message: WatchMessage, completion: @escaping (@Sendable(_ response: [String: AnyHashable]) -> Void))
}

public final class MSWatchSession: NSObject, ObservableObject {

    @MainActor @Published private var _applicationContext: [String: AnyHashable] = [:]

    @MainActor @Published public var isReachable: Bool = false

    nonisolated public static let shared = MSWatchSession()

    private var pendingContext: [String: AnyHashable]?

    var delegate: MSWatchSessionDelegate?

#if os(watchOS)
    private var haveLatestContext: Bool = false
#endif

#if os(iOS)
    let deviceType: String = "iOS"
#elseif os(watchOS)
    let deviceType: String = "watchOS"
#else
    let deviceType: String = "Unknown OS"
#endif

    private override init() {
        super.init()
    }

    public func activate(withDelegate delegate: MSWatchSessionDelegate? = nil) {
        self.delegate = delegate
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    var isPaired: Bool? {
        guard WCSession.default.activationState == .activated else {
            return nil
        }
#if os(iOS)
        return WCSession.default.isPaired
#elseif os(watchOS)
        return true
#endif
    }

    var isCounterpartAppInstalled: Bool? {

        guard WCSession.default.activationState == .activated else {
            return nil
        }
#if os(iOS)
        return WCSession.default.isWatchAppInstalled
#elseif os(watchOS)
        if #available(watchOS 6.0, *) {
            return WCSession.default.isCompanionAppInstalled
        }
        return true
#endif
    }
}

extension MSWatchSession {

    nonisolated public func send(context: [String: AnyHashable], force: Bool = false) {

        if !force {
            let shouldSend: Bool = self.applicationContext != context

            guard shouldSend else {
                print(title: "\(#function)", string: "Nothing to update. Skip send request")
                return
            }
        }

        _handleReceivedContext(context: context, notify: false)
        pendingContext = context

        send(command: "_sendCurrentContext", payload: context, fallthrough: true, replyHandler: { result in
            switch result {
            case .success:
                self.pendingContext = nil
            case .failure:
                break
            }
        })
    }

    nonisolated public func send(command: String, payload: [String: AnyHashable]?, fallthrough: Bool = false, replyHandler: ((Swift.Result<[String : Any], Error>) -> Void)? = nil) {

        guard WCSession.default.activationState == .activated else {
            let error: NSError = NSError(domain: "MSWatchSession", code: 0, userInfo: [NSLocalizedDescriptionKey: "Watch Session not activated. Send context pending"])
            print(title: "\(#function)", string: error.localizedDescription, error: error)
            replyHandler?(.failure(error))
            return
        }

#if os(iOS)
        guard WCSession.default.isPaired else {
            let error: NSError = NSError(domain: "MSWatchSession", code: 0, userInfo: [NSLocalizedDescriptionKey: "This device is not paired with counterpart device. Send context pending"])
            print(title: "\(#function)", string: error.localizedDescription, error: error)
            replyHandler?(.failure(error))
            return
        }

        guard WCSession.default.isWatchAppInstalled else {
            let error: NSError = NSError(domain: "MSWatchSession", code: 0, userInfo: [NSLocalizedDescriptionKey: "Watch app is not installed. Send context pending"])
            print(title: "\(#function)", string: error.localizedDescription, error: error)
            replyHandler?(.failure(error))
            return
        }
#else
        if #available(watchOS 6.0, *) {
            guard WCSession.default.isCompanionAppInstalled else {
                let error: NSError = NSError(domain: "MSWatchSession", code: 0, userInfo: [NSLocalizedDescriptionKey: "Companion app is not installed. Send context pending"])
                print(title: "\(#function)", string: error.localizedDescription, error: error)
                replyHandler?(.failure(error))
                return
            }
        }
#endif

        let message = WatchMessage(command: command, payload: payload)

        print(title: "\(#function)", message: message)

        WCSession.default.sendMessage(message.json, replyHandler: { response in
            replyHandler?(.success(response))
        }, errorHandler: { error in
            guard `fallthrough` else {
                self.print(title: "\(#function)", string: error.localizedDescription, error: error)
                replyHandler?(.failure(error))
                return
            }

            self.sendViaContext(message: message, replyHandler: replyHandler)
        })
    }

    nonisolated public func sendViaContext(message: WatchMessage, replyHandler: ((Swift.Result<[String : Any], Error>) -> Void)? = nil) {

        print(title: "\(#function)", message: message)

        do {
            try WCSession.default.updateApplicationContext(message.json)
        } catch let error {
            print(title: "\(#function)", string: "", error: error)
            sendContextViaTransfer(message: message, replyHandler: replyHandler)
        }
    }

    nonisolated private func sendContextViaTransfer(message: WatchMessage, replyHandler: ((Swift.Result<[String : Any], Error>) -> Void)? = nil) {

        print(title: "\(#function)", message: message)

        WCSession.default.transferUserInfo(message.json)
    }
}

public extension MSWatchSession {

    var applicationContext: [String : AnyHashable] {
        if let context: [String: AnyHashable] = UserDefaults.standard.dictionary(forKey: "applicationContext") as? [String: AnyHashable] {
            return context
        } else {
            let context: [String: AnyHashable] = [:]
            return context
        }
    }
}

extension MSWatchSession: WCSessionDelegate {

#if os(iOS)
    nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {
        print(title: "\(#function)", string: "")
    }

    nonisolated public func sessionDidDeactivate(_ session: WCSession) {
        print(title: "\(#function)", string: "")
    }

    nonisolated public func sessionWatchStateDidChange(_ session: WCSession) {
        print(title: "\(#function)", string: "isWatchAppInstalled: \(session.isWatchAppInstalled)")

        if session.isWatchAppInstalled {
            if let pendingContext = pendingContext {
                self.pendingContext = nil
                send(context: pendingContext, force: true)
            }
        }

        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
#elseif os(watchOS)

    @available(watchOS 6.0, *)
    nonisolated public func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        print(title: "\(#function)", string: "isCompanionAppInstalled: \(session.isCompanionAppInstalled)")

        if session.isCompanionAppInstalled {
            if let pendingContext = pendingContext {
                self.pendingContext = nil
                send(context: pendingContext, force: true)
            }
        }

        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

#endif

    nonisolated public func sessionReachabilityDidChange(_ session: WCSession) {
        print(title: "\(#function)", string: "isReachable: \(session.isReachable)")

        DispatchQueue.main.async { [self] in
            self.isReachable = session.isReachable
        }

        if session.isReachable {
            if let pendingContext = pendingContext {
                self.pendingContext = nil
                send(context: pendingContext, force: true)
            }

#if os(watchOS)
            if !haveLatestContext {
                let command = "_requestCurrentContext"
                send(command: command, payload: nil, replyHandler: { result in

                    switch result {
                    case .success(let reply):
                        guard let reply = reply as? [String: AnyHashable],
                              let message = WatchMessage(message: reply) else {
                            return
                        }

                        self._handle(message: message, completion: { reply in
                            self.haveLatestContext = true
                        })
                    case .failure(let error):
                        self.print(title: "Failed: \(command)", string: "", error: error)
                    }

                })
            }

            delegate?.sessionBecomeReachable()
#endif
        }
    }

    nonisolated public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        switch activationState {
        case .notActivated:
            print(title: "\(#function)", string: "notActivated", error: error)
        case .inactive:
            print(title: "\(#function)", string: "inactive", error: error)
        case .activated:
            print(title: "\(#function)", string: "activated", error: error)

            DispatchQueue.main.async {
                self.objectWillChange.send()
            }

        @unknown default:
            print(title: "\(#function)", string: "unknown", error: error)
        }

        if activationState == .activated, let pendingContext = pendingContext {
            send(context: pendingContext, force: true)
        }
    }

    nonisolated public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {

        print(title: "\(#function)", info: message)

        guard let message = message as? [String: AnyHashable],
              let message = WatchMessage(message: message) else {
            return
        }

        _handle(message: message, completion: { _ in })
    }

    nonisolated public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print(title: "\(#function)", info: message)

        guard let message = message as? [String: AnyHashable],
                  let message = WatchMessage(message: message) else {
            replyHandler([:])
            return
        }

        _handle(message: message, completion: { reply in
            replyHandler(reply)
        })
    }

    nonisolated public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print(title: "\(#function)", info: applicationContext)

        guard let applicationContext = applicationContext as? [String: AnyHashable],
              let message = WatchMessage(message: applicationContext) else {
            return
        }

#if os(watchOS)
        if message.command == "_sendCurrentContext" {
            haveLatestContext = true
        }
#endif
        _handle(message: message, completion: { _ in })
    }

    nonisolated public func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        guard let userInfo = userInfoTransfer.userInfo as? [String: AnyHashable] else {
            return
        }

        print(title: "\(#function)", info: userInfo, error: error)

        guard let message = WatchMessage(message: userInfo) else {
            return
        }

        _handle(message: message, completion: { _ in })
    }

    nonisolated public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print(title: "\(#function)", info: userInfo)

        guard let userInfo = userInfo as? [String: AnyHashable] else {
            return
        }

        guard let message = WatchMessage(message: userInfo) else {
            return
        }

        _handle(message: message, completion: { _ in })
    }
}

private extension MSWatchSession {
    func _handle(message: WatchMessage, completion: @escaping (@Sendable(_ response: [String: AnyHashable]) -> Void)) {

        switch message.command {
        case "_requestCurrentContext":
            let message = WatchMessage(command: "_sendCurrentContext", payload: self.applicationContext)
            completion(message.json)
        case "_sendCurrentContext":
            if let context = message.payload {
                _handleReceivedContext(context: context, notify: true)
            }
            completion([:])
        default:
            delegate?.handle(message: message, completion: { _ in })
        }
    }

    func _handleReceivedContext(context: [String: AnyHashable], notify: Bool) {
        var mergedContext: [String: AnyHashable] = self.applicationContext
        mergedContext.merge(context) { (_, new) in new }
        mergedContext = mergedContext.filter { !($0.value is NSNull) }
        let changed: Bool = self.applicationContext != mergedContext
        if changed {
            UserDefaults.standard.set(mergedContext, forKey: "applicationContext")
            UserDefaults.standard.synchronize()
        }

        delegate?.handleReceivedContext(context: mergedContext, changed: changed)

        if changed && notify {
            DispatchQueue.main.async { [mergedContext] in
                self._applicationContext = mergedContext
            }
        }
    }
}
