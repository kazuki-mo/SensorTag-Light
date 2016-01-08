//
//  LightGetViewController.swift
//  SensorTag01
//
//  Created by 守谷 一希 on 2015/09/15.
//  Copyright (c) 2015年 守谷 一希. All rights reserved.
//

import UIKit
import CoreBluetooth

class LightGetViewController: UIViewController, CBPeripheralDelegate {
    
    @IBOutlet weak var Lb_uuid: UILabel!
    var myCharacteristics: NSMutableArray = NSMutableArray()
    var showSensors: NSMutableArray = NSMutableArray()
    var myCharacteristicsUuids: NSMutableArray = NSMutableArray()
    var myTargetPeriperal: CBPeripheral!
    var myService: CBService!
    var myName: NSString!
    var myTargetCharacteristics: CBCharacteristic!
    var mySendCharacteristics: CBCharacteristic!
    
    var send_value:[UInt8] = [0x01]
    
    var Connection1 = Connection()
    var Flag_Connect = false
    
    @IBAction func BT_Connect(sender: AnyObject) {
        if(Flag_Connect){
            Connection1.sendCommand("end")
            Flag_Connect = false
        }else{
            Connection1.connect()
            Flag_Connect = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Lb_uuid.text = myService.UUID.UUIDString
        
        self.myTargetPeriperal.delegate = self
        self.myTargetPeriperal.discoverCharacteristics(nil, forService: self.myService)
    }
    
    override func viewWillDisappear(animated: Bool) {
        println("Disappear!!")
        
        println("Disappear!!")
        send_value = [0x00]
        var data:NSData = NSData(bytes: send_value, length: 1);
        if(mySendCharacteristics != nil){
            println("Send Stop!!")
            self.myTargetPeriperal.writeValue(data, forCharacteristic: mySendCharacteristics, type: CBCharacteristicWriteType.WithResponse)
        }
        
        if(Flag_Connect){
            Connection1.sendCommand("end")
            Flag_Connect = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Characteristicsが見つかったら
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!,error: NSError!) {
        
        for characteristics in service.characteristics {
            myCharacteristicsUuids.addObject(characteristics.UUID)
            myCharacteristics.addObject(characteristics)
            if(characteristics.UUID == CBUUID(string: "F000AA72-0451-4000-B000-000000000000")){
                println("!!!WriteUUID!!!")
                mySendCharacteristics = characteristics as CBCharacteristic
                send_value = [0x01]
                var data:NSData = NSData(bytes: send_value, length: 1);
                if(mySendCharacteristics != nil){
                    self.myTargetPeriperal.writeValue(data, forCharacteristic: mySendCharacteristics, type: CBCharacteristicWriteType.WithResponse)
                }
            }
        }
        
        for myCharacteristic in myCharacteristics{
            if(myCharacteristic.UUID == CBUUID(string: "F000AA71-0451-4000-B000-000000000000")){
                self.myTargetPeriperal.setNotifyValue(true, forCharacteristic: myCharacteristic as CBCharacteristic)
                self.myTargetPeriperal.readValueForCharacteristic(myCharacteristic as CBCharacteristic)
            }
        }
    }
    
    // peripheralからの値の通知
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!){
        
        var notify_value:[UInt8] = [UInt8](count:20 , repeatedValue:0)
        var data: NSData = characteristic.value
        data.getBytes(&notify_value, length: data.length)
        
        if(characteristic.UUID == CBUUID(string: "F000AA71-0451-4000-B000-000000000000")){
            
            var lux:UInt16
            var output:Double
            var magnitude:Double
            var mantissa:Int
            var exponent:Int
            
            lux =  UInt16(notify_value[1])<<8
            lux += UInt16(notify_value[0])
            
            //println("Data: \(Double(lux) / 100.0)")
            
            mantissa = Int(lux & 0x0FFF)
            exponent = Int((lux >> 12) & 0xFF)
            
            magnitude = pow(2.0, Double(exponent))
            output = Double(mantissa) * magnitude
            
            println("Data: \(output/100.0)")
            Lb_uuid.text = "\(output/100.0)"
            
            if(Flag_Connect){
                Connection1.sendCommand("\(output/100.0)")
            }
        }
        
    }
    
    //接続先のPeripheralを設定
    func setPeripheral(target: CBPeripheral) {
        self.myTargetPeriperal = target
        println(target)
    }
    
    //接続先のサービスを設定
    func setService(service: CBService) {
        self.myService = service
        println(service)
    }
    
    // 接続先のデバイス名を設定
    func setName(name: NSString){
        self.myName = name
        println(name)
    }

}

class Connection : NSObject, NSStreamDelegate {
    let serverAddress: CFString = "192.168.10.79"
    let serverPort: UInt32 = 1111
    
    private var inputStream: NSInputStream!
    private var outputStream: NSOutputStream!
    
    func connect() {
        println("connecting...")
        
        var readStream:  Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(nil, self.serverAddress, self.serverPort, &readStream, &writeStream)
        
        self.inputStream = readStream!.takeRetainedValue()
        self.outputStream = writeStream!.takeRetainedValue()
        
        self.inputStream.delegate = self
        self.outputStream.delegate = self
        
        self.inputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        self.outputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        self.inputStream.open()
        self.outputStream.open()
        
        println("connect success!!")
        
    }
    
    
    func stream(stream: NSStream, handleEvent eventCode: NSStreamEvent) {
        //println(stream)
    }
    
    func sendCommand(command: String){
        var ccommand = command.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        self.outputStream.write(UnsafePointer(ccommand.bytes), maxLength: ccommand.length)
        println("Send: \(command)")
        
        if (command == "end"){
            self.outputStream.close()
            self.outputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            
            while (!inputStream.hasBytesAvailable){}
            let bufferSize = 1024
            var buffer = Array<UInt8>(count: bufferSize, repeatedValue: 0)
            let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
            if (bytesRead >= 0){
                buffer.removeRange(Range(start: bytesRead, end: bufferSize))
                var read = String(bytes: buffer, encoding: NSUTF8StringEncoding)!
                println("Receive: \(read)")
            }
            self.inputStream.close()
            self.inputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        }
    }
}
