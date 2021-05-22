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

    @IBAction func didTapSignOut(_ sender: AnyObject) {
        GIDSignIn.sharedInstance().signOut()
        GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: "Gmail")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        GIDSignIn.sharedInstance()?.presentingViewController = self

        // Automatically sign in the user.
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
    }


}

