//
//  ViewController.swift
//  Packstation Abholcode
//
//  Created by Dave Nicolson on 22.05.21.
//

import UIKit
import GoogleSignIn
import GTMAppAuth

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
        headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true

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
        packstationImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
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
        signOutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
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
        abholcodeLabel.bottomAnchor.constraint(equalTo: abholcodeView.bottomAnchor, constant: -10).isActive = true

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
        }
    }
}

