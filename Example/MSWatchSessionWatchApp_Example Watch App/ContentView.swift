//
//  ContentView.swift
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

struct ContentView: View {
    
    @EnvironmentObject var session: MSWatchSession
    
    @State var message: String = ""
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    
    let items: [String] = ["Hello", "Hola", "Ciao", "Namaste", "Bonjour"]
    
    var body: some View {
        VStack {
            List(items, id: \.self) { item in
                Button(action: {
                    itemSelected(item: item)
                }, label: {
                    Text(item)
                })
                .listItemTint(.blue)
            }
        }
        .fontWeight(.semibold)
        .padding(.horizontal)
        .padding(.top)
        .navigationTitle("Home")
        .toast(isPresented: $showToast, message: toastMessage)
        .onReceive(NotificationCenter.default.publisher(for: .messageReceivedOnWatch)) { message in
            guard let messageText = message.object as? String else {
                return
            }
            showToastMessage(messageText)
        }
    }
    
    private func itemSelected(item: String) {
        guard !item.isEmpty else {
            return
        }
        let payload: [String: AnyHashable] = [ WatchCommand.kSessionKey: item ]
        MSWatchSession.shared.send(command: WatchCommand.phoneMessage.rawValue, payload: payload)
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = "Message received: " + message
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showToast = false
        }
    }
}

#Preview {
    ContentView()
}
