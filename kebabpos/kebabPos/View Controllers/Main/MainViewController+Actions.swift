//
//  MainViewController+Actions.swift
//  kebabPos
//
//  Created by Amir Kamali on 29/5/18.
//  Copyright © 2018 Assembly Payments. All rights reserved.
//

import Foundation
import SPIClient_iOS
extension MainViewController{
    var newRefrenceId:String {
        let randomName = "localRef1"//\(arc4random()%999999)"
        return randomName
    }
    @IBAction func btnPurchaseClicked(_ sender: Any) {
        let referenceId = newRefrenceId //Local referenceId
        
        guard let amount = Int(txtTransactionAmount.text ?? "") , amount > 0 else { //Amount Cents
            return
        }
        
        client.initiatePurchaseTx(referenceId, amountCents: amount,completion: printResult)
    }
    @IBAction func btnMotoClicked(_ sender: Any) {
        let referenceId = newRefrenceId //Local referenceId
        let amount = 120 //Cents
        client.initiateMotoPurchaseTx(referenceId, amountCents: amount, completion: printResult)
    }
    @IBAction func btnRefundClicked(_ sender: Any) {
        let referenceId = newRefrenceId //Local referenceId
     let amount = 120 //Cents
        client.initiateRefundTx(referenceId, amountCents: amount, completion: printResult)
    }
    @IBAction func btnCashOutClicked(_ sender: Any) {
        let referenceId = newRefrenceId //Local referenceId
        let amount = 120 //Cents
        client.initiateCashoutOnlyTx(referenceId, amountCents: amount, completion: printResult)
    }
    @IBAction func btnSettleClicked(_ sender: Any) {
        let referenceId = newRefrenceId //Local referenceId

        client.initiateSettleTx(referenceId, completion: printResult)
    }
    @IBAction func btnSettleEnquiryClicked(_ sender: Any) {
        let referenceId = newRefrenceId //Local referenceId
        client.initiateSettlementEnquiry(referenceId, completion: printResult)
    }
    func printResult(result:SPIInitiateTxResult?){
        DispatchQueue.main.async {
            SPILogMsg(result?.message)
            self.txtOutput.text =  result?.message ?? "" + self.txtOutput.text
        }
        
    }
}
