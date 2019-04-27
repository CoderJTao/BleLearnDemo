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
    @IBOutlet weak var boardView: UIImageView!
    @IBOutlet weak var handleBtn: UIButton!
    @IBOutlet weak var alertLbl: UILabel!
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(boardViewTap(_:)))
        return tap
    }()
    
    // MARK: - Scaner property
    private var scaner: BleScaner?
    private var foundPeripherals: [CBPeripheral] = []
    private var connectPeripheral: CBPeripheral?
    private var readableCharacteristic: CBCharacteristic?
    private var writeableCharacteristic: CBCharacteristic?
    
    // MARK: - Local peripher
    private var local: BleLocalPeripher?
    private var localPeripher: CBPeripheralManager?
    private var localBeReadCharacteristic: CBMutableCharacteristic?
    private var localBeWriteCharacteristic: CBMutableCharacteristic?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configView()
        
        if self.currentRole == .central {
            self.scaner = BleScaner()
            self.scaner?.delegate = self
        } else {
            self.local = BleLocalPeripher()
            self.local?.delegate = self
        }
        
        self.boardView.isUserInteractionEnabled = true
        self.boardView.addGestureRecognizer(self.tapGesture)
    }
    
    func setRole(_ role: Role) {
        self.currentRole = role
    }
    
    private func configView() {
        switch self.currentRole {
        case .central:
            self.handleBtn.setTitle("准备", for: .normal)
            self.handleBtn.isHidden = false
            self.handleBtn.isEnabled = false
            self.alertLbl.text = ""
        case .peripheral:
            self.handleBtn.setTitle("开始", for: .normal)
            self.handleBtn.isHidden = true
            self.alertLbl.text = ""
        default:
            print("")
            self.alertLbl.text = "读取角色信息失败"
        }
    }
    
    @IBAction func readyOrStartClick(_ sender: Any) {
        if self.currentRole == .central {
            self.scaner?.writeValue(I_AM_READY)
            self.alertLbl.text = "等待房主开始游戏"
            self.handleBtn.setTitle("已准备", for: .normal)
        } else {
            self.local?.writeLocalReadableForNotify(START_GAME)
            self.handleBtn.isHidden = true
            self.alertLbl.text = "请开始落子"
            self.boardView.isUserInteractionEnabled = true
        }
    }
}


extension GameController {
    @objc private func boardViewTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(ofTouch: 0, in: self.boardView)
        
        let putPosition = getCoordinates(point)
        
        if self.currentRole == .central {
            self.scaner?.writeValue(putPosition)
        } else {
            self.local?.writeLocalReadableForNotify(putPosition)
        }
        
        putPiece(putPosition, role: self.currentRole)
        
        print(putPosition)
    }
    
    private func getCoordinates(_ point: CGPoint) -> String {
        var xValue = ""
        var yValue = ""
        
        let x = Int(point.x)
        let y = Int(point.y)
        
        var x_divisor = x / 20
        let x_remainder = x % 20
        if x_remainder >= 10 {
            x_divisor += 1
        }
        xValue = String(x_divisor)
        
        var y_divisor = y / 20
        let y_remainder = y % 20
        if y_remainder >= 10 {
            y_divisor += 1
        }
        yValue = String(y_divisor)
        
        return "\(xValue)-\(yValue)"
    }
    
    private func createPieces(_ role: Role) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 6))
        view.backgroundColor = (role == Role.peripheral) ? UIColor.red : UIColor.purple
        
        view.clipsToBounds = true
        view.layer.cornerRadius = 3
        
        return view
    }
    
    
    // string : 12-2
    private func putPiece(_ coordinates: String, role: Role) {
        
        let piece = createPieces(role)
        
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
        self.alertLbl.text = "正在查找\(String(describing: peripheral.name))的相关服务"
    }
    
    func scaner(_ scaner: BleScaner, didDiscoverReadableCharacteristic characteristic: CBCharacteristic) {
        self.readableCharacteristic = characteristic
        self.alertLbl.text = "找到可读的 characteristic"
    }
    
    func scaner(_ scaner: BleScaner, didDiscoverWriteableCharacteristic characteristic: CBCharacteristic) {
        self.writeableCharacteristic = characteristic
        
        self.alertLbl.text = "找到可写的 characteristic"
        
        // 第一次发现特征时
        if scaner.status == .waiting {
            scaner.writeValue(I_AM_COMMING)
        }
    }
    
    /// 收到棋子的位置信息
    func scaner(_ scaner: BleScaner, didUpdateNotifyValue value: String) {
        switch value {
        case READY_TO_BEGIN:
            self.alertLbl.text = "房主在等我准备"
            self.handleBtn.isEnabled = true
        case START_GAME:
            self.alertLbl.text = "房主说那我们开始吧，等待房主落子"
            self.handleBtn.isHidden = true
        case GAME_OVER:
            self.alertLbl.text = "游戏结束"
        default:
            // 收到棋子的坐标信息
            print("piece position value: \(value)")
            
            putPiece(value, role: .peripheral)
        }
    }
}

extension GameController: BleLocalPeripherDelegate {
    func localPeripher(_ local: BleLocalPeripher, peripher: CBPeripheralManager, readCharacteristic: CBMutableCharacteristic, writeCharacteristic: CBMutableCharacteristic, error: Error?) {
        if error != nil {
            // handle error
            
            return
        }
        self.localPeripher = peripher
        self.localBeReadCharacteristic = readCharacteristic
        self.localBeWriteCharacteristic = writeCharacteristic
        
        self.alertLbl.text = "开始广播自己服务"
    }
    
    func localPeripher(_ local: BleLocalPeripher, didUpdateValue value: String) {
        switch value {
        case I_AM_COMMING:
            self.alertLbl.text = "有玩家进入房间"
            self.handleBtn.isHidden = false
            self.handleBtn.isEnabled = false
        case I_AM_READY:
            self.alertLbl.text = "玩家已经准备"
            self.handleBtn.isEnabled = true
        case START_GAME:
            self.alertLbl.text = "自己开始下第一个棋子"
        // 开始放置自己的棋子
        case GAME_OVER:
            self.alertLbl.text = "游戏结束"
        case PLAY_AGAIN:
            self.alertLbl.text = "玩家准备再来一局"
        default:
            // 收到的是棋子坐标的信息
            // 收到棋子的坐标信息
            print("piece position value: \(value)")
            
            putPiece(value, role: .central)
        }
    }
}
