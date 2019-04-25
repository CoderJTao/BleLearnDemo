//
//  BleLocalPeripher.swift
//  BleDemo
//
//  Created by JiangT on 2019/4/25.
//  Copyright © 2019 江涛. All rights reserved.
//

import Foundation
import CoreBluetooth

class LocalPeripher: NSObject {
    private var status = ConnectStatus.waiting
    
    var myPeripheral: CBPeripheralManager?
    
    var myService: CBMutableService?
    
    var myCharacteristic_beRead: CBMutableCharacteristic?
    var myCharacteristic_beWrite: CBMutableCharacteristic?
    
    override init() {
        super.init()
        
        myPeripheral = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey : true])
    }
    
    private func configServiceAndCharacteristic() {
        
        let characteristic_read = CBUUID(string: UUID_READABLE)
        let characteristic_write = CBUUID(string: UUID_WRITEABLE)
        
        let serviceUUID = CBUUID(string: UUID_SERVICE)
        /*
         如果你指定了 Characteristic 的值，那么该值将被缓存并且该 Characteristic 的 properties 和 permissions 将被设置为可读的。因此，如果你需要 Characteristic 的值是可写的，或者你希望在 Service 发布后，Characteristic 的值在 lifetime（生命周期）中依然可以更改，你必须将该 Characteristic 的值指定为 nil。通过这种方式可以确保 Characteristic 的值,在 Peripheral Manager 收到来自连接的 Central 的读或者写请求的时候，能够被动态处理。
         */
        
        // 为服务指定一个特征    读取特征   可被订阅
        myCharacteristic_beRead = CBMutableCharacteristic(type: characteristic_read,
                                                          properties: [.read, .notify],
                                                          value: nil,
                                                          permissions: .readable)
        
        myCharacteristic_beWrite = CBMutableCharacteristic(type: characteristic_write,
                                                           properties: .write,
                                                           value: nil,
                                                           permissions: .writeable)
        
        
        // 创建一个服务
        myService = CBMutableService(type: serviceUUID, primary: true)
        
        // 将特征加入到服务中
        myService!.characteristics = ([myCharacteristic_beRead, myCharacteristic_beWrite] as! [CBCharacteristic])
        
        // 将服务加入到外设中
        /*
         当你发布 Service 和相关的 Characteristic 到 Peripheral 的数据库中后，设备已经将数据缓存，你不能再改变它了。
         */
        
        myPeripheral?.add(myService!)
        
        // 广播自己的service
        /*
         
         */
        myPeripheral?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [myService!.uuid]])
    }
}

extension LocalPeripher: CBPeripheralManagerDelegate {
    /// 当调用添加服务的方法时，回调
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if error != nil {
            print("Error publishing service: \(error!.localizedDescription)")
        }
        
        print(#function)
    }
    
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print(#function)
        
        switch peripheral.state {
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
            configServiceAndCharacteristic()
        default:
            print("unknow state")
        }
        
    }
    
    
    /// 当你在本地设备中广播一些数据时
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print(#function)
    }
    
    
    /*
     无论读写时，应该确保请求的 offset 属性的范围有效。
     */
    /// 收到来自中心设备读取数据的请求
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print(#function)
        
        guard let beRead = myCharacteristic_beRead else { return }
        
        /// 判断request是否是自己的认可的
        if request.characteristic.uuid.isEqual(CBUUID(string: UUID_READABLE)) {
            switch status {
            case .waiting:
                // 写入进入准备状态的值
                beRead.value = READY_TO_BEGIN.toData()
            case .ready: break
            //
            default:
                print("")
            }
            
            
            
            guard let value = beRead.value else {
                print("myCharacteristic_beRead value 为空")
                return
            }
            
            //确保读取请求的位置没有超出 Characteristic 的值的边界
            if request.offset > value.count {
                myPeripheral?.respond(to: request, withResult: CBATTError.Code.invalidOffset)
            } else {
                let range = Range(NSRange(location: request.offset, length: value.count - request.offset))!
                request.value = value.subdata(in: range)
                
                myPeripheral?.respond(to: request, withResult: CBATTError.Code.success)
            }
        }
    }
    
    /// 收到来自中心设备写入数据的请求
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print(#function)
        
        var temp: CBATTRequest?
        for req in requests {
            if req.characteristic.uuid.isEqual(CBUUID(string: UUID_WRITEABLE)) {
                temp = req
                break
            }
        }
        guard let request = temp else {
            myPeripheral?.respond(to: requests.first!, withResult: CBATTError.Code.writeNotPermitted)
            return
        }
        
        // 确认写入请求与自己的特征对应时
        myCharacteristic_beWrite?.value = request.value
        
        myPeripheral?.respond(to: requests.first!, withResult: CBATTError.Code.success)
    }
    
    
    /// 当一个连接的 Central 订阅一个或多个你的 Characteristic 值时
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, characteristic: CBCharacteristic) {
        print(#function)
        
        let updateValue = Data()
        
        /*
         当你调用这个方法给订阅的 Central 发送通知时，你可以通过最后的那个参数来指定要发送的 Central，示例代码中的参数为 nil，表明将会发送通知给所有连接且订阅的 Central，没有订阅的 Central 则会被忽略。
         */
        let result = myPeripheral?.updateValue(updateValue, for: characteristic as! CBMutableCharacteristic, onSubscribedCentrals: nil)
        
    }
    
    /*
     updateValue:forCharacteristic:onSubscribedCentrals: 方法会返回一个 Boolean 类型的值来表示通知是否成功的发送给订阅的 Central 了，如果 base queue （基础队列）满载，该方法会返回 NO，当传输队列存在更多空间时，Peripheral Manager 则会调用 peripheralManagerIsReadyToUpdateSubscribers: 代理方法进行回调。你可以实现这个代理方法，在方法中再次调用 updateValue:forCharacteristic:onSubscribedCentrals: 方法发送通知给订阅的 Central。
     
     提示：用通知发送单个数据包给订阅的 Central，就是说，一旦订阅的 Central 发行更新时，你就应该调用 updateValue:forCharacteristic:onSubscribedCentrals: 方法用单一通知发送全部的更新值。
     
     并不是所有的数据都是通过通知来传输的，这主要取决于你的 Characteristic 的值的大小，只有当 Central 调用
     CBPeripheral类的 readValueForCharacteristic: 方法时，你可以检索全部的值。
     
     */
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        
    }
}

