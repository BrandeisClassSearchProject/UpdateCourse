//
//  LoadingCourseInfo.swift
//  CourseDataUpdate
//
//  Created by Yuanze Hu on 3/20/17.
//  Copyright © 2017 Yuanze Hu. All rights reserved.
//

import Foundation
import Alamofire
import Kanna


class LoadingCourseInfo {
    
    let firedb: FirebaseUpdateService
    
    init(){
        firedb = FirebaseUpdateService()
    }
    
    //start working
    func start() -> Bool{
        
        return false
    }
    
    func report() -> String{
        return firedb.report()
    }
    
    
    
    
}
