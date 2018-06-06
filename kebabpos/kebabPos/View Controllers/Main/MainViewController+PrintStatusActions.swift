//
//  MainViewController+PrintStatusActions.swift
//  kebabPos
//
//  Created by Amir Kamali on 6/6/18.
//  Copyright © 2018 Assembly Payments. All rights reserved.
//

import Foundation
import SPIClient_iOS

extension MainViewController{
    func logMessage(_ message:String){
        txtOutput.text = message + "\r\n" + txtOutput.text
        print(message)
    }
    func printFlowInfo(state:SPIState){
        if (state.flow == .pairing)
        {
            guard let pairingState = state.pairingFlowState else {
                return
            }
            logMessage("### PAIRING PROCESS UPDATE ###");
            logMessage(String(format:"# %@",pairingState.message));
            logMessage(String(format:"# Finished? %@",pairingState.isFinished.toString()));
            logMessage(String(format:"# Successful? %@",pairingState.isSuccessful.toString()));
            logMessage(String(format:"# Confirmation Code: %@",pairingState.confirmationCode));
            logMessage(String(format:"# Waiting Confirm from Eftpos? %@",pairingState.isAwaitingCheckFromEftpos.toString()));
            logMessage(String(format:"# Waiting Confirm from POS? %@",pairingState.isAwaitingCheckFromPos.toString()));
        }
        
        if (state.flow == .transaction)
        {
            guard let txState = state.txFlowState else {
                return
            }
            logMessage("### TX PROCESS UPDATE ###");
            logMessage(String(format:"# %@",txState.displayMessage));
            logMessage(String(format:"# Id: %@",txState.tid));
            logMessage(String(format:"# Type: %@",txState.type.name));
            logMessage(String(format:"# Amount: %.2f", Float(txState.amountCents) / 100.0));
            logMessage(String(format:"# Waiting For Signature: %@",txState.isAwaitingSignatureCheck.toString()));
            logMessage(String(format:"# Attempting to Cancel : %@",txState.isAttemptingToCancel.toString()));
            logMessage(String(format:"# Finished: %@",txState.isFinished.toString()));
            logMessage(String(format:"# Success: %@",txState.successState.name));
        
            if (txState.isFinished)
            {
                logMessage("\r\n");
                switch (txState.successState)
                {
                case.success:
                    if (txState.type == .purchase)
                    {
                        logMessage(String("# WOOHOO - WE GOT PAID!"));
                        guard let purchaseResponse = SPIPurchaseResponse(message: txState.response) else {
                            return
                        }
                        logMessage(String(format:"# Response: %@", purchaseResponse.getText()));
                        logMessage(String(format:"# RRN: %@", purchaseResponse.getRRN()));
                        logMessage(String(format:"# Scheme: %@", purchaseResponse.schemeName));
                        logMessage(String(format:"# Settlement Date: %@",purchaseResponse.getSettlementDate().toString()));
                        logMessage("# Customer Receipt:");
                        logMessage(purchaseResponse.getCustomerReceipt());
                    }
                    else if (txState.type == .refund)
                    {
                        logMessage(String(format:"# REFUND GIVEN - OH WELL!"));
                        guard let refundResponse =  SPIRefundResponse(message: txState.response) else {
                            return
                        }
                        logMessage(String(format:"# Response: %@", refundResponse.getText()));
                        logMessage(String(format:"# RRN: %@", refundResponse.getRRN()));
                        logMessage(String(format:"# Scheme: %@", refundResponse.schemeName));
                        logMessage(String(format:"# Settlement Date: %@",refundResponse.getSettlementDate().toString()));
                        logMessage("# Customer Receipt:");
                        logMessage(refundResponse.getCustomerReceipt());
                    }
                    else if (txState.type == .settle)
                    {
                        logMessage(String(format:"# SETTLEMENT SUCCESSFUL!"));
                        if (txState.response != nil)
                        {
                            guard let settleResponse =  SPISettlement(message: txState.response) else {
                                return
                            }
                            logMessage(String(format:"# Response: %@", settleResponse.getResponseText()));
                            logMessage("# Merchant Receipt:");
                            logMessage(settleResponse.getReceipt());
                        }
                    }
                    break;
                case .failed:
                    if (txState.type == .purchase)
                    {
                        logMessage(String(format:"# WE DID NOT GET PAID :("));
                        if (txState.response != nil)
                        {
                            guard let purchaseResponse = SPIPurchaseResponse(message: txState.response) else {
                                return
                            }
                            logMessage(String(format:"# Error: %@", txState.response.error));
                            logMessage(String(format:"# Response:  %@", purchaseResponse.getText()));
                            logMessage(String(format:"# RRN:  %@", purchaseResponse.getRRN()));
                            logMessage(String(format:"# Scheme:  %@", purchaseResponse.schemeName));
                            logMessage("# Customer Receipt:");
                            logMessage(purchaseResponse.getCustomerReceipt());
                        }
                    }
                    else if (txState.type == .refund)
                    {
                        logMessage(String(format:"# REFUND FAILED!"));
                        if (txState.response != nil)
                        {
                            guard let refundResponse = SPIRefundResponse(message: txState.response) else {
                                return
                            }
                            logMessage(String(format:"# Response:  %@", refundResponse.getText()));
                            logMessage(String(format:"# RRN:  %@", refundResponse.getRRN()));
                            logMessage(String(format:"# Scheme:  %@", refundResponse.schemeName));
                            logMessage("# Customer Receipt:");
                            logMessage(refundResponse.getCustomerReceipt());
                        }
                    }
                    else if (txState.type == .settle)
                    {
                        logMessage(String(format:"# SETTLEMENT FAILED!"));
                        if (txState.response != nil)
                        {
                            guard let settleResponse = SPISettlement(message: txState.response) else {
                                return
                            }
                            logMessage(String(format:"# Response:  %@", settleResponse.getResponseText()));
                            logMessage(String(format:"# Error:  %@", txState.response.error));
                            logMessage("# Merchant Receipt:");
                            logMessage(settleResponse.getReceipt());
                        }
                    }
                    break;
                case .unknown:
                    if (txState.type == .purchase)
                    {
                        logMessage("# WE'RE NOT QUITE SURE WHETHER WE GOT PAID OR NOT :/");
                        logMessage("# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.");
                        logMessage("# IF YOU CONFIRM THAT THE CUSTOMER PAID, CLOSE THE ORDER.");
                        logMessage("# OTHERWISE, RETRY THE PAYMENT FROM SCRATCH.");
                    }
                    else if (txState.type == .refund)
                    {
                        logMessage("# WE'RE NOT QUITE SURE WHETHER THE REFUND WENT THROUGH OR NOT :/");
                        logMessage("# CHECK THE LAST TRANSACTION ON THE EFTPOS ITSELF FROM THE APPROPRIATE MENU ITEM.");
                        logMessage("# YOU CAN THE TAKE THE APPROPRIATE ACTION.");
                    }
                   break;
                }
            }
         }
        //logMessage("");
    }
}
