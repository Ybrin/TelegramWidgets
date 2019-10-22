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

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var errorTextField: UILabel!
    private var loginButton: UIBarButtonItem!

    @IBOutlet weak var viewBottomConstraint: NSLayoutConstraint!

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        phoneNumberTextField.perform(
            #selector(becomeFirstResponder),
            with: nil,
            afterDelay: 0.1
        )

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
                    self.errorTextField.text = "Registration is not supported"
                    self.errorTextField.isHidden = false

                    self.phoneNumberTextField.isEnabled = true
                    self.loginButton.isEnabled = true

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
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        titleLabel.font = UIFont.systemFont(ofSize: 32)
        titleLabel.textAlignment = .center
        titleLabel.text = "Your Phone"
        if #available(iOS 13.0, *) {
            titleLabel.textColor = UIColor.label
        } else {
            titleLabel.textColor = .black
        }

        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.text = "Please enter your phone number in international format."
        if #available(iOS 13.0, *) {
            subtitleLabel.textColor = UIColor.secondaryLabel
        } else {
            titleLabel.textColor = .black
        }

        errorTextField.font = UIFont.systemFont(ofSize: 12)
        errorTextField.textAlignment = .natural
        errorTextField.textColor = .systemRed
        errorTextField.isHidden = true

        phoneNumberTextField.placeholder = "Your phone number"
        phoneNumberTextField.isEnabled = false
        phoneNumberTextField.keyboardType = .phonePad

        loginButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(loginButtonClicked))
        loginButton.isEnabled = false
        navigationItem.rightBarButtonItem = loginButton

        // Keyboard Resize
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: UIResponder.keyboardDidShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    // MARK: - Helpers

    private func redirectToCodeController() {
        self.performSegue(withIdentifier: "ShowCodeController", sender: nil)
    }

    // MARK: - Actions

    @objc private func loginButtonClicked() {
        guard let text = self.phoneNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return
        }

        loginButton.isEnabled = false
        phoneNumberTextField.isEnabled = false
        phoneNumberTextField.resignFirstResponder()

        DispatchQueue(label: "Login").async {
            ConstantHolder.coordinator.send(SetAuthenticationPhoneNumber(phoneNumber: text, allowFlashCall: false, isCurrentPhoneNumber: false)).done { info in
                print(info)
            }.catch { [weak self] error in
                self?.loginButton.isEnabled = true
                self?.phoneNumberTextField.isEnabled = true
                self?.phoneNumberTextField.becomeFirstResponder()

                if let error = error as? TDLib.Error {
                    self?.errorTextField.text = error.message
                } else {
                    self?.errorTextField.text = "Unknown error"
                }
                self?.errorTextField.isHidden = false

                print(error)
            }
        }
    }
}

// MARK: - Keyboard Resize

extension PhoneNumberViewController {

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
