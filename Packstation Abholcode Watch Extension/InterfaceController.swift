//
//  InterfaceController.swift
//  Packstation Abholcode Watch Extension
//
//  Created by Dave Nicolson on 22.05.21.
//

import WatchKit
import WatchConnectivity
import Foundation
import GTMAppAuth

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

    @IBOutlet weak var introText: WKInterfaceLabel!
    @IBOutlet weak var abholcodeGroup: WKInterfaceGroup!
    @IBOutlet weak var abholcode: WKInterfaceLabel!

    let session = WCSession.default

    @objc func applicationIsActive(_ notification: Notification) {
        updateAbholcode()
    }

    func updateAbholcode() {
        NSKeyedUnarchiver.setClass(GTMAppAuthFetcherAuthorization.self, forClassName: "GTMAppAuthFetcherAuthorizationWithEMMSupport")
        let authorizer = GTMAppAuthFetcherAuthorization(fromKeychainForName: "Gmail")

        if (authorizer != nil) {
            queryAbholcodeGmail(authorizer: authorizer!) {(code: String) in
                self.abholcode.setText(code)
                self.introText.setHidden(true)
                self.abholcodeGroup.setHidden(false)
            }
        } else {
            introText.setHidden(false)
            abholcodeGroup.setHidden(true)
        }
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        session.delegate = self
        session.activate()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationIsActive(_:)),
                                               name: .applicationIsActive,
                                               object: nil)
    }

    func addToKeychain(_ value: Data) -> Bool {
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrGeneric as String: "OAuth",
            kSecAttrAccount as String: "OAuth",
            kSecAttrService as String: "Gmail",
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: value
        ]

        var result: CFTypeRef? = nil
        let status = SecItemAdd(attributes as CFDictionary, &result)
        if status == errSecSuccess {
            print("Password successfully added to Keychain.")
        } else {
            if let error: String = SecCopyErrorMessageString(status, nil) as String? {
                if (error == "The specified item already exists in the keychain.") {
                    return true
                }
                print(error)
            }
            return false
        }
        return true
    }

    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        var reply = Data()
        if (messageData.count == 0) {
            GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: "Gmail")
        } else if (addToKeychain(messageData)) {
            reply = WKInterfaceDevice.current().name.data(using: .utf8)!
        }

        updateAbholcode()
        replyHandler(reply)
    }
}
