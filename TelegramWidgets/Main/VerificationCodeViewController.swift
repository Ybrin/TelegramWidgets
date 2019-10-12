//
//  VerificationCodeViewController.swift
//  TelegramWidgets
//
//  Created by Koray Koska on 11.10.19.
//  Copyright © 2019 Koray Koska. All rights reserved.
//

import UIKit
import TDLib

class VerificationCodeViewController: UIViewController {

    // MARK: - Properties

    private let authorizationSubscriptionHash = "CodeController"

    @IBOutlet weak var verificationCodeTextField: UITextField!
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
            case .waitPhoneNumber:
                self.navigationController?.popViewController(animated: true)
            case .waitCode(_, _, _):
                self.verificationCodeTextField.isEnabled = true
                self.nextButton.isEnabled = true
            case .waitPassword(_, _, _):
                self.performSegue(withIdentifier: "ShowPasswordController", sender: nil)
            case .ready:
                self.performSegue(withIdentifier: "ShowHomeController", sender: nil)
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
        verificationCodeTextField.isEnabled = false
        nextButton.isEnabled = false

        nextButton.addTarget(self, action: #selector(nextButtonClicked), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func nextButtonClicked() {
        nextButton.isEnabled = false
        verificationCodeTextField.isEnabled = false
        verificationCodeTextField.resignFirstResponder()

        let text = self.verificationCodeTextField.text ?? ""
        DispatchQueue(label: "Login").async {
            ConstantHolder.coordinator.send(CheckAuthenticationCode(code: text, firstName: "", lastName: "")).done { info in
                print(info)
            }.catch { error in
                print(error)
            }
        }
    }
}
