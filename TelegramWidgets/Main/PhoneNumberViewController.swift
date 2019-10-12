//
//  PhoneNumberViewController.swift
//  TelegramWidgets
//
//  Created by Koray Koska on 11.10.19.
//  Copyright © 2019 Koray Koska. All rights reserved.
//

import UIKit
import TDLib

class PhoneNumberViewController: UIViewController {

    // MARK: - Properties

    private let authorizationSubscriptionHash = "PhoneNumberController"

    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ConstantHolder.coordinator.authorizationState.subscribe(with: authorizationSubscriptionHash, on: .main) { [weak self] event in
            guard let self = self, let state = event.value else {
                return
            }

            switch state {
            case .waitPhoneNumber:
                self.phoneNumberTextField.isEnabled = true
                self.loginButton.isEnabled = true
            case .waitCode(let isRegistered, _, _):
                if !isRegistered {
                    print("Registration is not supported")
                    return
                }
                self.redirectToCodeController()
            case .waitPassword, .ready:
                self.redirectToCodeController()
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
        phoneNumberTextField.isEnabled = false
        loginButton.isEnabled = false
        loginButton.addTarget(self, action: #selector(loginButtonClicked), for: .touchUpInside)
    }

    // MARK: - Helpers

    private func redirectToCodeController() {
        self.performSegue(withIdentifier: "ShowCodeController", sender: nil)
    }

    // MARK: - Actions

    @objc private func loginButtonClicked() {
        loginButton.isEnabled = false
        phoneNumberTextField.isEnabled = false
        phoneNumberTextField.resignFirstResponder()

        let text = self.phoneNumberTextField.text ?? ""
        DispatchQueue(label: "Login").async {
            ConstantHolder.coordinator.send(SetAuthenticationPhoneNumber(phoneNumber: text, allowFlashCall: false, isCurrentPhoneNumber: false)).done { info in
                print(info)
            }.catch { error in
                print(error)
            }
        }
    }
}
