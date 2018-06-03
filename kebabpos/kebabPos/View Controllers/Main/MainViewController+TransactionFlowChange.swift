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
    func transactionFlowChanged(state:SPIState)  {
        
        SPILogMsg("showConnectedTx")
        
        guard let txFlowState = state.txFlowState else {
            showError("Missing txFlowState \(state)")
            return
        }
        let alertVC = UIAlertController(title: "Title", message: txFlowState.displayMessage, preferredStyle: .alert)
        
        if (txFlowState.successState == .failed) {
            SPILogMsg("# [ok] - acknowledge fail")
            alertVC.title = "Purchase failed"
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
            self.showAlert(alertController: alertVC)
        }
        
    }
    func acknowledge() {
        SPILogMsg("acknowledge")
        
        KebabApp.current.client.ackFlowEndedAndBack { [weak self] alreadyMovedToIdleState, state in
            guard let `self` = self else { return }
            //self.printStatusAndAction(KebabApp.current.client.state)
        }
    }
    func showError(_ msg: String, completion: (() -> Swift.Void)? = nil) {
        SPILogMsg("ERROR: \(msg)")
        showAlert(title:"ERROR!", message: msg)
        
    }
}
