# MSWatchSession
Lightweight library to initiate communication between watchApp with companion iOS app at ease.

[![Version](https://img.shields.io/cocoapods/v/MSWatchSession.svg?style=flat)](https://cocoapods.org/pods/MSWatchSession)
[![License](https://img.shields.io/cocoapods/l/MSWatchSession.svg?style=flat)](https://cocoapods.org/pods/MSWatchSession)
[![Platform](https://img.shields.io/cocoapods/p/MSWatchSession.svg?style=flat)](https://cocoapods.org/pods/MSWatchSession)

![Screenshot](https://raw.githubusercontent.com/mayur43s/MSWatchSession/main/Screenshot/MSWatchSessionScreenshot.png)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

| Library                | Language | Minimum iOS Target | Minimum watchOS Target | Minimum Xcode Version |
|------------------------|----------|--------------------|------------------------|-----------------------|
| MSWatchSession         | Swift    | iOS 13.0           | watchOS 7.0            | Xcode 11              |

#### Swift versions support
5.0 and above

## Installation

MSWatchSession is available through CocoaPods. To install it, simply add the following line to your Podfile:

```ruby
pod 'MSWatchSession'
```

## Usage

To initiate communication, conform both app to MSWatchSessionDelegate:-

### iOS

#### Step 1: Activate MSWatchSession

```swift
import MSWatchSession

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        MSWatchSession.shared.activate(withDelegate: self)
        return true
    }
}
```

#### Step 2: Conform MSWatchSessionDelegate

```swift
import MSWatchSession

extension AppDelegate : MSWatchSessionDelegate {

    func sessionBecomeReachable() {
    }
    
    func handleReceivedContext(context: [String: AnyHashable], changed: Bool) {
    }

    func handle(message: WatchMessage, completion: @escaping (@Sendable(_ response: [String: AnyHashable]) -> Void)) {
        guard let command = Command(rawValue: message.command) else {
            return
        }

        switch command {
        case .phoneMessage:
            if let message = message.payload?[Command.kSessionKey] as? String {
                DispatchQueue.main.async {
                    let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first

                    if let rootController = window?.rootViewController as? ViewController {
                        rootController.handlePhoneMessage(message: message)
                    }
                }
            }
            completion([:])
        case .watchMessage:
            print("receiveMessage")
            completion([:])
        }
    }
}

```

### watchOS
```swift
import SwiftUI
import MSWatchSession

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
        let command = Command.watchMessage.rawValue
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
        guard let command = Command(rawValue: message.command) else {
            return
        }

        switch command {
        case .phoneMessage:
            print("sendMessage")
            completion([:])
        case .watchMessage:
            if let message = message.payload?[Command.kSessionKey] as? String {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .messageReceivedOnWatch, object: message)
                }
            }
            completion([:])
        }
    }
}


```

## Author

Mayur Shrivas idevmayur@gmail.com

## Contributions

Any contribution is more than welcome! You can contribute through pull requests and issues on GitHub.

## License

MSWatchSession is available under the MIT license. See the LICENSE file for more info.
