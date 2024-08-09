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
```swift
import MSWatchSession

extension AppDelegate : MSWatchSessionDelegate {

    func sessionBecomeReachable() {
    }
    
    func handleReceivedContext(context: [String: AnyHashable], changed: Bool) {
    }

    func handle(message: WatchMessage, completion: @escaping (@Sendable(_ response: [String: AnyHashable]) -> Void)) {
        guard let command = WatchCommand(rawValue: message.command) else {
            return
        }

        switch command {
        case .phoneMessage:
            if let message = message.payload?[WatchCommand.kSessionKey] as? String {
                DispatchQueue.main.async {
                    let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first

                    if let rootController = window?.rootViewController as? ViewController {
                        rootController.handlePhoneMessage(message: message)
                    }
                }

            }
        case .watchMessage:
            print("receiveMessage")
        }
    }
}

```

### watchOS
```swift
import MSWatchSession

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

```

## Author

Mayur Shrivas idevmayur@gmail.com

## Contributions

Any contribution is more than welcome! You can contribute through pull requests and issues on GitHub.

## License

MSWatchSession is available under the MIT license. See the LICENSE file for more info.
