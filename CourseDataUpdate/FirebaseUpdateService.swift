//
//  File.swift
//  CourseDataUpdate
//
//  Created by Yuanze Hu on 3/20/17.
//  Copyright © 2017 Yuanze Hu. All rights reserved.
//

import Firebase


class FirebaseUpdateService{
    init(){
        
        
    }
    
    //this function will be called to put a new course on firebase
    func postCourse(term:String,courseID:String, name:String,description: String, block:String, time:String,bookUrl:String ,teacherUrl:String)->Bool{
        return false
    }
    

    func report() -> String {
        //return a general report of current status of the firebase
        //including but not limited with: last update time, number of items, number of terms .....
        
        return "Firebase not initialized yet."
    }
    
    
    
    
    
    
}
