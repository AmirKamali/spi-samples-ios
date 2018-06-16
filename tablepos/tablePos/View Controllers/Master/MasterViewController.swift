//
//  MasterViewController.swift
//  TablePos
//
//  Created by Amir Kamali on 16/6/18.
//  Copyright © 2018 Assembly Payments. All rights reserved.
//

import UIKit
import SPIClient_iOS
class MasterViewController: UITableViewController {
    var billsStore:[String: Bill] = [:];
    var tableToBillMapping: [String: String] = [:]
    var assemblyBillDataStore: [String: String] = [:]

    var detailViewController: DetailViewController? = nil
    var objects = [Any]()

    var client: SPIClient {
        return TablePosApp.current.client
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        txtReferenceId.text = newRefrenceId
//        restoreConfig()
//        registerForEvents(appEvents: [.connectionStatusChanged, .transactionFlowStateChanged])
        client.start()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.leftBarButtonItem = editButtonItem

        //let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        let pairButton = UIBarButtonItem(title: "Pair", style: .plain, target: self, action: #selector(navigateToConnection))
        navigationItem.rightBarButtonItem = pairButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @objc
    func navigateToConnection(){
        self.performSegue(withIdentifier: "connection", sender: self)
    }
    @objc
    func insertNewObject(_ sender: Any) {
        objects.insert(NSDate(), at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let object = objects[indexPath.row] as! NSDate
        cell.textLabel!.text = object.description
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    func printResult(result: SPIInitiateTxResult?) {
        DispatchQueue.main.async {
            SPILogMsg(result?.message)
          //  self.txtOutput.text =  result?.message ?? "" + self.txtOutput.text
        }
        
    }
    func showError(_ msg: String, completion: (() -> Void)? = nil) {
        SPILogMsg("\r\nERROR: \(msg)")
        showAlert(title: "ERROR!", message: msg)
        
    }
}

