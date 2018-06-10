//
//  ActionProvider.swift
//  kebabPos
//
//  Created by Amir Kamali on 11/6/18.
//  Copyright © 2018 Assembly Payments. All rights reserved.
//

import Foundation
import SPIClient_iOS
enum SPIActions{
    case purchase
    case MOTO
    case refund
    case cashout
    case settle
    case settle_enq
    case recover
    case glt
    case rcpt_from_eftpos
    case sig_flow_from_eftpos
    case pair
    case unpair
    case pair_confirm
    case pair_cancel
    case ok
    case tx_sign_accept
    case tx_sign_decline
    case tx_auth_code
    case tx_cancel
    var name:String{
        switch self {
        case .purchase:
            return "Purchase"
        case .MOTO:
            return "MOTO"
        case .refund:
            return "Refund"
        case .cashout:
            return "Cashout"
        case .settle:
            return "Settle"
        case .settle_enq:
            return "Settle Enquiry"
        case .recover:
            return "Recover"
        case .glt:
            return "Last Transaction"
        case .rcpt_from_eftpos:
            return "Receipt from EFTPos"
        case .sig_flow_from_eftpos:
            return "Signature from EFTPos"
        case .pair:
            return "Pair"
        case .unpair:
            return "Unpair"
        case .pair_confirm:
            return "Confirm Pair"
        case .pair_cancel:
            return "Cancel pair"
        case .ok:
            return "Acknowledge"
        case .tx_sign_accept:
            return "Accept Signature"
        case .tx_sign_decline:
            return "Signature Decline"
        case .tx_auth_code:
            return "Provide Auth Code"
        case .tx_cancel:
            return "Cancel Transaction"
        }
    }
}
protocol SPIActionProvider:class{
     func updateUIFlowInfo(state: SPIState)
}
extension SPIActionProvider {
    var client:SPIClient{
        return KebabApp.current.client
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
    func displayActions(actions:[SPIActions]){
        
    }
    func ok(){
        client.ackFlowEndedAndBack { (finished, state) in
            DispatchQueue.main.async {
                KebabApp.current.stateChanged(state: state);
            }
            
        }
        
    }
    func tx_cancel(){
        client.cancelTransaction()
    }
    func presentActions(actions:[SPIActions]){
        
    }
}
