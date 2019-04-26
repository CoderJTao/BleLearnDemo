//
//  ViewController.swift
//  BleDemo
//
//  Created by 江涛 on 2019/4/24.
//  Copyright © 2019 江涛. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func findGameClick(_ sender: Any) {
        let vc = GameController()
        vc.setRole(.central)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func createGameClick(_ sender: Any) {
        let vc = GameController()
        vc.setRole(.peripheral)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
