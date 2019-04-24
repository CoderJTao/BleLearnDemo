//
//  LocalPeripheral.swift
//  BleDemo
//
//  Created by 江涛 on 2019/4/24.
//  Copyright © 2019 江涛. All rights reserved.
//

import UIKit
import CoreBluetooth

class LocalPeripheral: UIViewController {

    var myPeripheral: CBPeripheralManager {
        get {
            return CBPeripheralManager(delegate: self, queue: nil, options: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    


}

extension LocalPeripheral: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
    }
    
    
}

