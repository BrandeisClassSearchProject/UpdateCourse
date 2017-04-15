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
        //
        
        if term == "" || course.id == "" {
            print("skip")
            return
        }
        
        self.postCourse(term: term, courseID: course.id, name: course.name, descriptionURL: course.descUrl, block: course.block, time: course.time, bookUrl: course.bookUrl, teacherUrl: course.teacherUrl, syllabusURL: course.syllUrl, open: course.open, req: course.requirements, loc: course.location, sec: course.section, code: course.code)
        print("\n\nUPDATE COURSE=>\nCODE: \(course.code)\nTerm: \(term)\nID: \(course.id)\nName: \(course.name)\nDesc: \(course.descUrl)\nREQ: \(course.requirements)\nTeacher: \(course.teacherUrl)\nSyllabus: \(course.syllUrl)\n")
        for t in course.time{
            print("Time: \(t)\n")
        }
    }
    
    //this function will be called to put a new course on firebase
    private func postCourse(term:String,courseID:String, name:String,descriptionURL: String, block:String, time:[String],bookUrl:String ,teacherUrl:String,syllabusURL:String,open:String,req:String,loc:String, sec:String, code:String){
        if term == "" || courseID == "" {
            return
        }
        
        dbRef.child(term).child(courseID).updateChildValues(["NAME":name,"DESCRIPTION":descriptionURL,"BLOCK":block,"TIMES":"","TEACHER":teacherUrl,"SYLLABUS":syllabusURL,"REQ":req,"OPEN":open,"LOCATION":loc,"SECTION":sec,"CODE":code])
        
        var i = 1
        for t in time{
            if t != ""{
                dbRef.child(term).child(courseID).child("TIMES").updateChildValues(["\(i)":t])
                i += 1
            }
        }
        
        
        
        
    
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
