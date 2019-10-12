//
//  ConstantHolder.swift
//  ConversationsWidget
//
//  Created by Koray Koska on 12.10.19.
//  Copyright © 2019 Koray Koska. All rights reserved.
//

import Foundation
import TDLib

final class ConstantHolder {

    private init() {}

    static let coordinator = Coordinator(client: TDJsonClient(), apiId: 1170449, apiHash: "225ec5406d574ebec218c8b7e320e30f")
}

extension Coordinator {

    /// Initalizes a new `Coordinator` instance.
    ///
    /// - Parameters:
    ///   - client: The `TDJsonClient` used for all communcation with `tdlib` (default is new `TDJsonClient`).
    ///   - apiId: The application identifier for Telegram API access, which can be obtained at https://my.telegram.org
    ///   - apiHash: The application identifier hash for Telegram API access, which can be obtained at https://my.telegram.org
    ///   - useTestDc: If set to true, the Telegram test environment will be used instead of the production environment
    ///   - encryptionKey: The encryption key for the local database.
    public convenience init(client: TDJsonClient = TDJsonClient(),
                            apiId: Int32,
                            apiHash: String,
                            useTestDc: Bool = false,
                            encryptionKey: Data = Data(repeating: 123, count: 64)) {
        let appBundleIdentifier = Bundle.main.bundleIdentifier!
        let lastDotRange = appBundleIdentifier.range(of: ".", options: [.backwards])!
        let baseAppBundleId = String(appBundleIdentifier[..<lastDotRange.lowerBound])
        let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.\(baseAppBundleId)")
        guard let path = containerUrl?.path else {
            fatalError("Can't get document director path")
        }
        self.init(client: client, parameters: TdlibParameters.create(useTestDc: useTestDc,
                                                                     databaseDirectory: path,
                                                                     filesDirectory: path,
                                                                     apiId: apiId,
                                                                     apiHash: apiHash))
    }
}
