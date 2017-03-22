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
    
    var loader : LoadingCourseInfo?
    
    
    @IBOutlet var updateBut: UIButton!
    @IBOutlet var console: UITextView!
    
    @IBAction func clickUpdate(_ sender: Any) {
        updateBut.isEnabled = false
        indicator.startAnimating()
        loader!.start()

        

    }
    
    public func stopAnimation(){
        
        DispatchQueue.main.async {
            self.indicator.stopAnimating()
        }
    }
    
    public func println(newLine:String){
        DispatchQueue.main.async {
            print(newLine)
            self.console.print(newLine: newLine)
            let bottomOffset = CGPoint(x: 0, y: self.console.contentSize.height - self.console.bounds.size.height)
            self.console.setContentOffset(bottomOffset, animated: true)
        }
    }
    

    @IBOutlet var indicator: NVActivityIndicatorView!
    

    override func viewDidLoad() {
        
        super.viewDidLoad()
        loader = LoadingCourseInfo(vc: self)
        updateBut.layer.cornerRadius = 5
        console.text = loader!.report()
        indicator.type = .lineScale 
        indicator.color = UIColor(red: 250.0/255.0, green: 128.0/255.0, blue: 114.0/255.0, alpha: 1.0)
        
    
    
    
    }

    

}

