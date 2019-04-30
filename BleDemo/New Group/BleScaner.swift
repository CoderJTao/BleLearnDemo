//
//  BleScaner.swift
//  BleDemo
//
//  Created by JiangT on 2019/4/25.
//  Copyright © 2019 江涛. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BleScanerDelegate: AnyObject {
    func scaner(_ scaner: BleScaner, didFound peripherals: [CBPeripheral])
    
    func scaner(_ scaner: BleScaner, didConnect peripheral: CBPeripheral)
    
    func scaner(_ scaner: BleScaner, didDiscoverReadableCharacteristic  characteristic: CBCharacteristic)
    
    func scaner(_ scaner: BleScaner, didDiscoverWriteableCharacteristic characteristic: CBCharacteristic)
    
    func scaner(_ scaner: BleScaner, didUpdateNotifyValue value: String)
}

class BleScaner: NSObject {
    var status = ConnectStatus.waiting
    
    weak var delegate: BleScanerDelegate?
    
    private var centralManager: CBCentralManager?
    
    // 强引用搜索到的外设。否则会被释放
    private var peripheralArray: [CBPeripheral] = []
    
    private var configPeripheral: CBPeripheral?
    
    private var myCharacteristic_toRead: CBCharacteristic?
    private var myCharacteristic_toWrite: CBCharacteristic?
    
    var isConnected = false
    
    override init() {
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey : true])
    }
    
    private func startScan() {
        print(#function)
        self.centralManager?.scanForPeripherals(withServices: [CBUUID(string: UUID_SERVICE)], options: [CBPeripheralManagerOptionShowPowerAlertKey : true])
    }
    
    func writeValue(_ value: String) {
        guard let characteristic = myCharacteristic_toWrite else {
            return
        }
        
        switch value {
        case I_AM_COMMING:
            self.status = .beforeReady
        case I_AM_READY:
            self.status = .isReady
        case PLAY_AGAIN:
            self.status = .isReady
        default:
            // 棋子的坐标
            print("player put his piece value: \(value)")
        }
        
        if let data = value.toData() {
            self.configPeripheral?.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
}


extension BleScaner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(#function)
        
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
        print(#function)
        
        
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            if let uuid = serviceUUIDs.first?.uuidString, uuid == UUID_SERVICE {
                self.configPeripheral = peripheral
                
                self.configPeripheral?.delegate = self
                
                if !self.peripheralArray.contains(peripheral) {
                    self.peripheralArray.append(peripheral)
                    self.delegate?.scaner(self, didFound: self.peripheralArray)
                }
                
                self.centralManager?.connect(peripheral, options: nil)
                
                self.centralManager?.stopScan()
            }
        }
    }
    
    /// 与外设成功连接
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print(#function)
        
        // 发现需要外设的服务
        /*
         在实际开发中，传入的参数一般不为 nil，传入 nil 会返回全部的可用 Service，为了节省电量以及一些不必要的时间浪费，通过指定一个 Service Array（包含 UUID 对象）为参数，来获取你想要了解的 Service 的信息
         */
        self.configPeripheral?.discoverServices([CBUUID(string: UUID_SERVICE)])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(#function)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print(#function)
    }
}


extension BleScaner: CBPeripheralDelegate {
    /// 外设发现指定服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print(#function)
        
        var service: CBService?
        if let services = peripheral.services {
            for ser in services {
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
        print(#function)
        /*
         <CBCharacteristic: 0x2800a0de0, UUID = 2224537A-5EB3-4CA1-884C-2656E62FDE7C, properties = 0x2, value = (null), notifying = NO>
         
         <CBCharacteristic: 0x2800a0d20, UUID = A06CC76E-D143-4736-85D1-F1E8C8C8ED34, properties = 0x88, value = (null), notifying = NO>
         */
        
        if let characteristics = service.characteristics {
            var writeChar: CBCharacteristic?
            var readChar: CBCharacteristic?
            
            for characteri in characteristics {
                if characteri.uuid.isEqual(CBUUID(string: UUID_READABLE)) {
                    readChar = characteri
                } else if characteri.uuid.isEqual(CBUUID(string: UUID_WRITEABLE)) {
                    writeChar = characteri
                }
            }
            
            // 读取值
            if let character = readChar {
                // 订阅指定 Characteristic 的值
                self.myCharacteristic_toRead = character
                
                peripheral.setNotifyValue(true, for: character)
                
                self.delegate?.scaner(self, didDiscoverReadableCharacteristic: character)
            }
            
            if let character = writeChar {
                
                self.myCharacteristic_toWrite = character
                self.delegate?.scaner(self, didDiscoverWriteableCharacteristic: character)
            }
        }
    }
    
    /// 尝试去读取一个 Characteristic 的值时，此回调来返回结果
    /*
     并不是所有的 Characteristic 的值都是可读的，决定一个 Characteristic 的值是否可读是通过检查 Characteristic 的 Properties 属性是否包含 CBCharacteristicPropertyRead 常量来判断的。当你尝试去读取一个值不可读的 Characteristic 时，Peripheral 会通过 peripheral:didUpdateValueForCharacteristic:error: 给你返回一个合适的错误。
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print(#function)
        if !characteristic.uuid.isEqual(CBUUID(string: UUID_READABLE)) {
            return
        }
        
        guard let message = characteristic.value?.toString() else {
            return
        }
        
        switch message {
        case READY_TO_BEGIN:
            print("Receive ReadyToBegin from Peripheral")
        case START_GAME:
            print("Receive Start Game from Peripheral")
            self.status = .isPlaying
        default:
            // 收到棋子的坐标信息
            print("Receive piece position from Peripheral")
            
            if message.hasPrefix("Last:") {
                // 对方落子之后赢得比赛
                print("Receive Game Over from Peripheral")
                self.status = .gameOver
            }
        }
        
        self.delegate?.scaner(self, didUpdateNotifyValue: message)
    }
    
    /*
     写一个数据到 Characteristic 中时，你可以指定写入类型，上面代码中的写入类型是 CBCharacteristicWriteWithResponse ，此类型时，Peripheral 会通过 peripheral:didWriteValueForCharacteristic:error: 方法来代理回调告知你是否写入数据成功，可以实现下面这个代理方法进行错误处理。
     */
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print(#function)
        
        if error == nil {
            return
        }
        
//        guard let readable = myCharacteristic_toRead else { return }
        
//        self.configPeripheral?.readValue(for: readable)
    }
    
    
    /*
     有的 Characteristic 的值可能仅仅是可写的，或者不是可写的。决定 Characteristic 的值是否可写，需要通过查看 Characteristic 的 properties 属性是否包含 CBCharacteristicPropertyWriteWithoutResponse 或者 CBCharacteristicPropertyWrite 常量来判断的。
     */
    
    ///订阅或取消订阅一个 Characteristic 的值时，Peripheral 会通过调用
    /*
     并不是所有的 Characteristic 都提供订阅功能，决定一个 Characteristic 是否能订阅是通过检查 Characteristic 的 properties 属性是否包含 CBCharacteristicPropertyNotify 或者 CBCharacteristicPropertyIndicate  常量来判断的。
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print(#function)
        
        if !characteristic.uuid.isEqual(CBUUID(string: UUID_READABLE)) {
            return
        }
        
        if characteristic.isNotifying {
//            peripheral.readValue(for: characteristic)
            print("characteristic.isNotifying true")
        } else {
            print("characteristic.isNotifying false")
        }
    }
}

