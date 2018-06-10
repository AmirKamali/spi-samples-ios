//
//  MainViewController.swift
//  kebabPos
//
//  Created by Amir Kamali on 27/5/18.
//  Copyright © 2018 Assembly Payments. All rights reserved.
//

import UIKit
import SPIClient_iOS
class MainViewController: UITableViewController,NotificationListener {
    
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var lblPosId: UILabel!
    @IBOutlet weak var lblPosAddress: UILabel!
    @IBOutlet weak var lblExtraOption: UILabel!
    @IBOutlet weak var btnReceiptFromEFTPos: UISwitch!
    @IBOutlet weak var signatureFromEFTPos: UISwitch!
    @IBOutlet weak var btnConnection: UIBarButtonItem!
    @IBOutlet weak var txtTransactionAmount: UITextField!
    @IBOutlet weak var txtExtraAmount: UITextField!
    @IBOutlet weak var txtOutput: UITextView!
    @IBOutlet weak var segmentExtraAmount: UISegmentedControl!
    
    let indexPath_extraAmount = IndexPath(row: 2, section: 3)
    let _lastCmd:[String] = []

    @IBOutlet weak var lbl_flowStatus: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForEvents(appEvents: [.connectionStatusChanged,.transactionFlowStateChanged])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    

    override func numberOfSections(in tableView: UITableView) -> Int {
        return super.numberOfSections(in: tableView)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath == indexPath_extraAmount && segmentExtraAmount.selectedSegmentIndex == 0){
            return 0
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    @IBAction func segmentExtraAmountValueChanged(_ sender: UISegmentedControl) {
        tableView.beginUpdates()
        lblExtraOption.text = segmentExtraAmount.titleForSegment(at: segmentExtraAmount.selectedSegmentIndex)
        tableView.endUpdates()
    }
    var client:SPIClient{
        return KebabApp.current.client
    }
    @objc
    func onNotificationArrived(notification:NSNotification){
        switch notification.name.rawValue {
        case AppEvent.connectionStatusChanged.rawValue:
            guard let state = notification.object as? SPIState else {
                return
            }
            DispatchQueue.main.async {
                self.stateChanged(state: state)
            }
        case AppEvent.transactionFlowStateChanged.rawValue:
            guard let state = notification.object as? SPIState else {
                return
            }
            DispatchQueue.main.async {
                self.stateChanged(state: state)
            }
        default:
            break
        }
    }
    func printResult(result:SPIInitiateTxResult?){
        DispatchQueue.main.async {
            SPILogMsg(result?.message)
            self.txtOutput.text =  result?.message ?? "" + self.txtOutput.text
        }
        
    }
    func showError(_ msg: String, completion: (() -> Void)? = nil) {
        SPILogMsg("\r\nERROR: \(msg)")
        showAlert(title:"ERROR!", message: msg)
        
    }
}
