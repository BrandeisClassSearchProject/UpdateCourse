//
//  ViewController.swift
//  CourseDataUpdate
//
//  Created by Yuanze Hu on 3/20/17.
//  Copyright © 2017 Yuanze Hu. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import Firebase



class ViewController: UIViewController {
    
    let loader : LoadingCourseInfo = LoadingCourseInfo()
    
    @IBOutlet var updateBut: UIButton!
    @IBOutlet var console: UITextView!
    
    @IBAction func clickUpdate(_ sender: Any) {
        updateBut.isEnabled = false
        indicator.startAnimating()
        let result = loader.start()
        // multi-threading implementation required later
        if !result{
            console.text = console.text + "\nUpdating...not implemented yet!"
        }
        // multi-threading implementation required later
        

    }
    

    @IBOutlet var indicator: NVActivityIndicatorView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        updateBut.layer.cornerRadius = 5
        console.text = loader.report()
        indicator.type = .lineScale 
        indicator.color = UIColor(red: 250.0/255.0, green: 128.0/255.0, blue: 114.0/255.0, alpha: 1.0)
        
    
    
    
    }

    

}

