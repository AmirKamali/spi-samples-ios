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
    func showError(_ msg: String, completion: (() -> Swift.Void)? = nil) {
        SPILogMsg("\r\nERROR: \(msg)")
        showAlert(title:"ERROR!", message: msg)
        
    }
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
        if (state.flow == .idle)
        {
            //    logMessage("# [pizza:funghi] - charge for a pizza!");
            //    logMessage("# [yuck] - hand out a refund!");
            //    logMessage("# [settle] - Initiate Settlement");
        }
        if (state.status == .unpaired && state.flow == .idle)
        {
            //    logMessage("# [pos_id:CITYPIZZA1] - Set the POS ID");
            //    logMessage("# [eftpos_address:10.161.104.104] - Set the EFTPOS ADDRESS");
        }
        if (state.status == .unpaired && state.flow == .idle){
            logMessage("# [pair] - Pair with Eftpos");
        }
        if (state.status != .unpaired && state.flow == .idle){
            logMessage("# [unpair] - Unpair and Disconnect");
        }
        
        if (state.flow == .pairing)
        {
            logMessage("# [pair_cancel] - Cancel Pairing");
            
            if (state.pairingFlowState.isAwaitingCheckFromPos){
                logMessage("# [pair_confirm] - Confirm Pairing Code");
            }
            
            if (state.pairingFlowState.isFinished){
                logMessage("# [ok] - acknowledge final");
                ok()
            }
        }
        
        if (state.flow == .transaction)
        {
            guard let txState = state.txFlowState else {
                return
            }
            
            if (txState.isAwaitingSignatureCheck)
            {
                logMessage("# [tx_sign_accept] - Accept Signature");
                logMessage("# [tx_sign_decline] - Decline Signature");
            }
            if (!txState.isFinished && !txState.isAttemptingToCancel){
                logMessage("# [tx_cancel] - Attempt to Cancel Tx");
              //  tx_cancel()
                
            }
            
            if (txState.isFinished){
                logMessage("# [ok] - acknowledge final");
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
        client.cancelTransaction()
    }
}
