//
//  File.swift
//  CourseDataUpdate
//
//  Created by Yuanze Hu on 3/20/17.
//  Copyright © 2017 Yuanze Hu. All rights reserved.
//

import Firebase


class FirebaseUpdateService{
    
    let dbRef: FIRDatabaseReference
    
    init(){
        FIRApp.configure()
         dbRef = FIRDatabase.database().reference(fromURL: "https://classsearch-179fb.firebaseio.com/")

                
    }

    
    //this function will be called to put a new course on firebase
    func postCourse(term:String,courseID:String, name:String,descriptionURL: String, block:String, time:String,bookUrl:String ,teacherUrl:String,syllabusURL:String)->Bool{
        
        dbRef.child(term).child(courseID).updateChildValues(["NAME":name,"DESCRIPTION":descriptionURL,"BLOCK":block,"TIMES":time,"TEACHER":teacherUrl,"BOOKS":bookUrl,"SYLLABUS":syllabusURL])
        
        
        
        
        
        return false
    }
    

    func report() -> String {
        //return a general report of current status of the firebase
        //including but not limited with: last update time, number of items, number of terms .....
        
        return "Firebase not initialized yet."
    }
    
    
    
    
    
    
}
