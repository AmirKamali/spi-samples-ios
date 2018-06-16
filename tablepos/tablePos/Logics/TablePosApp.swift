//
//  TablePos.swift
//  TablePos
//
//  Created by Amir Kamali on 16/6/18.
//  Copyright © 2018 Assembly Payments. All rights reserved.
//

import Foundation
import SPIClient_iOS

class TablePosApp: NSObject {
    private static var _instance: TablePosApp = TablePosApp()
    var settings = SettingsProvider()
    var client = SPIClient()
    
    static var current: TablePosApp {
        return _instance
    }
    
    func initialize() {
        guard let eftPosAddress = settings.eftPosAddress else {
            return
        }
        guard let eftPosId = settings.posId else {
            return
        }
        if let encriptionKey = settings.encriptionKey, let hmacKey = settings.hmacKey {
            SPILogMsg("LOADED KEYS FROM USERDEFAULTS")
            SPILogMsg("KEYS \(encriptionKey):\(hmacKey)")
            client.setSecretEncKey(encriptionKey, hmacKey: hmacKey)
        }
        client.eftposAddress = eftPosAddress
        client.posId = eftPosId
        client.enablePayAtTable()
        client.config.signatureFlowOnEftpos = settings.customerSignatureromEFTPos ?? false
        client.config.promptForCustomerCopyOnEftpos = settings.customerReceiptFromEFTPos ?? false
        client.delegate = self
        
    }
    func start() {
        client.start()
    }
}
