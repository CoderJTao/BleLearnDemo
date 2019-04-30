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
    
    private var centralArr: [CGPoint] = []
    private var peripherArr: [CGPoint] = []
    
    // MARK: - UI
    @IBOutlet weak var boardView: UIImageView!
    @IBOutlet weak var handleBtn: UIButton!
    @IBOutlet weak var alertLbl: UILabel!
    
    @IBOutlet weak var endView: UIView!
    @IBOutlet weak var endImage: UIImageView!
    
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
    
    private func gameOver(isReceived: Bool) {
        self.endView.isHidden = false
        
        if isReceived {
            // 对手胜利
            self.endImage.image = UIImage(named: "failure")!
        } else {
            // 己方胜利
            self.endImage.image = UIImage(named: "victory")!
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
    
    @IBAction func quitClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playAgainClicked(_ sender: Any) {
        self.endView.isHidden = true
        
        self.centralArr.removeAll()
        self.peripherArr.removeAll()
        
        // 删除现在棋盘上所有的棋子
        for subView in self.boardView.subviews {
            subView.removeFromSuperview()
        }
        
        if self.currentRole == .central {
            //
            self.scaner?.writeValue(PLAY_AGAIN)
            self.alertLbl.text = "等待房主开始游戏"
            self.handleBtn.setTitle("已准备", for: .normal)
        } else {
            if let status = self.local?.status {
                if status == .isReady {
                    self.handleBtn.isHidden = false
                    self.alertLbl.text = "玩家准备好再来一局了"
                    self.boardView.isUserInteractionEnabled = false
                } else {
                    self.handleBtn.isHidden = true
                    self.alertLbl.text = "等待玩家准备"
                    self.boardView.isUserInteractionEnabled = false
                }
            } else {
                self.handleBtn.isHidden = true
                self.alertLbl.text = "等待玩家准备"
                self.boardView.isUserInteractionEnabled = false
            }
        }
    }
}


extension GameController {
    @objc private func boardViewTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(ofTouch: 0, in: self.boardView)
        
        let putPosition = getCoordinates(point)
        
        if !canPlace(point) {
            print("Already been placed")
            return
        }
        
        putPiece(putPosition, role: self.currentRole)
        
        self.boardView.isUserInteractionEnabled = false
        
        addPieces(putPosition)
    }
    
    /// 将下的棋子保存起来，用于判断是否胜利
    private func addPieces(_ value: String) {
        let arr = value.components(separatedBy: "-")
        
        // 添加到对应数组中，判断是否有玩家成功
        if self.currentRole == .central {
            self.centralArr.append(CGPoint(x: Int(arr.first!)!, y: Int(arr.last!)!))
        } else if self.currentRole == .peripheral {
            self.peripherArr.append(CGPoint(x: Int(arr.first!)!, y: Int(arr.last!)!))
        }
        
        if isWin((self.currentRole == .central ? self.centralArr : self.peripherArr)) {
            if self.currentRole == .central {
                scaner?.writeValue("Last:\(value)")
            } else {
                local?.writeLocalReadableForNotify("Last:\(value)")
            }
            self.alertLbl.text = "恭喜你胜利了。"
            
            gameOver(isReceived: false)
        } else {
            if self.currentRole == .central {
                self.scaner?.writeValue(value)
            } else {
                self.local?.writeLocalReadableForNotify(value)
            }
            self.alertLbl.text = "等待对方落子"
        }
    }
    
    private func canPlace(_ point: CGPoint) -> Bool {
        for p in self.centralArr {
            if p.x == point.x && p.y == point.y {
                return false
            }
        }
        
        for p in self.peripherArr {
            if p.x == point.x && p.y == point.y {
                return false
            }
        }
        
        return true
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
        
        let x = Int(arr.first!)! * 20
        let y = Int(arr.last!)! * 20
    
        piece.center = CGPoint(x: x, y: y)
        
        self.boardView.addSubview(piece)
    }
    
    /// 判断当前角色是否成功
    private func isWin(_ pointArr: [CGPoint]) -> Bool {
        for p in pointArr {
            let x = p.x
            let y = p.y
            // 横向
            let horizontal: ()->(Bool) = {
                var count = 1
                // x减小方向
                var temp = x-1
                while temp >= 0 {
                    if pointArr.contains(CGPoint(x: temp, y: y)) {
                        count += 1
                        temp -= 1
                    } else { break }
                }
                
                // x增加方向
                var temp1 = x+1
                while temp1 <= 16 {
                    if pointArr.contains(CGPoint(x: temp1, y: y)) {
                        count += 1
                        temp1 += 1
                    } else { break }
                }
                
                return count == 5
            }
            
            
            // 纵向
            let vertical: ()->(Bool) = {
                var count = 1
                // y减小方向
                var temp = y-1
                while temp >= 0 {
                    if pointArr.contains(CGPoint(x: x, y: temp)) {
                        count += 1
                        temp -= 1
                    } else { break }
                }
                
                // y增加方向
                var temp1 = y+1
                while temp1 <= 16 {
                    if pointArr.contains(CGPoint(x: x, y: temp1)) {
                        count += 1
                        temp1 += 1
                    } else { break }
                }
                return count == 5
            }
            
            // 正斜率方向
            let oblique_positive: ()->(Bool) = {
                var count = 1
                
                // 斜线方向，斜率为1
                // 值减小方向
                var temp_x = x - 1
                var temp_y = y - 1
                while temp_x >= 0 && temp_y > 0 {
                    if pointArr.contains(CGPoint(x: temp_x, y: temp_y)) {
                        count += 1
                        temp_x -= 1
                        temp_y -= 1
                    } else { break }
                }
                
                var temp_x1 = x + 1
                var temp_y1 = y + 1
                while temp_x1 <= 16 && temp_y1 <= 16 {
                    if pointArr.contains(CGPoint(x: temp_x1, y: temp_y1)) {
                        count += 1
                        temp_x1 += 1
                        temp_y1 += 1
                    } else { break }
                }
                
                return count == 5
            }
            
            // 负斜率方向
            let oblique_negative: ()->(Bool) = {
                var count = 1
                
                // 斜线方向，斜率为 -1
                // 值减小方向
                var temp_x = x - 1
                var temp_y = y + 1
                while temp_x >= 0 && temp_y <= 16 {
                    if pointArr.contains(CGPoint(x: temp_x, y: temp_y)) {
                        count += 1
                        temp_x -= 1
                        temp_y += 1
                    } else { break }
                }
                
                var temp_x1 = x + 1
                var temp_y1 = y - 1
                while temp_x1 <= 16 && temp_y1 >= 0 {
                    if pointArr.contains(CGPoint(x: temp_x1, y: temp_y1)) {
                        count += 1
                        temp_x1 += 1
                        temp_y1 -= 1
                    } else { break }
                }
                
                return count == 5
            }
            
            if horizontal() || vertical() || oblique_positive() || oblique_negative() {
                return true
            }
        }
        return false
    }
    
    // transform coordinates to self_coordinates
    private func transformed(_ value: String) -> String {
        let total = 16
        
        var result = ""
        
        let arr = value.components(separatedBy: "-")
        
        let x = Int(arr.first!)!
        let y = Int(arr.last!)!
        
        result = "\(total-x)-\(total-y)"
        
        return result
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
            self.alertLbl.text = "房主说我们开始吧，等待房主落子"
            self.handleBtn.isHidden = true
        default:
            // 收到棋子的坐标信息
            print("piece position value: \(value)")
            
            if value.hasPrefix("Last:") {
                // 对方落子之后赢得比赛
                self.alertLbl.text = "对手已经胜利。游戏结束。"
                var pass = value
                pass.replaceSubrange(Range.init(NSRange(location: 0, length: 5), in: pass)!, with: "")
                putPiece(self.transformed(pass), role: .peripheral)
                
                gameOver(isReceived: true)
                
                // UI 处理
                
            } else {
                putPiece(self.transformed(value), role: .peripheral)
                
                self.boardView.isUserInteractionEnabled = true
                self.alertLbl.text = "己方可以落子"
            }
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
        case PLAY_AGAIN:
            self.alertLbl.text = "玩家准备再来一局,并且已准备"
            self.handleBtn.isHidden = false
            self.handleBtn.isEnabled = true
        default:
            // 收到的是棋子坐标的信息
            // 收到棋子的坐标信息
            print("piece position value: \(value)")
            
            if value.hasPrefix("Last:") {
                // 对方落子之后赢得比赛
                self.alertLbl.text = "对手已经胜利。游戏结束。"
                
                var pass = value
                pass.replaceSubrange(Range.init(NSRange(location: 0, length: 5), in: pass)!, with: "")
                putPiece(self.transformed(pass), role: .central)
                
                gameOver(isReceived: true)
                
                // UI 处理
                
            } else {
                putPiece(self.transformed(value), role: .central)
                
                self.boardView.isUserInteractionEnabled = true
                self.alertLbl.text = "己方可以落子"
            }
        }
    }
}
