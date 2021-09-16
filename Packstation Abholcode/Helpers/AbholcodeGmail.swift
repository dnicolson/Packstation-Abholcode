//
//  AbholcodeGmail.swift
//  Packstation Abholcode
//
//  Created by Dave Nicolson on 04.06.21.
//

import Foundation
import GTMAppAuth
import GoogleAPIClientForREST

func queryAbholcodeGmail(authorizer: GTMFetcherAuthorizationProtocol, completion : @escaping (String) -> Void) {
    let gmailService = GTLRGmailService.init()
    // let authorizer = GIDSignIn.sharedInstance()?.currentUser?.authentication?.fetcherAuthorizer()
    gmailService.authorizer = authorizer

    let listQuery = GTLRGmailQuery_UsersMessagesList.query(withUserId: "me")
    listQuery.q = "from:noreply@dhl.de \"subject:Der Abholcode für Ihre Sendung\""
    listQuery.labelIds = ["INBOX"]

    gmailService.executeQuery(listQuery) { (_, response, error) in
        if response != nil {
            let response = response as! GTLRGmail_ListMessagesResponse
            guard response.resultSizeEstimate as! Int > 0 else {
                return
            }

            let identifier = response.messages![0].identifier
            let messageQuery = GTLRGmailQuery_UsersMessagesGet.query(withUserId: "me", identifier: identifier ?? "")
            messageQuery.identifier = identifier

            gmailService.executeQuery(messageQuery) { (_, response, error) in
                if response != nil {
                    let message = response as! GTLRGmail_Message
                    let str = message.snippet!

                    let pattern = "lautet: ([0-9]{4})"
                    let regex = try! NSRegularExpression(pattern: pattern)
                    let result = regex.firstMatch(in: str, range: NSRange(location: 0, length: str.count))
                    if result == nil {
                        print("Abholcode not found in email")
                        return
                    }

                    let range = result!.range(at: 1)
                    if let swiftRange = Range(range, in: str) {
                        let name = str[swiftRange]
                        print("Abholcode:", name)
                        completion(String(name) as String)
                    }
                } else {
                    print("Abholcode error:", error!)
                }
            }
        } else {
            print("Abholcode error:", error!)
        }
    }
}
