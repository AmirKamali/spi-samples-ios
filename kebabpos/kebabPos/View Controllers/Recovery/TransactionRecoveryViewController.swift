//
//  RecoveryViewController.swift
//  kebabPos
//
//  Created by Amir Kamali on 27/5/18.
//  Copyright © 2018 Assembly Payments. All rights reserved.
//

import UIKit
import SPIClient_iOS
class TransactionRecoveryViewController: UITableViewController {

    @IBOutlet weak var txtReferenceId: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    @IBAction func btnRecoverClicked(_ sender: UIButton) {
        if let referenceId = txtReferenceId.text{
            return
        }
       // KebabApp.current.client.initiateRecovery(referenceId, transactionType: SPITransactionType.getLastTransaction, completion: )
    }
}
