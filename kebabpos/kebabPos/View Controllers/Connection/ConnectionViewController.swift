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
    
    var alertVC: UIAlertController?

   
   
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForEvents(appEvents: [.connectionStatusChanged,.pairingFlowChanged,.transactionFlowStateChanged])
        txt_posId.text = KebabApp.current.settings.posId
        txt_posAddress.text = KebabApp.current.settings.eftPosAddress

    }
    @IBAction func pairButtonClicked(_ sender: Any) {
        KebabApp.current.settings.posId = txt_posId.text
        KebabApp.current.settings.eftPosAddress = txt_posAddress.text
        KebabApp.current.settings.encriptionKey = nil
        KebabApp.current.settings.hmacKey = nil
        KebabApp.current.client.pair()
    }
    @IBAction func pairingCancel() {
        KebabApp.current.client.pairingCancel()
        
    }
    @IBAction func unpair() {
        KebabApp.current.client.unpair()
        
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
   
    func printStatusAndAction(_ state: SPIState?) {
        SPILogMsg("printStatusAndAction \(String(describing: state))")
        
        guard let state = state else { return }
        
        switch state.status {
            
        case .unpaired:
            
            switch state.flow {
            case .idle:
                break
            case .pairing:
                KebabApp.current.client.ackFlowEndedAndBack { (alreadyInIdle, state) in
                    print("setting to idle :\(alreadyInIdle) state:\(String(describing: state))")
                    if let state = state{
                        self.showPairing(state)
                    }
                }
                
                
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

    func acknowledge() {
        SPILogMsg("acknowledge")
        
        KebabApp.current.client.ackFlowEndedAndBack {  alreadyMovedToIdleState, state in
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
