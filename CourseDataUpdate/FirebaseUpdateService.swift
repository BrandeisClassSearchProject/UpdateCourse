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

    func postCourse(course: course, term:String){
        //self.postCourse(term: term, courseID: course.id, name: course.name, descriptionURL: course.descUrl, block: course.block, time: course.time, bookUrl: course.bookUrl, teacherUrl: course.teacherUrl, syllabusURL: course.syllUrl, open: course.open, req: course.requirements)
        
        if term == "" || course.id == "" {
            print("skip")
            return
        }
        print("Term: \(term)\nID: \(course.id)\nName: \(course.name)\nDesc: \(course.descUrl)\nREQ: \(course.requirements)\nTeacher: \(course.teacherUrl)\nSyllabus: \(course.syllUrl)")
        
        
    }
    
    //this function will be called to put a new course on firebase
    func postCourse(term:String,courseID:String, name:String,descriptionURL: String, block:String, time:String,bookUrl:String ,teacherUrl:String,syllabusURL:String,open:String,req:String){
        if term == "" || courseID == "" {
            return
        }
        dbRef.child(term).child(courseID).updateChildValues(["NAME":name,"DESCRIPTION":descriptionURL,"BLOCK":block,"TIMES":time,"TEACHER":teacherUrl,"SYLLABUS":syllabusURL,"REQ":req,"OPEN":open])
        
        
        
        
        
    
    }
    
    //grab a lock of database, prevent updating the same time
    //return the result 
    //if true, continue, if false stop the process
    func lock() -> Bool{
        
        //not implemented for now, just return true
        return true
    }
    

    func report() -> String {
        //return a general report of current status of the firebase
        //including but not limited with: last update time, number of items, number of terms .....
        
        return "Firebase not initialized yet."
    }
    
    
    
    
    
    
}
