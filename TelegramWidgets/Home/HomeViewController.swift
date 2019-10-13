//
//  HomeViewController.swift
//  TelegramWidgets
//
//  Created by Koray Koska on 12.10.19.
//  Copyright © 2019 Koray Koska. All rights reserved.
//

import UIKit
import TDLib

class HomeViewController: UIViewController {

    @IBOutlet weak var logoutButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        logoutButton.addTarget(self, action: #selector(logoutButtonClicked), for: .touchUpInside)
    }

    @objc private func logoutButtonClicked() {
        DispatchQueue(label: "Logout").async {
            ConstantHolder.coordinator.send(LogOut()).done { ok in
                self.performSegue(withIdentifier: "ShowMainStoryboard", sender: nil)
            }.catch { error in
                print(error)
            }
        }
    }
}
