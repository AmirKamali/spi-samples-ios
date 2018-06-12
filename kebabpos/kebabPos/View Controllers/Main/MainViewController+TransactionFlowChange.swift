//
//  MainViewController+TransactionFlowChange.swift
//  kebabPos
//
//  Created by Amir Kamali on 3/6/18.
//  Copyright © 2018 Assembly Payments. All rights reserved.
//

import Foundation
import SPIClient_iOS
extension MainViewController{
    func updateUIFlowInfo(state:SPIState){
        lblStatus.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        lblStatus.textColor = UIColor.darkGray
        
        btnConnection.title = "Pair"
        switch state.status {
        case .pairedConnected:
            lblStatus.text = "Connected"
            lblStatus.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightSemibold)
            lblStatus.textColor = UIColor(red: 23.0/256, green: 156.0/255, blue: 63.0/255, alpha: 1.0)
            btnConnection.title = "Connection"
        case .pairedConnecting:
            lblStatus.text = "Connecting"
            break
        case .unpaired:
            lblStatus.text = "Not Connected"
            break
        }
        lblPosId.text = KebabApp.current.settings.posId
        lblPosAddress.text = KebabApp.current.settings.eftPosAddress
        lbl_flowStatus.text = state.flow.name
        self.title = lblStatus.text
    }
    func stateChanged(state:SPIState? = nil){
        guard let state = state ?? KebabApp.current.client.state else {
            return
        }
        updateUIFlowInfo(state: state)
        printFlowInfo(state: state)
        selectActions(state: state)
    }
    func selectActions(state:SPIState){
        
       // Console.WriteLine("# ----------- AVAILABLE ACTIONS ------------");
        if client.state.flow == .idle {
            //clear UI
            self.presentedViewController?.dismiss(animated: false,completion: nil)
        }
        if (client.state.status == .unpaired && client.state.flow == .idle){
            //Console.WriteLine("# [pos_id:CITYKEBAB1] - Set the POS ID");
        }
        if (client.state.status == .unpaired || client.state.status == .pairedConnecting){
            //Console.WriteLine("# [eftpos_address:10.161.104.104] - Set the EFTPOS ADDRESS");
        }

        if (client.state.status == .unpaired || client.state.status == .pairedConnecting)
        {
          //  Console.WriteLine("# [eftpos_address:10.161.104.104] - Set the EFTPOS ADDRESS");
        }
        if (client.state.status == .unpaired && client.state.flow == .idle){
            //Console.WriteLine("# [pair] - Pair with Eftpos");
        }
        if (client.state.status != .unpaired && client.state.flow == .idle){
            //Console.WriteLine("# [unpair] - Unpair and Disconnect");
        }
        if (client.state.flow == .pairing)
        {
            if (client.state.pairingFlowState.isAwaitingCheckFromPos){
                client.pairingConfirmCode()
            }
            if (!client.state.pairingFlowState.isFinished){
                //Console.WriteLine("# [pair_cancel] - Cancel Pairing");
            }
            if (client.state.pairingFlowState.isFinished){
                ok()
            }
        }
        if client.state.flow == .transaction , let txState = client.state.txFlowState{
            
            if (txState.isAwaitingSignatureCheck){
               tx_signature()
            }
            if (txState.isAwaitingPhoneForAuth){
                tx_auth_code()
            }
        }
        
        if (client.state.flow == .transaction)
        {
            
            if (!client.state.txFlowState.isFinished && !client.state.txFlowState.isAttemptingToCancel){
               tx_cancel()
            }
            
            if (client.state.txFlowState.isFinished){
                ok()
            }
        }
    }
    func ok(){
        client.ackFlowEndedAndBack { (finished, state) in
            DispatchQueue.main.async {
                self.stateChanged(state: state);
            }
            
        }
        
    }
    func tx_cancel(){
        let alertVC = UIAlertController(title: "Message", message: client.state.txFlowState.displayMessage, preferredStyle: .alert)
        let cancelBtn = UIAlertAction(title: "Cancel", style: .default) { (action) in
            self.client.cancelTransaction()
        }
        alertVC.addAction(cancelBtn)
        showAlert(alertController: alertVC)
        
    }
    func tx_auth_code(){
        var txtAuthCode:UITextField?
        let alertVC = UIAlertController(title: "Message", message: "Submit Phone for Auth Code", preferredStyle: .alert)
        _ = alertVC.addTextField { (txt) in
            txtAuthCode = txt
            txt.text = "Enter code"
        }
        let submitBtn = UIAlertAction(title: "Submit", style: .default) { (action) in
            self.client.submitAuthCode(txtAuthCode?.text, completion: { (result) in
                self.logMessage(String(format:"Valid format: %@)",result?.isValidFormat ?? false))
                self.logMessage(String(format:"Message: %@", result?.message ?? "-"))
            })
        }
        alertVC.addAction(submitBtn)
        showAlert(alertController: alertVC)
    }
    func tx_signature(){
        let alertVC = UIAlertController(title: "Message", message: "Select Action", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Accept Signature", style: .default, handler: { action in
        KebabApp.current.client.acceptSignature(true)
                                }))
        
        alertVC.addAction(UIAlertAction(title: "Decline Signature", style: .default, handler: { action in
                                    KebabApp.current.client.acceptSignature(false)
                                }))
        showAlert(alertController: alertVC)
    }
    //    func showConnectedTx(_ state: SPIState) {
    //        SPILogMsg("showConnectedTx")
    //
    //        guard let txFlowState = state.txFlowState else {
    //            showError("Missing txFlowState \(state)")
    //            return
    //        }
    //        let alertVC = UIAlertController(title: "Title", message: txFlowState.displayMessage, preferredStyle: .alert)
    //
    //            if (txFlowState.successState == .failed) {
    //                SPILogMsg("# [ok] - acknowledge fail")
    //
    //                alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { alert in
    //                    self.acknowledge()
    //                }))
    //
    //            } else {
    //
    //                if txFlowState.isAwaitingSignatureCheck {
    //                    SPILogMsg("# [tx_sign_accept] - Accept Signature")
    //                    SPILogMsg("# [tx_sign_decline] - Decline Signature")
    //
    //                    alertVC.addAction(UIAlertAction(title: "Accept Signature", style: .default, handler: { action in
    //                        KebabApp.current.client.acceptSignature(true)
    //                    }))
    //
    //                    alertVC.addAction(UIAlertAction(title: "Decline Signature", style: .default, handler: { action in
    //                        KebabApp.current.client.acceptSignature(false)
    //                    }))
    //                }
    //
    //                if !txFlowState.isFinished {
    //                    SPILogMsg("# [tx_cancel] - Attempt to Cancel Transaction")
    //
    //                    if !state.txFlowState.isAttemptingToCancel {
    //                        alertVC.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
    //                            KebabApp.current.client.cancelTransaction()
    //                        }))
    //                    }
    //
    //                } else {
    //                    SPILogMsg("# [ok] - acknowledge transaction success")
    //
    //                    alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
    //                        self.acknowledge()
    //                    }))
    //                }
    //            }
    //        DispatchQueue.main.async {
    //            self.showAlert(alertController: alertVC)
    //        }
    //
    //    }
}
