//
//  TwoFactorPasswordViewController.swift
//  TelegramWidgets
//
//  Created by Koray Koska on 11.10.19.
//  Copyright © 2019 Koray Koska. All rights reserved.
//

import UIKit
import TDLib

class TwoFactorPasswordViewController: UIViewController {

    // MARK: - Properties

    private let authorizationSubscriptionHash = "PasswordController"

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ConstantHolder.coordinator.authorizationState.subscribe(with: authorizationSubscriptionHash, on: .main) { event in
            guard let state = event.value else {
                return
            }

            switch state {
            case .waitPhoneNumber, .waitCode:
                self.navigationController?.popViewController(animated: true)
            case .waitPassword(let passwordHint, _, _):
                self.passwordTextField.placeholder = passwordHint
                self.passwordTextField.isEnabled = true
                self.nextButton.isEnabled = true
            case .ready:
                self.performSegue(withIdentifier: "ShowHomeController", sender: nil)
                print("Logged in :)")
            default:
                break
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        ConstantHolder.coordinator.authorizationState.unsubscribe(authorizationSubscriptionHash)
    }

    // MARK: - UI setup

    private func setupUI() {
        passwordTextField.isEnabled = false
        passwordTextField.isSecureTextEntry = true
        nextButton.isEnabled = false

        nextButton.addTarget(self, action: #selector(nextButtonClicked), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func nextButtonClicked() {
        nextButton.isEnabled = false
        passwordTextField.isEnabled = false
        passwordTextField.resignFirstResponder()

        let text = self.passwordTextField.text ?? ""
        DispatchQueue(label: "Login").async {
            ConstantHolder.coordinator.send(CheckAuthenticationPassword(password: text)).done { info in
                print(info)
            }.catch { error in
                print(error)
            }
        }
    }
}
