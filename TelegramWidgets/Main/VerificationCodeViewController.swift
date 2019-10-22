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

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var verificationCodeTextField: UITextField!
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
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        titleLabel.font = UIFont.systemFont(ofSize: 32)
        titleLabel.textAlignment = .center
        titleLabel.text = "+43"
        if #available(iOS 13.0, *) {
            titleLabel.textColor = UIColor.label
        } else {
            titleLabel.textColor = .black
        }

        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.text = "We have sent you an SMS with the code"
        if #available(iOS 13.0, *) {
            subtitleLabel.textColor = UIColor.secondaryLabel
        } else {
            titleLabel.textColor = .black
        }

        errorLabel.font = UIFont.systemFont(ofSize: 12)
        errorLabel.textAlignment = .natural
        errorLabel.textColor = .systemRed
        errorLabel.isHidden = true

        verificationCodeTextField.placeholder = "Code"
        verificationCodeTextField.isEnabled = false
        verificationCodeTextField.keyboardType = .numberPad

        nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextButtonClicked))
        nextButton.isEnabled = false
        navigationItem.rightBarButtonItem = nextButton

        // Keyboard Resize
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: UIResponder.keyboardDidShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    // MARK: - Actions

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)

        if parent == nil {
            DispatchQueue.global().async {
                ConstantHolder.coordinator.send(LogOut()).done { ok in
                    print(ok)
                }.catch { error in
                    print(error)
                }
            }
        }
    }

    @objc private func nextButtonClicked() {
        nextButton.isEnabled = false
        verificationCodeTextField.isEnabled = false
        verificationCodeTextField.resignFirstResponder()

        let text = self.verificationCodeTextField.text ?? ""
        DispatchQueue(label: "Login").async {
            ConstantHolder.coordinator.send(CheckAuthenticationCode(code: text, firstName: "", lastName: "")).done { info in
                print(info)
            }.catch { [weak self] error in
                self?.nextButton.isEnabled = true
                self?.verificationCodeTextField.isEnabled = true
                self?.verificationCodeTextField.becomeFirstResponder()

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

extension VerificationCodeViewController {

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
