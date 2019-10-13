//
//  TodayViewController.swift
//  ConversationsWidget
//
//  Created by Koray Koska on 12.10.19.
//  Copyright © 2019 Koray Koska. All rights reserved.
//

import UIKit
import NotificationCenter
import TDLib
import PromiseKit
import LetterAvatarKit
import BadgeSwift

class TodayViewController: UIViewController, NCWidgetProviding {

    // MARK: - Properties

    private let authorizationSubscriptionHash = "TodayViewController"

    private let queue = DispatchQueue(label: "TodayViewController")

    private var authorized = false

    @IBOutlet weak var chat0View: UIView!
    @IBOutlet weak var chat0Image: UIImageView!
    @IBOutlet weak var chat0Name: UILabel!
    @IBOutlet weak var chat0Badge: BadgeSwift!
    
    @IBOutlet weak var chat1View: UIView!
    @IBOutlet weak var chat1Image: UIImageView!
    @IBOutlet weak var chat1Name: UILabel!
    @IBOutlet weak var chat1Badge: BadgeSwift!

    @IBOutlet weak var chat2View: UIView!
    @IBOutlet weak var chat2Image: UIImageView!
    @IBOutlet weak var chat2Name: UILabel!
    @IBOutlet weak var chat2Badge: BadgeSwift!

    @IBOutlet weak var chat3View: UIView!
    @IBOutlet weak var chat3Image: UIImageView!
    @IBOutlet weak var chat3Name: UILabel!
    @IBOutlet weak var chat3Badge: BadgeSwift!

    private var cachedChats: [GetChat.Result] = []

    // MARK: - Initialization
        
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        print("????")

        runOrWaitForAuth { authorized in
            if authorized {
                self.getConversations(completionHandler: completionHandler)
            } else {
                completionHandler(.noData)
            }
        }
    }

    // MARK: - UI setup

    private func setupUI() {
        let imageViews: [UIImageView] = [chat0Image, chat1Image, chat2Image, chat3Image]
        for im in imageViews {
            im.layer.cornerRadius = im.frame.size.width / 2
            im.clipsToBounds = true
            im.backgroundColor = UIColor(red: 0 / 255, green: 136 / 255, blue: 204 / 255, alpha: 1)
        }

        let labels: [UILabel] = [chat0Name, chat1Name, chat2Name, chat3Name]
        for l in labels {
            l.textAlignment = .center
            l.font = l.font.withSize(12)
            l.lineBreakMode = .byTruncatingTail
            l.text = "-"
        }

        let views: [UIView] = [chat0View, chat1View, chat2View, chat3View]
        for v in views {
            v.isUserInteractionEnabled = true
            v.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(chatViewClicked(_:))))
        }

        let badges: [BadgeSwift] = [chat0Badge, chat1Badge, chat2Badge, chat3Badge]
        for b in badges {
            b.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
            b.textColor = UIColor.white
            b.shadowOpacityBadge = 0
            b.text = "0"
            b.isHidden = true
        }
    }

    // MARK: - Helpers

    private func runOrWaitForAuth(_ callback: @escaping (_ authorized: Bool) -> Void) {
        DispatchQueue.main.async {
            if self.authorized {
                callback(true)
            } else {
                ConstantHolder.coordinator.authorizationState.subscribe(with: self.authorizationSubscriptionHash, on: .main) { [weak self] event in
                    guard let self = self, let state = event.value else {
                        callback(false)
                        return
                    }

                    switch state {
                    case .waitPhoneNumber, .waitCode, .waitPassword:
                        callback(false)
                        ConstantHolder.coordinator.authorizationState.unsubscribe(self.authorizationSubscriptionHash)
                    case .ready:
                        self.authorized = true
                        callback(true)
                        ConstantHolder.coordinator.authorizationState.unsubscribe(self.authorizationSubscriptionHash)
                    default:
                        break
                    }
                }
            }
        }
    }

    private func getConversations(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        queue.async {
            ConstantHolder.coordinator.send(GetChats(offsetOrder: "9223372036854775807", offsetChatId: 0, limit: 4)).then(on: self.queue) { chats -> Promise<[GetChat.Result]> in
                var getChatPromises: [Promise<GetChat.Result>] = []
                let chatIds = chats.chatIds
                for id in chatIds {
                    getChatPromises.append(ConstantHolder.coordinator.send(GetChat(chatId: id)))
                }

                return when(fulfilled: getChatPromises)
            }.done { [weak self] chats in
                self?.setConversations(chats: chats)
                completionHandler(.newData)
            }.catch { error in
                completionHandler(.failed)
                print(error)
            }
        }
    }

    private func setConversations(chats: [GetChat.Result]) {
        // Set chats for redirct
        cachedChats = chats

        let chatElements: [(image: UIImageView, label: UILabel, badge: BadgeSwift)] = [
            (chat0Image, chat0Name, chat0Badge),
            (chat1Image, chat1Name, chat1Badge),
            (chat2Image, chat2Name, chat2Badge),
            (chat3Image, chat3Name, chat3Badge)
        ]

        for i in 0..<chats.count {
            guard chatElements.count > i else {
                continue
            }

            let chat = chats[i]
            let elements = chatElements[i]

            // Name
            elements.label.text = chat.title

            // Badge
            if chat.unreadCount > 0 {
                elements.badge.isHidden = false
                elements.badge.text = "\(chat.unreadCount)"
            } else {
                elements.badge.isHidden = true
                elements.badge.text = "0"
            }

            // Image
            if let file = chat.photo?.small {
                if file.local.path.isEmpty {
                    queue.async {
                        ConstantHolder.coordinator.download(file: file).subscribe(on: .main) { event in
                            switch event {
                            case .completed(let image):
                                elements.image.image = UIImage(contentsOfFile: image.local.path)
                            default:
                                break
                            }
                        }
                    }
                } else {
                    elements.image.image = UIImage(contentsOfFile: file.local.path)
                }
            } else {
                // Default avatar with initial
                let circleAvatarImage = LetterAvatarMaker()
                    .setCircle(true)
                    .setUsername(chat.title)
                    .build()
                elements.image.image = circleAvatarImage
            }
        }
    }

    // MARK: - Actions

    @objc private func chatViewClicked(_ sender: UITapGestureRecognizer) {
        let view = sender.view

        let views: [UIView] = [
            chat0View, chat1View, chat2View, chat3View
        ]

        let cachedChats = self.cachedChats
        for i in 0..<views.count {
            if views[i] === view && cachedChats.count > i {
                let chat = cachedChats[i]

                let urlString: String
                switch chat.type {
                case .private(let userId):
                    urlString = "tg://localpeer?id=\(userId)"
                case .secret(let secretChatId, _):
                    urlString = "tg://localpeer?id=\(secretChatId)"
                case .basicGroup(let basicGroupId):
                    urlString = "tg://resolve?domain=\(basicGroupId)"
                case .supergroup(let supergroupId, _):
                    urlString = "tg://resolve?domain=\(supergroupId)"
                }

                guard let url = URL(string: urlString) else {
                    continue
                }
                extensionContext?.open(url)
            }
        }
    }
}
