//
//  SPIExtensions.swift
//  kebabPos
//
//  Created by Amir Kamali on 6/6/18.
//  Copyright © 2018 Assembly Payments. All rights reserved.
//

import Foundation
import SPIClient_iOS
extension SPIMessageSuccessState{
    var name:String{
        switch self {
        case .failed:
            return "failed"
        case .success:
            return "success"
        case .unknown:
            return "unknown"
        }
    }
}
