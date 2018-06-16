//
//  Bill.swift
//  tablePos
//
//  Created by Amir Kamali on 17/6/18.
//  Copyright © 2018 Assembly Payments. All rights reserved.
//

import Foundation
class Bill:Codable
{
    var billId:String!
    var tableId:String!
    var totalAmount:Int  = 0;
    var outstandingAmount:Int  = 0;
    var tippedAmount:Int  = 0;
    
    public func ToString() -> String
{
    return "\(billId) - Table:\(tableId) Total:\( Float(totalAmount) / 100.0) Outstanding:\(Float(outstandingAmount) / 100.0) Tips:\(Float(tippedAmount) / 100.0)";
    }
}
