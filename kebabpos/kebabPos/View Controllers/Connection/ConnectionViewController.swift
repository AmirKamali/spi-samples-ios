//
//  ConnectionViewController.swift
//  kebabPos
//
//  Created by Amir Kamali on 27/5/18.
//  Copyright © 2018 Assembly Payments. All rights reserved.
//

import UIKit
import SPIClient_iOS
class ConnectionViewController: UITableViewController,NotificationListener {
    @IBOutlet weak var txt_output: UITextView!
    @IBOutlet weak var txt_posId: UITextField!
    @IBOutlet weak var txt_posAddress: UITextField!
    
    @IBAction func pairButtonClicked(_ sender: Any) {
        KebabApp.current.settings.posId = txt_posId.text
        KebabApp.current.settings.eftPosAddress = txt_posAddress.text
        KebabApp.current.client.pair()
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForEvents(appEvents: [.connectionStatusChanged,.pairingFlowChanged,.transactionFlowStateChanged])
        txt_posId.text = KebabApp.current.settings.posId
        txt_posAddress.text = KebabApp.current.settings.eftPosAddress

    }
    @objc
    func onNotificationArrived(notification:NSNotification){
        switch notification.name.rawValue {
        case AppEvent.connectionStatusChanged.rawValue:
            if let state = notification.object as? SPIState {
                printStatusAndAction(state)
            }
        case AppEvent.pairingFlowChanged.rawValue:
            if let state = notification.object as? SPIState {
                printStatusAndAction(state)
            }
        case AppEvent.transactionFlowStateChanged.rawValue:
            if let state = notification.object as? SPIState {
                printStatusAndAction(state)
            }
        default:
            return
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return super.numberOfSections(in: tableView)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    func printStatusAndAction(_ state: SPIState?) {
        SPILogMsg("printStatusAndAction \(String(describing: state))")
        
        guard let state = state else { return }
        
        switch state.status {
            
        case .unpaired:
            
            switch state.flow {
            case .idle:
                SPILogMsg("# [pos_id:MYPOSNAME] - sets your POS instance ID")
                SPILogMsg("# [eftpos_address:10.10.10.10] - sets IP address of target EFTPOS")
                SPILogMsg("# [pair] - start pairing")
                
            case .pairing:
                showPairing(state)
                
            default:
                showError("# .. Unexpected Flow .. \(KebabApp.current.client.state.flow.rawValue)")
            }
            
        case .pairedConnecting, .pairedConnected:
            SPILogMsg("status .connected, flow=\(state.flow.rawValue)")
            
            switch state.flow {
            case .idle:
                break
                
            case .transaction:
                showConnectedTx(KebabApp.current.client.state)
                
            case .pairing: // Paired, Pairing - we have just finished the pairing flow. OK to ack.
                showPairing(KebabApp.current.client.state)
            }
        }
    }
    var alertVC: UIAlertController?
    func showPairing(_ state: SPIState) {
        SPILogMsg("showPairing")
        
        guard let pairingFlowState = state.pairingFlowState else {
            return showError("Missing pairingFlowState \(state)")
        }
        if let oldAlertVc = self.alertVC{
            oldAlertVc.dismiss(animated: false, completion: nil)
        }
        let alertVC = UIAlertController(title: "EFTPOS PAIRING PROCESS", message: pairingFlowState.message, preferredStyle: .alert)
        self.alertVC = alertVC
        
        
        if pairingFlowState.isAwaitingCheckFromPos {
            SPILogMsg("# [pair_confirm] - confirm the code matches")
            
            alertVC.addAction(UIAlertAction(title: "NO", style: .cancel, handler: { (action) in
                self.pairingCancel()
            }))
            
            alertVC.addAction(UIAlertAction(title: "YES", style: .default, handler: { action in
                KebabApp.current.client.pairingConfirmCode()
            }))
            
            
        } else if !pairingFlowState.isFinished {
            SPILogMsg("# [pair_cancel] - cancel pairing process")
            
            alertVC.addAction(UIAlertAction(title: "CANCEL", style: .cancel, handler: { action in
                self.pairingCancel()
            }))
            
        } else if pairingFlowState.isSuccessful {
            SPILogMsg("# [ok] - acknowledge pairing")
            
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.acknowledge()
            }))
            
        } else {
            // error
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }
        DispatchQueue.main.async {
        self.present(alertVC, animated: true, completion: nil)
        }
        
        
    }
    @IBAction func pairingCancel() {
        KebabApp.current.client.pairingCancel()
    }
    func txFlowStateString(_ txFlowState: SPITransactionFlowState) -> String {
        var buffer = "# Id: \(txFlowState.tid ?? "")\n"
        buffer += "# Type: \(SPITransactionFlowState.txTypeString(txFlowState.type)!)\n"
        buffer += "# RequestSent: \(txFlowState.isRequestSent)\n"
        buffer += "# WaitingForSignature: \(txFlowState.isAwaitingSignatureCheck)\n"
        buffer += "# Attempting to Cancel: \(txFlowState.isAttemptingToCancel)\n"
        buffer += "# Finished: \(txFlowState.isFinished)\n"
        buffer += "# Success: \(SPIMessage.successState(toString:txFlowState.successState)!)\n"
        buffer += "# Display Message: \(txFlowState.displayMessage ?? "")\n"
        
        if txFlowState.isAwaitingSignatureCheck {
            // We need to print the receipt for the customer to sign.
            self.appendReceipt(txFlowState.signatureRequiredMessage.getMerchantReceipt())
        }
        
        // If the transaction is finished, we take some extra steps.
        if txFlowState.isFinished {
            
            if txFlowState.successState == .unknown {
                // TH-4T, TH-4N, TH-2T - This is the dge case when we can't be sure what happened to the transaction.
                // Invite the merchant to look at the last transaction on the EFTPOS using the dicumented shortcuts.
                // Now offer your merchant user the options to:
                // A. Retry the transaction from scrtatch or pay using a different method - If Merchant is confident that tx didn't go through.
                // B. Override Order as Paid in you POS - If Merchant is confident that payment went through.
                // C. Cancel out of the order all together - If the customer has left / given up without paying
                buffer += "# NOT SURE IF WE GOT PAID OR NOT. CHECK LAST TRANSACTION MANUALLY ON EFTPOS!\n"
                buffer += "# RETRY (TH-5R), OVERRIDE AS PAID (TH-5D), CANCEL (TH-5C)\n"
            } else {
                
                // We have a result...
                switch txFlowState.type {
                    // Depending on what type of transaction it was, we might act diffeently or use different data.
                    
                case .purchase:
                    
                    if txFlowState.response != nil {
                        if let purchaseResponse = SPIPurchaseResponse(message: txFlowState.response) {
                            buffer += "# Scheme: \(purchaseResponse.schemeName)\n"
                            buffer += "# Response: \(purchaseResponse.getText() ?? "")\n"
                            buffer += "# RRN: \(purchaseResponse.getRRN() ?? "")\n"
                            
                            if let error = txFlowState.response.error {
                                buffer += "# Error: \(error)\n"
                            }
                            
                            self.appendReceipt(purchaseResponse.getCustomerReceipt())
                        }
                    } else {
                        // We did not even get a response, like in the case of a time-out.
                    }
                    
                    if txFlowState.isFinished && txFlowState.successState == .success {
                        // TH-6A
                        buffer += "# HOORAY WE GOT PAID (TH-7A). CLOSE THE ORDER!\n"
                        
                    } else {
                        // TH-6E
                        buffer += "# WE DIDN'T GET PAID. RETRY PAYMENT (TH-5R) OR GIVE UP (TH-5C)!\n"
                    }
                    
                case .refund:
                    if txFlowState.response != nil {
                        if let refundResponse = SPIRefundResponse(message: txFlowState.response) {
                            buffer += "# Scheme: \(refundResponse.schemeName)\n"
                            buffer += "# Response: \(refundResponse.getText)\n"
                            buffer += "# RRN: \(refundResponse.getRRN)\n"
                            buffer += "# Customer Receipt:\n"
                            self.appendReceipt(refundResponse.getCustomerReceipt())
                        }
                        
                        if let error = txFlowState.response.error {
                            buffer += "# Error: \(error)\n"
                        }
                        
                    } else {
                        // We did not even get a response, like in the case of a time-out.
                    }
                    
                case .settle:
                    
                    if let response = txFlowState.response, let settleResponse = SPISettlement(message: response) {
                        buffer += "# Response: \(settleResponse.getResponseText())\n"
                        
                        if let error = txFlowState.response.error {
                            buffer += "# Error: \(error)\n"
                        }
                        
                        self.appendReceipt(settleResponse.getReceipt())
                    } else {
                        // We did not even get a response, like in the case of a time-out.
                    }
                    
                case .getLastTransaction:
                    
                    if let response = txFlowState.response, let gltResponse = SPIGetLastTransactionResponse(message: response) {
                        buffer += "# Type: \(gltResponse.getTxType())\n"
                        buffer += "# Amount: \(gltResponse.getAmount())\n"
                        buffer += "# Success State: \(gltResponse.successState)\n"
                        
                        if let error = txFlowState.response.error {
                            buffer += "# Error: \(error)\n"
                        }
                    } else {
                        // We did not even get a response, like in the case of a time-out.
                    }
                }
            }
        }
        
        return buffer
    }
    func acknowledge() {
        SPILogMsg("acknowledge")
        
        KebabApp.current.client.ackFlowEndedAndBack { [weak self] alreadyMovedToIdleState, state in
            guard let `self` = self else { return }
            self.printStatusAndAction(KebabApp.current.client.state)
        }
    }
    func showConnectedTx(_ state: SPIState) {
        SPILogMsg("showConnectedTx")
        
        guard let txFlowState = state.txFlowState else {
            showError("Missing txFlowState \(state)")
            return
        }
        let alertVC = UIAlertController(title: "Title", message: txFlowState.displayMessage, preferredStyle: .alert)
        
            if (txFlowState.successState == .failed) {
                SPILogMsg("# [ok] - acknowledge fail")
                
                alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { alert in
                    self.acknowledge()
                }))
                
            } else {
                
                if txFlowState.isAwaitingSignatureCheck {
                    SPILogMsg("# [tx_sign_accept] - Accept Signature")
                    SPILogMsg("# [tx_sign_decline] - Decline Signature")
                    
                    alertVC.addAction(UIAlertAction(title: "Accept Signature", style: .default, handler: { action in
                        KebabApp.current.client.acceptSignature(true)
                    }))
                    
                    alertVC.addAction(UIAlertAction(title: "Decline Signature", style: .default, handler: { action in
                        KebabApp.current.client.acceptSignature(false)
                    }))
                }
                
                if !txFlowState.isFinished {
                    SPILogMsg("# [tx_cancel] - Attempt to Cancel Transaction")
                    
                    if !state.txFlowState.isAttemptingToCancel {
                        alertVC.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
                            KebabApp.current.client.cancelTransaction()
                        }))
                    }
                    
                } else {
                    SPILogMsg("# [ok] - acknowledge transaction success")
                    
                    alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        self.acknowledge()
                    }))
                }
            }
        DispatchQueue.main.async {
        self.present(alertVC, animated: true, completion: nil)
        }
        
    }
    func showError(_ msg: String, completion: (() -> Swift.Void)? = nil) {
        SPILogMsg("ERROR: \(msg)")
        showAlert(title:"ERROR!", message: msg)
        
    }
    func appendReceipt(_ msg: String?) {
        SPILogMsg("appendReceipt \(String(describing: msg))")
        
        guard let msg = msg, msg.count > 0 else { return }
        
        DispatchQueue.main.async {
            self.txt_output.text = msg + "\n================\n" + self.txt_output.text
        }
    }
}
