//
//  ViewController.swift
//  Packstation Abholcode
//
//  Created by Dave Nicolson on 22.05.21.
//

import UIKit
import GoogleSignIn
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

class ViewController: UIViewController {

    var headerLabel: UILabel!
    var introLabel: UILabel!
    var signInButton: GIDSignInButton!
    var signOutButton: UIButton!
    var abholcodeView: UIView!

    @objc func signOutButtonTapped(_ sender: AnyObject) {
        GIDSignIn.sharedInstance().signOut()
        GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: "Gmail")
        updateScreen()
    }

    @objc func userDidSignInGoogle(_ notification: Notification) {
        updateScreen()
        updateAbholcode()
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        overrideUserInterfaceStyle = .light

        view.backgroundColor = UIColor(red: 255/255, green: 204/255, blue: 0, alpha: 1)

        headerLabel = UILabel()
        headerLabel.text = "Packstation Abholcode"
        headerLabel.font = UIFont.boldSystemFont(ofSize: 30.0)
        headerLabel.textAlignment = .center
        view.addSubview(headerLabel)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true

        introLabel = UILabel()
        introLabel.text = "You need to sign in to Gmail to allow the Abholcode to be found."
        introLabel.textAlignment = .center
        introLabel.lineBreakMode = .byWordWrapping
        introLabel.numberOfLines = 0
        introLabel.sizeToFit()
        view.addSubview(introLabel)
        introLabel.translatesAutoresizingMaskIntoConstraints = false
        introLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        introLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 140).isActive = true
        introLabel.widthAnchor.constraint(equalToConstant: 300).isActive = true

        signInButton = GIDSignInButton()
        view.addSubview(signInButton)
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        let packstationImage = UIImage(named: "icon-packstation-red.png")
        let packstationImageView = UIImageView(image: packstationImage!)
        view.addSubview(packstationImageView)
        packstationImageView.translatesAutoresizingMaskIntoConstraints = false
        packstationImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        packstationImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25).isActive = true
        packstationImageView.widthAnchor.constraint(equalToConstant: 300).isActive = true
        packstationImageView.heightAnchor.constraint(equalToConstant: 300).isActive = true

        signOutButton = UIButton()
        signOutButton.layer.cornerRadius = 10
        signOutButton.setTitle("Sign out", for: .normal)
        signOutButton.setTitleColor(UIColor(named: "AccentColor"), for: .normal)
        signOutButton.backgroundColor = .systemFill
        signOutButton.addTarget(self, action: #selector(signOutButtonTapped(_:)), for: .touchUpInside)
        view.addSubview(signOutButton)
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signOutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15).isActive = true
        signOutButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        signOutButton.widthAnchor.constraint(equalToConstant: 150).isActive = true

        abholcodeView = UIView()
        abholcodeView.backgroundColor = .white
        abholcodeView.layer.cornerRadius = 10

        let abholcodeTextLabel = UILabel()
        abholcodeTextLabel.text = "Abholcode"
        abholcodeTextLabel.textColor = .gray
        abholcodeTextLabel.font = UIFont.boldSystemFont(ofSize: 18)
        abholcodeView.addSubview(abholcodeTextLabel)
        abholcodeTextLabel.translatesAutoresizingMaskIntoConstraints = false
        abholcodeTextLabel.centerXAnchor.constraint(equalTo: abholcodeView.centerXAnchor).isActive = true
        abholcodeTextLabel.topAnchor.constraint(equalTo: abholcodeView.topAnchor, constant: 10).isActive = true

        let abholcodeLabel = UILabel()
        abholcodeLabel.font = UIFont.boldSystemFont(ofSize: 42)
        abholcodeView.addSubview(abholcodeLabel)
        abholcodeLabel.translatesAutoresizingMaskIntoConstraints = false
        abholcodeLabel.centerXAnchor.constraint(equalTo: abholcodeView.centerXAnchor).isActive = true
        abholcodeLabel.bottomAnchor.constraint(equalTo: abholcodeView.bottomAnchor, constant: -8).isActive = true

        view.addSubview(abholcodeView)
        abholcodeView.translatesAutoresizingMaskIntoConstraints = false
        abholcodeView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        abholcodeView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        abholcodeView.widthAnchor.constraint(equalToConstant: 160).isActive = true
        abholcodeView.heightAnchor.constraint(equalToConstant: 100).isActive = true

        abholcodeView.isHidden = true

        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDidSignInGoogle(_:)),
                                               name: .signInGoogleCompleted,
                                               object: nil)

        updateScreen()
        updateAbholcode()
    }

    func updateScreen() {
        if GIDSignIn.sharedInstance()?.currentUser != nil {
            introLabel.isHidden = true
            signInButton.isHidden = true
            signOutButton.isHidden = false
        } else {
            introLabel.isHidden = false
            signInButton.isHidden = false
            signOutButton.isHidden = true
            abholcodeView.isHidden = true
        }
    }

    func updateAbholcode() {
        guard GIDSignIn.sharedInstance()?.currentUser != nil else {
            return
        }

        let abholcodeLabel = abholcodeView.subviews[1] as? UILabel
        let authorizer = GTMAppAuthFetcherAuthorization(fromKeychainForName: "Gmail")
        queryAbholcode(authorizer: authorizer!) {(code: String) in
            abholcodeLabel!.text = code
            self.abholcodeView.isHidden = false
        }
    }

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
}

