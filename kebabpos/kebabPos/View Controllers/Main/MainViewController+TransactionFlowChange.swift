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
    func getFlowString(flow:SPIFlow)->String{
        switch flow {
        case .idle:
           return "Idle"
        case .pairing:
           return "Pairing"
        case .transaction:
           return "Transaction"
        }
    }
    func updateFlowInfo(state:SPIState){
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
        lbl_flowStatus.text = getFlowString(flow: state.flow)
        self.title = lblStatus.text
    }
    func stateChanged(state:SPIState){
        updateFlowInfo(state: state)
    }
   
//    ///Console.WriteLine("# ----------- AVAILABLE ACTIONS ------------");
//
//    if (_spi.CurrentFlow == SpiFlow.Idle)
//    {
//    Console.WriteLine("# [pizza:funghi] - charge for a pizza!");
//    Console.WriteLine("# [yuck] - hand out a refund!");
//    Console.WriteLine("# [settle] - Initiate Settlement");
//    }
//
//    if (_spi.CurrentStatus == SpiStatus.Unpaired && _spi.CurrentFlow == SpiFlow.Idle)
//    {
//    Console.WriteLine("# [pos_id:CITYPIZZA1] - Set the POS ID");
//    Console.WriteLine("# [eftpos_address:10.161.104.104] - Set the EFTPOS ADDRESS");
//    }
//
//    if (_spi.CurrentStatus == SpiStatus.Unpaired && _spi.CurrentFlow == SpiFlow.Idle)
//    Console.WriteLine("# [pair] - Pair with Eftpos");
//
//    if (_spi.CurrentStatus != SpiStatus.Unpaired && _spi.CurrentFlow == SpiFlow.Idle)
//    Console.WriteLine("# [unpair] - Unpair and Disconnect");
//
//    if (_spi.CurrentFlow == SpiFlow.Pairing)
//    {
//    Console.WriteLine("# [pair_cancel] - Cancel Pairing");
//
//    if (_spi.CurrentPairingFlowState.AwaitingCheckFromPos)
//    Console.WriteLine("# [pair_confirm] - Confirm Pairing Code");
//
//    if (_spi.CurrentPairingFlowState.Finished)
//    Console.WriteLine("# [ok] - acknowledge final");
//    }
//
//    if (_spi.CurrentFlow == SpiFlow.Transaction)
//    {
//    var txState = _spi.CurrentTxFlowState;
//
//    if (txState.AwaitingSignatureCheck)
//    {
//    Console.WriteLine("# [tx_sign_accept] - Accept Signature");
//    Console.WriteLine("# [tx_sign_decline] - Decline Signature");
//    }
//
//    if (!txState.Finished && !txState.AttemptingToCancel)
//    Console.WriteLine("# [tx_cancel] - Attempt to Cancel Tx");
//
//    if (txState.Finished)
//    Console.WriteLine("# [ok] - acknowledge final");
//    }
//
//    Console.WriteLine("# [status] - reprint buttons/status");
//    Console.WriteLine("# [bye] - exit");
//    Console.WriteLine();
   
}
