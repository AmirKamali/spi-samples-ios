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
    @IBOutlet weak var btnReceiptFromEFTPos: UISwitch!
    @IBOutlet weak var signatureFromEFTPos: UISwitch!
    @IBOutlet weak var btnConnection: UIBarButtonItem!
    @IBOutlet weak var txtTransactionAmount: UITextField!
    @IBOutlet weak var txtCashOutAmount: UITextField!
    @IBOutlet weak var txtOutput: UITextView!
    
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
                self.refreshConnectionInfo(state: state)
            }
        case AppEvent.transactionFlowStateChanged.rawValue:
            guard let state = notification.object as? SPIState else {
                return
            }
            DispatchQueue.main.async {
                self.transactionFlowChanged(state: state)
            }
        default:
            break
        }
    }
    func refreshConnectionInfo(state:SPIState){
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
        self.title = lblStatus.text
    }
 
}
