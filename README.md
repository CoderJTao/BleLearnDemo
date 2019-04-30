# BleLearnDemo

# 前言

最近公司的项目中刚好用到了 CoreBluetooth 相关的知识，在看了网上很多文章及[官方文档](https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothOverview/CoreBluetoothOverview.html)的介绍后，现在对大概的框架有了基本的了解。

在此，写下这篇文章记录自己这段时间的成果。文章的最后会有一个小Demo，简单的实现了一些基本的功能，供各位看官把玩。Demo的代码可以去[我的Github](https://github.com/CoderJTao/BleLearnDemo)中下载。


![](https://user-gold-cdn.xitu.io/2019/4/30/16a6d24f70a0e32d?w=970&h=447&f=png&s=84343)

这篇文章主要以实践的方式，实现了蓝牙交互中的两个角色。关于基本概念的介绍，[官方文档](https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothOverview/CoreBluetoothOverview.html)中介绍的非常详细，大家可以仔细研究一下。

# Central 和 Peripheral

## 核心概念

CoreBluetooth 中最关键的两个角色就是 Central(中心) 和 Peripheral（周边）。

Central 在连接中作为主动发起者会去寻找待连接的 Peripheral。

Peripheral 一般是提供服务的一方， Central 获取 Peripheral 提供的服务然后来完成特定的任务。

Peripheral 通过向空中广播数据的方式来使我们能感知到它的存在。Central 通过扫描搜索来发现周围正在广播数据的 Peripheral, 找到指定的 Peripheral 后，发送连接请求进行连接，连接成功后则与 Peripheral 进行一些数据交互， Peripheral 则会通过合适的方式对 Central 进行响应。

## 实现 Central 的功能

这是在开发中最常见的一个需求，需要自身作为 Central 的对象，去发现一些外设的服务，并根据其提供的数据进行相应的操作。例如，连接一个小米手环，根据其提供的步数、心率等信息调整UI的显示。

**实现步骤：**

### 1. 创建Central Manager

```
centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey : true])
```

* **delegate：** centralManager的代理
* **queue：** 接收回调事件的线程
* **options:**
* CBCentralManagerOptionShowPowerAlertKey: 当蓝牙状态为 powered off时，系统会弹出提示框。

* CBCentralManagerOptionRestoreIdentifierKey：生成一个唯一的标识符，用于后续应用恢复这个manager。

当创建了 CentralManager 之后， CBCentralManagerDelegate 会通过下面的回调告知你，当前设备是否支持你去使用蓝牙的功能。

```
func centralManagerDidUpdateState(_ central: CBCentralManager)
```

通过 central.state 可以获取当前的状态

```
case unknown        //未知状态
case resetting      // 连接断开，即将重置
case unsupported    // 该设备不支持蓝牙
case unauthorized   // 蓝牙未授权
case poweredOff     // 蓝牙关闭
case poweredOn      // 蓝牙正常开启
```

只有当蓝牙的状态为正常开启的状态时，才能进行后续的步骤。

### 2. 搜索正在广播数据的 Peripheral 设备

##### 1. 开始搜索

```
self.centralManager?.scanForPeripherals(withServices: [CBUUID(string: UUID_SERVICE)], options: [CBCentralManagerOptionShowPowerAlertKey : true])
```

* **serviceUUIDs：** 写入这个参数，说明搜索拥有这个特定服务的 Peripheral，若传入nil，则搜索附近所有的 Peripheral。

> UUID_SERVICE 通常是由Central及Peripheral自己定义的，两端使用同一个UUID。

##### 2. 处理搜索结果

每当 CentralManager 搜索到一个 Peripheral 设备时，就会通过代理方法进行回调。如果你后面需要连接这个 Peripheral，需要定义一个 CBPeripheral 类型的对象来指向（强引用）这个对象，这样系统暂时就不会释放这个对象了。

```
func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
```

* **advertisementData：** Peripheral 开始广播时，放入的数据。 
* **RSSI：** 代表发现的 Peripheral 的信号强度。

> 当发现自身需要的 Peripheral 时，为了减少蓝牙对电量的消耗，可以停止CentralManager的扫描。
> self.centralManager?.stopScan()

### 3. 连接自身需要的 Peripheral 设备

##### 1. 开始连接

```
self.centralManager?.connect(peripheral, options: nil)
```

##### 2. 处理连接结果

* 当 CentralManager 与 Peripheral 成功连接时

```
func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
```

当成功连接 Peripheral 之后，我们需要去查找 Peripheral 为我们提供的服务。为了能收到 Peripheral 查找的结果，我们需要去遵守 Peripheral 对象的代理方法 CBPeripheralDelegate。

```
self.configPeripheral?.delegate = self
```


* 当 CentralManager 与 Peripheral 连接失败时

```
func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
```

### 4. 搜索连接设备的 Services

##### 1. 查找 Service

```
self.configPeripheral?.discoverServices([CBUUID(string: UUID_SERVICE)])
```

这里我们可以传入一个关于 Service 的一个数组，查找自己需要的 Service。当然也可以传入 nil，这样就会查找到 Peripheral 提供的全部 Service。

但是，一般来说，为了节省电量以及一些不必要的时间浪费，会传入自己需要的 Service 的数组。

##### 2. 处理搜索结果

```
func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
```

CBPeripheralDelegate 的 搜索 Service 回调。在这里出现错误之后，可以进行重试或者抛出停止连接流程。

若成功的话，则可以继续搜索对应 Service 的 Characteristic。

### 5. 搜索 Services 的 Characteristic

##### 1.开始搜索

```
peripheral.discoverCharacteristics([CBUUID(string: UUID_READABLE), CBUUID(string: UUID_WRITEABLE)], for: service)
```

* **characteristicUUIDs：** 参数接收一个 Characteristic UUID 的数组对象。若传入，则搜索对应的 Characteristic，否则则会搜索 Service 拥有的所有 Characteristic。

##### 2. 处理搜索结果

```
func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
```

CBPeripheralDelegate 的 搜索 Characteristic 的回调。若 Characteristic 有多个，则此方法会回调多次。

##### 3. 使用 Characteristic 

* 读取 Characteristic 的值

```
peripheral.readValue(for: characteristic)
```

当你尝试去读取一个 Characteristic 的值时， Peripheral 会通过下面的代理回调来返回结果，你可以通过 Characteristic 的 value 属性来得到这个值。

并不是所有的 Characteristic 的值都是可读的，决定一个 Characteristic 的值是否可读是通过检查 Characteristic 的 Properties 属性是否包含 CBCharacteristicPropertyRead 常量来判断的。当你尝试去读取一个值不可读的 Characteristic 时，下面的代理方法会返回一个Error供你处理。

```
func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
```


* 订阅 Characteristic 的值

当一个我们需要读取 Characteristic 的值，频繁变化时，read 操作就会显得很繁琐。这个时候我们就可以通过订阅的方式获取值得更新。如果订阅了某个 Characteristic 之后，每当值有变化时，也会通过 peripheral(_ peripheral:, didUpdateValueFor characteristic:, error:) 方法回调使我们收到每次更新的值。

```
peripheral.setNotifyValue(true, for: characteristic)
```

当我们订阅了一个 Characteristic 后，CBPeripheralDelegate 会通过下面的回调，使我们知道订阅的 Characteristic 的状态。

```
func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
```

并不是所有的 Characteristic 都提供订阅功能，决定一个 Characteristic 是否能订阅是通过检查 Characteristic 的 properties 属性是否包含 CBCharacteristicPropertyNotify 或者 CBCharacteristicPropertyIndicate  常量来判断的。


* 写入数据到 Characteristic

决定 Characteristic 的值是否可写，需要通过查看 Characteristic 的 properties 属性是否包含 CBCharacteristicPropertyWriteWithoutResponse 或者 CBCharacteristicPropertyWrite 常量来判断的。

```
peripheral.writeValue(data, for: characteristic, type: .withResponse)
```

type: 写入类型。
* .withResponse：写入后，会通过下面的回调告知写入的结果。
* .withoutResponse：无回调消息。

```
func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
```


## 实现 Peripheral 的功能

将自身声明为一个 Peripheral，可为 Central 对象提供一些服务。例如：在A手机利用连接B手机时，B手机此时就是 Peripheral 对象。

**实现步骤：**

### 1. 创建 Peripheral Manager

```
myPeripheral = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey : true])
```

当创建了 Peripheral 之后， CBPeripheralManagerDelegate 会通过下面的回调告知你，当前设备是否支持你去使用蓝牙的功能。

状态同 CentralManager 一样的。

```
func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
```

只有当蓝牙的状态为正常开启的状态时，才能进行后续的步骤。

### 2. 设置自身的 Services 和 Characteristics

```
let characteristic_read = CBUUID(string: UUID_READABLE)
let characteristic_write = CBUUID(string: UUID_WRITEABLE)

let serviceUUID = CBUUID(string: UUID_SERVICE)

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
```

上面的代码中，我们创建了两个 Characteristic，一个可读且可被订阅，另一个可写。这个是通过实例化时，传入的 properties 及 permissions 的值来指定的。

这里需要注意的是 value 传入的值是 nil。因为，如果你指定了 Characteristic 的值，那么该值将被缓存并且该 Characteristic 的 properties 和 permissions 将被设置为可读的。因此，如果你需要 Characteristic 的值是可写的，或者你希望在 Service 发布后，Characteristic 的值在 lifetime（生命周期）中依然可以更改，你必须将该 Characteristic 的值指定为 nil。通过这种方式可以确保 Characteristic 的值,在 PeripheralManager 收到来自连接的 Central 的读或者写请求的时候，能够被动态处理。

### 3. 添加服务特征

```
// 将特征加入到服务中
myService!.characteristics = ([myCharacteristic_beRead, myCharacteristic_beWrite] as! [CBCharacteristic])

// 将服务加入到外设中
myPeripheral?.add(myService!)
```

这里我们将自己的服务构建完成，并将服务添加至 Peripheral 中。这样，当 Peripheral 向外界发送广播时，就可以搜索这个服务获取相应的支持。

### 4. 广播自己的服务

```
// 广播自己的service
myPeripheral?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [myService!.uuid], CBAdvertisementDataLocalNameKey: "我创建了一个房间"])
```

在广播时，可以同时携带一些数据。这里可以传入一个字典，但是这个字典只支持传入 CBAdvertisementDataLocalNameKey 及 CBAdvertisementDataServiceUUIDsKey。

关于广播方法官方文档的说明如下：

> When in the foreground, an application can utilize up to 28 bytes of space in the initial advertisement data for any combination of the supported advertising data types. If this space is used up, there are an additional 10 bytes of space in the scan response that can be used only for the local name. Note that these sizes do not include the 2 bytes of header information that are required for each new data type. Any service UUIDs that do not fit in the allotted space will be added to a special "overflow" area, and can only be discovered by an iOS device that is explicitly scanning for them.

> While an application is in the background, the local name will not be used and all service UUIDs will be placed in the "overflow" area. However, applications that have not specified the "bluetooth-peripheral" background mode will not be able  to advertise anything while in the background.

大概意思是：

当处于前台时，应用程序可以在初始广告数据中利用28个字节的空间用来初始化广播数据字典，该字典包含两个支持的 key。如果此空间已用完，扫描响应时最后还会添加10个字节的空间，只能用于Local Name。

> 请注意，这些大小不包括每种新数据类型所需的2个字节的头部信息。任何不适合分配空间的服务UUID都将添加到特殊的“溢出”区域，并且只能由明确扫描它们的iOS设备发现。

当应用程序在后台时，将不使用本地名称，并且所有服务UUID将放置在“溢出”区域中。但是，未指定“蓝牙后台运行”背景模式的应用程序将无法在后台播放任何内容。


### 5. 响应 Central 的读写请求

```
/// 收到来自中心设备读取数据的请求
func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest)

/// 收到来自中心设备写入数据的请求
func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest])
```

当 Peripheral 收到来自 Central 的读写请求时，CBPeripheralManagerDelegate 会通过上面两个方法来进行回调。读写请求以 CBATTRequest 对象来传递。

当我们收到请求时，可以根据 CBATTRequest 请求的一些属性来判断 Central 指定要读写的 Characteristic 是否和设备服务库中的 Characteristic 是否相匹配。

```
if request.characteristic.uuid.isEqual(CBUUID(string: UUID_READABLE)) { 
// do something 
myPeripheral?.respond(to: request, withResult: CBATTError.Code.success)
} else {
// not match
myPeripheral?.respond(to: request, withResult: CBATTError.Code.readNotPermitted)
}
```

最后使用 respond(to:, withResult:) 回应 Central 请求。

这里的 **result** 是一个 CBATTError.Code 类型，这里定义了很多对 Request 响应的枚举，可以根据对 Request 的响应，返回相应的 CBATTError.Code 值。


# 蓝牙学习小实践

利用蓝牙连接两个设备，进行一场激情的五子棋小游戏吧。

示例工程可以去[我的Giuhub](https://github.com/CoderJTao/BleLearnDemo)下载。

目前工程内完成了基本的两端交互逻辑。对于掉线重连等优化问题目前[示例工程](https://github.com/CoderJTao/BleLearnDemo)内尚未体现。

**创建房间：** 实现 Local Peripheral 端功能。将自己创建了房间的消息进行广播，使其它玩家可以扫描到房间进入游戏。并利用一个可被订阅的 Characteristic 将消息传输给 Central，一个可写的 Characteristic 接收来自 Central 的消息。

**寻找房间：** 实现 Local Central 端功能。可以扫描其它玩家创建的房间并加入游戏。通过可写的 Characteristic 将消息传输给 Peripheral，订阅一个 Characteristic 来获取值更新的通知。

<figure class="half">
<img src="https://github.com/CoderJTao/BleLearnDemo/blob/master/images/Peripheral.gif">
<img src="https://github.com/CoderJTao/BleLearnDemo/blob/master/images/Central.gif">
</figure>
