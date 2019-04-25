//
//  FindGameController.swift
//  BleDemo
//
//  Created by 江涛 on 2019/4/25.
//  Copyright © 2019 江涛. All rights reserved.
//

import UIKit
import CoreBluetooth

class FindGameController: UIViewController {
    
    private var status = ConnectStatus.waiting
    
    @IBOutlet weak var tableView: UITableView!
    
    var centralManager: CBCentralManager?
    
    // 强引用搜索到的外设。否则会被释放
    private var peripheralArray: [CBPeripheral] = []
    
    private var configPeripheral: CBPeripheral?
    
    var isConnected = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }
    
    private func startScan() {
        print("startScan")
        self.centralManager?.scanForPeripherals(withServices: [CBUUID(string: UUID_SERVICE)], options: [CBPeripheralManagerOptionShowPowerAlertKey : true])
    }
    
}

// MARK: - CBCentralManagerDelegate
extension FindGameController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState")
        
        switch central.state {
        case CBManagerState.unknown:
            print("unknown")
        case CBManagerState.resetting:
            print("resetting")
        case CBManagerState.unsupported:
            print("unsupported")
        case CBManagerState.unauthorized:
            print("unauthorized")
        case CBManagerState.poweredOff:
            print("poweredOff")
        case CBManagerState.poweredOn:
            print("poweredOn")
            startScan()
        default:
            print("unknow state")
        }
    }
    
    /// 每当 Central Manager 搜索到一个 Peripheral 设备时
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("发现了一个外设：\(peripheral.name)")
        
        if !self.peripheralArray.contains(peripheral) {
            self.peripheralArray.append(peripheral)
            self.tableView.reloadData()
        }
    }
    
    /// 与外设成功连接
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        // 发现需要外设的服务
        /*
         在实际开发中，传入的参数一般不为 nil，传入 nil 会返回全部的可用 Service，为了节省电量以及一些不必要的时间浪费，通过指定一个 Service Array（包含 UUID 对象）为参数，来获取你想要了解的 Service 的信息
         */
        self.configPeripheral?.discoverServices([CBUUID(string: UUID_SERVICE)])
    }
    
}


extension FindGameController: CBPeripheralDelegate {
    /// 外设发现指定服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        var service: CBService?
        if let services = peripheral.services {
            for ser in services {
                print("Discover service: \(ser)")
                if ser.uuid.isEqual(CBUUID(string: UUID_SERVICE)) {
                    service = ser
                    break
                }
            }
        }
        
        // 找到指定的service时，下一步要做的就是搜索这个 Service 中提供的所有的 Characteristic
        if let ser = service {
            peripheral.discoverCharacteristics([CBUUID(string: UUID_READABLE), CBUUID(string: UUID_WRITEABLE)], for: ser)
        }
    }
    
    /// 服务发现特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
/*
 <CBCharacteristic: 0x2800a0de0, UUID = 2224537A-5EB3-4CA1-884C-2656E62FDE7C, properties = 0x2, value = (null), notifying = NO>
         
 <CBCharacteristic: 0x2800a0d20, UUID = A06CC76E-D143-4736-85D1-F1E8C8C8ED34, properties = 0x88, value = (null), notifying = NO>
 */
        
        if let characteristics = service.characteristics {
            var writeChar: CBCharacteristic?
            var readChar: CBCharacteristic?
            
            for characteri in characteristics {
                print("Disvocer characteristic: \(characteri)")
                
                if characteri.uuid.isEqual(CBUUID(string: UUID_READABLE)) {
                    readChar = characteri
                } else if characteri.uuid.isEqual(CBUUID(string: UUID_WRITEABLE)) {
                    writeChar = characteri
                }
            }
            
            // 读取值
            if let character = readChar {
                peripheral.readValue(for: character)
                
                // 订阅指定 Characteristic 的值
                peripheral.setNotifyValue(true, for: character)
            }
//
//            // 写入值
//            if let character = writeChar {
//                peripheral.writeValue(Data(), for: character, type: .withResponse)
//            }
        }
    }
    
    /// 尝试去读取一个 Characteristic 的值时，此回调来返回结果
    /*
     并不是所有的 Characteristic 的值都是可读的，决定一个 Characteristic 的值是否可读是通过检查 Characteristic 的 Properties 属性是否包含 CBCharacteristicPropertyRead 常量来判断的。当你尝试去读取一个值不可读的 Characteristic 时，Peripheral 会通过 peripheral:didUpdateValueForCharacteristic:error: 给你返回一个合适的错误。
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if !characteristic.uuid.isEqual(CBUUID(string: UUID_READABLE)) {
            return
        }
        
        print("读取需要的值")
    }
    
    /*
     写一个数据到 Characteristic 中时，你可以指定写入类型，上面代码中的写入类型是 CBCharacteristicWriteWithResponse ，此类型时，Peripheral 会通过 peripheral:didWriteValueForCharacteristic:error: 方法来代理回调告知你是否写入数据成功，可以实现下面这个代理方法进行错误处理。
     */
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    
    
    
    
    /*
     有的 Characteristic 的值可能仅仅是可写的，或者不是可写的。决定 Characteristic 的值是否可写，需要通过查看 Characteristic 的 properties 属性是否包含 CBCharacteristicPropertyWriteWithoutResponse 或者 CBCharacteristicPropertyWrite 常量来判断的。
     */
    
    ///订阅或取消订阅一个 Characteristic 的值时，Peripheral 会通过调用
    /*
     并不是所有的 Characteristic 都提供订阅功能，决定一个 Characteristic 是否能订阅是通过检查 Characteristic 的 properties 属性是否包含 CBCharacteristicPropertyNotify 或者 CBCharacteristicPropertyIndicate  常量来判断的。
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if !characteristic.uuid.isEqual(CBUUID(string: UUID_READABLE)) {
            return
        }
        
        let message = characteristic.value?.toString()
        
        switch message {
        case READY_TO_BEGIN:
            print("I can ready for game")
            // 我可以准备了
        case START_GAME:
            print("Game is playing")
            // 我方可开始放置
        default:
            print("")
        }
        
        print("didUpdateNotificationStateFor")
    }
    
    
    
}



extension FindGameController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripheralArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if let lbl = cell.textLabel {
            lbl.text = self.peripheralArray[indexPath.row].name
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.configPeripheral = self.peripheralArray[indexPath.row]
        
        self.configPeripheral?.delegate = self
        
        if let per = self.configPeripheral {
            self.centralManager?.connect(per, options: nil)
        }
    }
}
