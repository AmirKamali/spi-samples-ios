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
               // console.WriteLine("# [tx_sign_accept] - Accept Signature");
               // console.WriteLine("# [tx_sign_decline] - Decline Signature");
            }
            if (txState.isAwaitingPhoneForAuth){
               // Console.WriteLine("# [tx_auth_code:123456] - Submit Phone For Auth Code");
            }
        }
        
        if (client.state.flow == .transaction)
        {
            
            if (!client.state.txFlowState.isFinished && !client.state.txFlowState.isAttemptingToCancel){
               // Console.WriteLine("# [tx_cancel] - Attempt to Cancel Tx");
            }
            
            if (client.state.txFlowState.isFinished){
                ok()
              //  Console.WriteLine("# [ok] - acknowledge final");
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
    func tx_auth_code(){
        
    }
}
