//
//  TwoFactorPasswordViewController.swift
//  TelegramWidgets
//
//  Created by Koray Koska on 11.10.19.
//  Copyright © 2019 Koray Koska. All rights reserved.
//

import UIKit
import TDLib
import Firebase

class TwoFactorPasswordViewController: UIViewController {

    // MARK: - Properties

    private let authorizationSubscriptionHash = "PasswordController"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!

    private var nextButton: UIBarButtonItem!

    @IBOutlet weak var viewBottomConstraint: NSLayoutConstraint!

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

                Analytics.logEvent(AnalyticsEventLogin, parameters: [
                    AnalyticsParameterMethod: "phone_number"
                ])

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
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        titleLabel.font = UIFont.systemFont(ofSize: 32)
        titleLabel.textAlignment = .center
        titleLabel.text = "Password"
        if #available(iOS 13.0, *) {
            titleLabel.textColor = UIColor.label
        } else {
            titleLabel.textColor = .black
        }

        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.text = "Type in your second factor password"
        if #available(iOS 13.0, *) {
            subtitleLabel.textColor = UIColor.secondaryLabel
        } else {
            titleLabel.textColor = .black
        }

        errorLabel.font = UIFont.systemFont(ofSize: 12)
        errorLabel.textAlignment = .natural
        errorLabel.textColor = .systemRed
        errorLabel.isHidden = true

        passwordTextField.isEnabled = false
        passwordTextField.isSecureTextEntry = true

        nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextButtonClicked))
        nextButton.isEnabled = false
        navigationItem.rightBarButtonItem = nextButton

        // Keyboard Resize
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: UIResponder.keyboardDidShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: UIResponder.keyboardDidHideNotification, object: nil)
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
            }.catch { [weak self] error in
                self?.nextButton.isEnabled = true
                self?.passwordTextField.isEnabled = true
                self?.passwordTextField.becomeFirstResponder()

                if let error = error as? TDLib.Error {
                    self?.errorLabel.text = error.message
                } else {
                    self?.errorLabel.text = "Unknown error"
                }
                self?.errorLabel.isHidden = false

                print(error)
            }
        }
    }
}

// MARK: - Keyboard Resize

extension TwoFactorPasswordViewController {

    @objc func keyboardWillShow(sender: NSNotification) {
        let info = sender.userInfo!
        let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        viewBottomConstraint.constant = keyboardSize - bottomLayoutGuide.length

        let duration: TimeInterval = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue

        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc func keyboardWillHide(sender: NSNotification) {
        let info = sender.userInfo!
        let duration: TimeInterval = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        viewBottomConstraint.constant = 0

        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
}
