//
//  GameController.swift
//  BleDemo
//
//  Created by 江涛 on 2019/4/25.
//  Copyright © 2019 江涛. All rights reserved.
//

import UIKit

class GameController: UIViewController {

    @IBOutlet weak var boardView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let arr = ["12-11", "0-0", "16-16", "5-9", "15-3"]
        
        for str in arr {
            putPiece(str, role: .central)
        }
        
    }
}


extension GameController {
    private func createPieces(_ role: Role) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 6))
        view.backgroundColor = (role == Role.peripheral) ? UIColor.red : UIColor.purple
        
        view.clipsToBounds = true
        view.layer.cornerRadius = 3
        
        return view
    }
    
    
    // string : 12-2
    private func putPiece(_ coordinates: String, role: Role) {
        
        let piece = createPieces(.central)
        
        let arr = coordinates.components(separatedBy: "-")
        
        
        
        var x = Int(arr.first!)! * 20
        var y = Int(arr.last!)! * 20
    
        piece.center = CGPoint(x: x, y: y)
        
        self.boardView.addSubview(piece)
    }
}
