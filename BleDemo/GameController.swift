//
//  GameController.swift
//  BleDemo
//
//  Created by 江涛 on 2019/4/25.
//  Copyright © 2019 江涛. All rights reserved.
//

import UIKit
import CoreBluetooth

class GameController: UIViewController {
    private var currentRole: Role = .unknow
    
    // MARK: - UI
    @IBOutlet weak var boardView: UIView!
    @IBOutlet weak var handleBtn: UIButton!
    @IBOutlet weak var alertLbl: UILabel!
    
    // MARK: - Scaner property
    private var scaner: BleScaner?
    private var foundPeripherals: [CBPeripheral] = []
    private var connectPeripheral: CBPeripheral?
    private var readableCharacteristic: CBCharacteristic?
    private var writeableCharacteristic: CBCharacteristic?
    
    // MARK: - Local peripher
    private var local: LocalPeripher?
    private var localPeripher: CBPeripheralManager?
    private var localBeReadCharacteristic: CBMutableCharacteristic?
    private var localBeWriteCharacteristic: CBMutableCharacteristic?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let arr = ["12-11", "0-0", "16-16", "5-9", "15-3"]
        
        for str in arr {
            putPiece(str, role: .central)
        }
    }
    
    func setRole(_ role: Role) {
        self.currentRole = role
        configView()
    }
    
    private func configView() {
        switch self.currentRole {
        case .central:
            self.handleBtn.setTitle("准备", for: .normal)
            self.alertLbl.text = ""
        case .peripheral:
            self.handleBtn.setTitle("开始", for: .normal)
            self.alertLbl.text = ""
        default:
            print("")
            self.alertLbl.text = "读取角色信息失败"
        }
    }
}


extension GameController {
    private func createPieces(_ role: Role) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 6))
        view.backgroundColor = (role == Role.peripheral) ? UIColor.red : UIColor.purple
        
        view.clipsToBounds = true
        view.layer.cornerRadius = 3
        
        return view
    }
    
    
    // string : 12-2
    private func putPiece(_ coordinates: String, role: Role) {
        
        let piece = createPieces(.central)
        
        let arr = coordinates.components(separatedBy: "-")
        
        var x = Int(arr.first!)! * 20
        var y = Int(arr.last!)! * 20
    
        piece.center = CGPoint(x: x, y: y)
        
        self.boardView.addSubview(piece)
    }
}


extension GameController: BleScanerDelegate {
    func scaner(_ scaner: BleScaner, didFound peripherals: [CBPeripheral]) {
        self.foundPeripherals = peripherals
    }
    
    func scaner(_ scaner: BleScaner, didConnect peripheral: CBPeripheral) {
        self.connectPeripheral = peripheral
    }
    
    func scaner(_ scaner: BleScaner, didDiscoverReadableCharacteristic characteristic: CBCharacteristic) {
        self.readableCharacteristic = characteristic
    }
    
    func scaner(_ scaner: BleScaner, didDiscoverWriteableCharacteristic characteristic: CBCharacteristic) {
        self.writeableCharacteristic = characteristic
    }
    
    func scaner(_ scaner: BleScaner, didUpdateNotification characteristic: CBCharacteristic, error: Error?) {
        
    }
}

extension GameController: LocalPeripherDelegate {
    func localPeripher(_ local: LocalPeripher, peripher: CBPeripheralManager, readCharacteristic: CBMutableCharacteristic, writeCharacteristic: CBMutableCharacteristic, error: Error?) {
        if error != nil {
            // handle error
            
            return
        }
        self.localPeripher = peripher
        self.localBeReadCharacteristic = readCharacteristic
        self.localBeWriteCharacteristic = writeCharacteristic
    }
    
    func localPeripher(_ local: LocalPeripher, handleReadRequest result: Bool) {
        if !result {
            // handle read request error
            
            return
        }
        
        
    }
    
    func localPeripher(_ local: LocalPeripher, handleWriteRequest result: Bool) {
        if !result {
            // handle write request error
            
            return
        }
    }
}
