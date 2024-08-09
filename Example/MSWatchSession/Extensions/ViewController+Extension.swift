//
//  ViewController+Extension.swift
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

import UIKit

extension UIViewController {
    
    func showToast(message: String, font: UIFont = UIFont.systemFont(ofSize: 18, weight: .semibold)) {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        let toastLabel = UILabel()
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font = font
        toastLabel.text = "Message received: " + message
        toastLabel.numberOfLines = 0
        
        blurEffectView.contentView.addSubview(toastLabel)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.layer.cornerRadius = 10
        blurEffectView.clipsToBounds = true
        
        self.view.addSubview(blurEffectView)
        
        NSLayoutConstraint.activate([
            blurEffectView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            blurEffectView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            blurEffectView.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.leadingAnchor, constant: 20),
            blurEffectView.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor, constant: -20)
        ])
        
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toastLabel.leadingAnchor.constraint(equalTo: blurEffectView.contentView.leadingAnchor, constant: 10),
            toastLabel.trailingAnchor.constraint(equalTo: blurEffectView.contentView.trailingAnchor, constant: -10),
            toastLabel.topAnchor.constraint(equalTo: blurEffectView.contentView.topAnchor, constant: 10),
            toastLabel.bottomAnchor.constraint(equalTo: blurEffectView.contentView.bottomAnchor, constant: -10)
        ])
        
        blurEffectView.alpha = 0.0
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: {
            blurEffectView.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseInOut, animations: {
                blurEffectView.alpha = 0.0
            }, completion: { _ in
                blurEffectView.removeFromSuperview()
            })
        })
    }
}


