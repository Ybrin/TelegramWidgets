//
//  HomeViewController.swift
//  TelegramWidgets
//
//  Created by Koray Koska on 12.10.19.
//  Copyright © 2019 Koray Koska. All rights reserved.
//

import UIKit
import TDLib
import Firebase

class HomeViewController: UIViewController {

    @IBOutlet weak var logoutButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        logoutButton.addTarget(self, action: #selector(logoutButtonClicked), for: .touchUpInside)

        Analytics.logEvent("home_screen_launched", parameters: [:])
    }

    @objc private func logoutButtonClicked() {
        Analytics.logEvent("logout", parameters: [:])

        logoutButton.isEnabled = false
        DispatchQueue(label: "Logout").async {
            ConstantHolder.coordinator.send(LogOut()).done { ok in
                self.performSegue(withIdentifier: "ShowMainStoryboard", sender: nil)
            }.catch { error in
                self.logoutButton.isEnabled = true
                print(error)
            }
        }
    }
}
