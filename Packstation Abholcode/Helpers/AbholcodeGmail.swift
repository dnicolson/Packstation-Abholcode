//
//  AbholcodeGmail.swift
//  Packstation Abholcode
//
//  Created by Dave Nicolson on 04.06.21.
//

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
        guard let d = Data(base64Encoded: st, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return String(data: d, encoding: .utf8)
    }
}

func queryAbholcodeGmail(authorizer: GTMFetcherAuthorizationProtocol, completion : @escaping (String) -> Void) {
    let gmailService = GTLRGmailService.init()
    // let authorizer = GIDSignIn.sharedInstance()?.currentUser?.authentication?.fetcherAuthorizer()
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

            gmailService.executeQuery(messageQuery) { (_, response, error) in
                if response != nil {
                    let message = response as! GTLRGmail_Message
                    let base64encodedData = message.payload?.parts?[0].parts?[0].body?.data!
                    let str = base64encodedData!.urlSafeBase64Decoded()!

                    let pattern = "\n([0-9]{4})"
                    let regex = try! NSRegularExpression(pattern: pattern)
                    let result = regex.firstMatch(in: str, range: NSRange(location: 0, length: str.utf16.count))
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
