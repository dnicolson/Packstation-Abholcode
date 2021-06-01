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
import WatchConnectivity

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

class ViewController: UIViewController, WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
    }

    func sessionDidDeactivate(_ session: WCSession) {
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

    var headerLabel: UILabel!
    var introLabel: UILabel!
    var signInButton: GIDSignInButton!
    var signOutButton: UIButton!
    var abholcodeView: UIView!
    var session: WCSession?

    @objc func signOutButtonTapped(_ sender: AnyObject) {
        GIDSignIn.sharedInstance().signOut()
        GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: "Gmail")
        sendKeychainItemToWatch(keychainItemData: Data())
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "WatchGmailAuth")
        updateScreen()
    }

    @objc func userDidSignInGoogle(_ notification: Notification) {
        updateScreen()
        updateAbholcode()
        sendKeychainItemToWatch(keychainItemData: getKeychainItemData()!)
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground(_:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)
    }

    @objc func applicationWillEnterForeground(_ notification: NSNotification) {
        updateAbholcode()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }

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
        let defaults = UserDefaults.standard
        if (defaults.bool(forKey: "WatchGmailAuth")) {
            introLabel.text = "The Abholcode is also available on your Apple Watch."
        } else {
            introLabel.text = "You need to sign in to Gmail to allow the Abholcode to be found. The Abholcode will also be available on a paired Apple Watch."
        }
        introLabel.textAlignment = .center
        introLabel.lineBreakMode = .byWordWrapping
        introLabel.numberOfLines = 0
        introLabel.sizeToFit()
        view.addSubview(introLabel)
        introLabel.translatesAutoresizingMaskIntoConstraints = false
        introLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        introLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 140).isActive = true
        introLabel.widthAnchor.constraint(equalToConstant: 300).isActive = true
        introLabel.isHidden = true

        signInButton = GIDSignInButton()
        view.addSubview(signInButton)
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        signInButton.isHidden = true

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

    func getKeychainItemData() -> Data? {
        let getquery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                       kSecAttrGeneric as String: "OAuth",
                                       kSecAttrAccount as String: "OAuth",
                                       kSecAttrService as String: "Gmail",
                                       kSecReturnData as String: kCFBooleanTrue!,
                                       kSecMatchLimit as String : kSecMatchLimitOne]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &item)

        guard status == errSecSuccess else {
            print("keyStore.retrieve SecItemCopyMatching error \(status)")
            return nil
        }

        guard let data = item as? Data? else {
            print("keyStore.retrieve not data")
            return nil
        }

        return data
    }

    func sendKeychainItemToWatch(keychainItemData: Data) {
        session!.sendMessageData(keychainItemData, replyHandler: { (data) in
            let success = data[0] == 1
            let defaults = UserDefaults.standard
            defaults.set(success, forKey: "WatchGmailAuth")}) { (error) in
                print(error)
        }
    }
}

