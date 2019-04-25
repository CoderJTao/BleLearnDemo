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


// MARK: - 交互步骤中，centralManager 订阅的 Peripheral 的消息
let READY_TO_BEGIN = "ReadyToBegin"
let START_GAME = "RockAndRoll"

enum Role {
    case peripheral
    case central
}

enum ConnectStatus {
    case waiting    
    case canReady
    case ready
    case canStart
}


// MARK: - string 与 data 互转
extension String {
    func toData() -> Data? {
        return self.data(using: String.Encoding.utf8)
    }
}

extension Data {
    func toString() -> String? {
        return String(data: self, encoding: String.Encoding.utf8)
    }
}
