//
//  Common.swift
//  BleDemo
//
//  Created by 江涛 on 2019/4/25.
//  Copyright © 2019 江涛. All rights reserved.
//

import Foundation

// 在终端利用 uuidgen 命令生成
let UUID_SERVICE = "65186161-1F1C-43EC-B302-C92ACE5F7D01"

let UUID_READABLE = "2224537A-5EB3-4CA1-884C-2656E62FDE7C"
let UUID_WRITEABLE = "A06CC76E-D143-4736-85D1-F1E8C8C8ED34"


// MARK: - 交互步骤中，centralManager 与 Peripheral 的互相定义的消息
let I_AM_COMMING = "I am comming"          // from centralManager
let READY_TO_BEGIN = "ReadyToBegin"        // from Peripheral
let I_AM_READY = "I am ready"              // from centralManager
let START_GAME = "Let's rock and roll"     // from both
let PLAY_AGAIN = "Play again"              // from both

enum Role {
    case unknow
    case peripheral
    case central
}

enum ConnectStatus {
    case waiting    
    case beforeReady
    case isReady
    case isPlaying
    case gameOver
}


// MARK: - string 与 data 互转
extension String {
    func toData() -> Data? {
        return self.data(using: String.Encoding.utf8)
    }
    
    func isValidPosition() -> Bool {
        let arr = self.components(separatedBy: "-")
        
        if arr.count != 2 {
            return false
        }
        
        let xValue = arr.first
        let yValue = arr.last
        
        guard let x = xValue, let y = yValue else {
            return false
        }
        
        guard let xInt = Int(x), let yInt = Int(y) else {
            return false
        }
        
        if xInt < 0 || xInt > 16 || yInt < 0 || yInt > 16 {
            return false
        }
        
        return true
    }
}

extension Data {
    func toString() -> String? {
        return String(data: self, encoding: String.Encoding.utf8)
    }
}
