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
import GoogleAPIClientForREST

extension String {
    func urlSafeBase64Decoded() -> String? {
        var st = self
            .replacingOccurrences(of: "_", with: "/")
            .replacingOccurrences(of: "-", with: "+")
        let remainder = self.count % 4
        if remainder > 0 {
            st = self.padding(toLength: self.count + 4 - remainder,
                              withPad: "=",
                              startingAt: 0)
        }
        guard let d = Data(base64Encoded: st, options: .ignoreUnknownCharacters) else{
            return nil
        }
        return String(data: d, encoding: .utf8)
    }
}

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

    @IBOutlet weak var introText: WKInterfaceLabel!
    @IBOutlet weak var abholcodeGroup: WKInterfaceGroup!
    @IBOutlet weak var abholcode: WKInterfaceLabel!

    func queryAbholcode(authorizer: GTMFetcherAuthorizationProtocol, completion : @escaping (String) -> Void) {
        let gmailService = GTLRGmailService.init()
        //let authorizer = GIDSignIn.sharedInstance()?.currentUser?.authentication?.fetcherAuthorizer()
        gmailService.authorizer = authorizer

        let listQuery = GTLRGmailQuery_UsersMessagesList.query(withUserId: "me")
        listQuery.q = "from:noreply.packstation@dhl.de subject:Abholcode"
        listQuery.labelIds = ["INBOX"]

        gmailService.executeQuery(listQuery) { (ticket, response, error) in
            if response != nil {
                let response = response as! GTLRGmail_ListMessagesResponse
                let identifier = response.messages![0].identifier
                let messageQuery = GTLRGmailQuery_UsersMessagesGet.query(withUserId: "me", identifier: identifier ?? "")
                messageQuery.identifier = identifier

                gmailService.executeQuery(messageQuery) { (ticket, response, error) in
                    if response != nil {
                        let message = response as! GTLRGmail_Message
                        let base64encodedData = message.payload?.parts?[0].parts?[0].body?.data!
                        let str = base64encodedData!.urlSafeBase64Decoded()!

                        let pattern = "\n([0-9]{4})"
                        let regex = try! NSRegularExpression(pattern: pattern)
                        let result = regex.firstMatch(in:str, range:NSMakeRange(0, str.utf16.count))
                        let range = result!.range(at:1)
                        if let swiftRange = Range(range, in: str) {
                            let name = str[swiftRange]
                            print(name)
                            completion(String(name) as String)
                        }
                    } else {
                        print("Error: ")
                        print(error!)
                    }
                }
            } else {
                print("Error: ")
                print(error!)
            }
        }
    }

    let session = WCSession.default

    func updateAbholcode() {
        NSKeyedUnarchiver.setClass(GTMAppAuthFetcherAuthorization.self, forClassName: "GTMAppAuthFetcherAuthorizationWithEMMSupport")
        let authorizer = GTMAppAuthFetcherAuthorization(fromKeychainForName: "Gmail")

        if (authorizer != nil) {
            queryAbholcode(authorizer: authorizer!) {(code: String) in
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

        updateAbholcode()
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
