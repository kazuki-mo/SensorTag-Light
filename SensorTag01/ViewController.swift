//
//  ViewController.swift
//  SensorTag01
//
//  Created by 守谷 一希 on 2015/09/15.
//  Copyright (c) 2015年 守谷 一希. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate, CBPeripheralDelegate {

    @IBOutlet weak var TV_Devices: UITableView!
    var myUuids: NSMutableArray = NSMutableArray()
    var myNames: NSMutableArray = NSMutableArray()
    var myPeripheral: NSMutableArray = NSMutableArray()
    var myTargetPeripheral: CBPeripheral!
    var myCentralManager: CBCentralManager!
    
    var connectedIndex: Int = 0
    var myTargetName: NSString!
    var Flag_ServiceFind = false
    
    @IBAction func BT_Reload(sender: AnyObject) {
        myNames = NSMutableArray()
        myUuids = NSMutableArray()
        myPeripheral = NSMutableArray()
        
        myCentralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TV_Devices.dataSource = self
        TV_Devices.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Cellの総数を返す
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myUuids.count
    }
    
    // Cellに値を設定する
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier:"MyCell" )
        
        cell.backgroundColor = UIColor.whiteColor()
        // Cellに値を設定.
        cell.textLabel!.sizeToFit()
        cell.textLabel!.textColor = UIColor.blackColor()
        cell.textLabel!.text = "         \(myNames[indexPath.row])"
        cell.textLabel!.font = UIFont.systemFontOfSize(20)
        //cell.textLabel?.alignmentRectForFrame(CGRectMake(60, 0, 100, 50))
        // Cellに値を設定(下).
        cell.detailTextLabel!.text = "                  \(myUuids[indexPath.row])"
        cell.detailTextLabel!.font = UIFont.systemFontOfSize(9)
        
        return cell
    }
    
    // Cellが選択された際に呼び出される
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
//        ConnectedName.text = "\(myNames[indexPath.row])"
//        ConnectedUuid.text = "\(myUuids[indexPath.row])"
        
        connectedIndex = indexPath.row
        myTargetName = myNames[indexPath.row] as NSString
        
        self.myTargetPeripheral = myPeripheral[indexPath.row] as CBPeripheral
        myCentralManager.connectPeripheral(self.myTargetPeripheral, options: nil)
        
    }
    
    // CBCentralManagerのインスタンスを生成すると呼び出される
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        println("state \(central.state)");
        switch (central.state) {
        case .PoweredOff:
            println("Bluetoothの電源がOff")
        case .PoweredOn:
            println("Bluetoothの電源はOn")
            // BLEデバイスの検出を開始.
            myCentralManager.scanForPeripheralsWithServices(nil, options: nil)
        case .Resetting:
            println("レスティング状態")
        case .Unauthorized:
            println("非認証状態")
        case .Unknown:
            println("不明")
        case .Unsupported:
            println("非対応")
        }
    }
    
    // BLEデバイスが検出された際に呼び出される
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        
        var name: NSString? = advertisementData["kCBAdvDataLocalName"] as? NSString
        if (name == nil) {
            name = "no name";
        }
        
        var count = myUuids.count
        var Flag = true;
        for(var i=0;i<count;i++){
            if(myUuids[i] as NSString == peripheral.identifier.UUIDString){
                Flag = false;
            }
        }
        
        if(Flag){
            myNames.addObject(name!)
            
            myPeripheral.addObject(peripheral)
            myUuids.addObject(peripheral.identifier.UUIDString)
            
            TV_Devices.reloadData()
        }
    }
    
    // BLEデバイスと接続すると呼び出される
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!){
        
        self.myTargetPeripheral.delegate = self
        self.myTargetPeripheral.discoverServices(nil)
        
    }
    
    // BLEデバイスとの接続に失敗すると呼び出される
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!){
        println("not connnect")
    }
    
    // 接続済みデバイスとの接続が切断されると呼び出される
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        Flag_ServiceFind = false
    }
    
    // サービスが発見されると呼び出される
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        Flag_ServiceFind = true
        println("Check!!")
        
        let myLightGetViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LightGetView") as LightGetViewController
        
        myLightGetViewController.setPeripheral(self.myTargetPeripheral)
        
        var targetService:CBService = self.myTargetPeripheral.services[0] as CBService
        for service in self.myTargetPeripheral.services{
            let servicee = service as CBService
            if(servicee.UUID.UUIDString == "F000AA70-0451-4000-B000-000000000000"){
                targetService = service as CBService
            }
        }
        myLightGetViewController.setService(targetService)
        myLightGetViewController.setName(myTargetName)
        
        // アニメーションを設定する.
        myLightGetViewController.modalTransitionStyle = UIModalTransitionStyle.PartialCurl
        
        // Viewの移動する.
        self.navigationController?.pushViewController(myLightGetViewController, animated: true)
    }

}

