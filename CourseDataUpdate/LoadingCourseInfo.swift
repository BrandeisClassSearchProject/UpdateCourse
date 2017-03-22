//
//  LoadingCourseInfo.swift
//  CourseDataUpdate
//
//  Created by Yuanze Hu on 3/20/17.
//  Copyright © 2017 Yuanze Hu. All rights reserved.
//  example link: http://registrar-prod.unet.brandeis.edu/registrar/schedule/search?strm=1171&view=all&status=&time=time&day=mon&day=tues&day=wed&day=thurs&day=fri&start_time=07%3A00%3A00&end_time=22%3A30%3A00&block=&keywords=&order=class&search=Search&subsequent=1&page=1

import Foundation
import Alamofire
import Kanna


class LoadingCourseInfo {
    
    var isDone = false //indicates if the update process is done or not
    
    let firedb: FirebaseUpdateService //ref of the firebase
    
    let mainVC : ViewController //ref of the ui
    
    var lock = [true,true,true]
    
    init(vc: ViewController){
        mainVC = vc
        firedb = FirebaseUpdateService()
    }
    
    
    //start working
    func start() {
        let queue = DispatchQueue(label: "download")
        queue.async {
            if self.firedb.lock(){
                print("xxxx")
                self.mainVC.println(newLine:"Lock the database from others, start updating")
                print("Lock the database from others, start updating")
                self.doUpdate(terms: self.generateTerms())
            }else{
                print("The database is locked probably because others might be updating this database right now, try later")
                self.mainVC.println(newLine:"The database is locked probably because others might be updating this database right now, try later")
            }
        }
    }
    
    private func generateTerms() -> [Int]{
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yy"
        let result = formatter.string(from: date)
        formatter.dateFormat = "MM"
        let m = Int(formatter.string(from: date))
        var y = Int(result)
        var a:[Int] = []
       if m! >= 3 && m! < 10{
            a.append(1000+y!*10+1)
            a.append(1000+y!*10+2)
            a.append(1000+y!*10+3)
            y = y! - 1
        }else if m! >= 10{
            a.append(1000+(1+y!)*10+1)
        }
        for i in 0...2 {
            a.append(1000+(y!-i)*10+1)
            a.append(1000+(y!-i)*10+2)
            a.append(1000+(y!-i)*10+3)
        }
        print(a)
        return a
    }
    
    //this func should be fed with something like [1171,1172,1173,1161,1162,1163.....]
    private func doUpdate(terms:[Int]){
        for term in terms{
            self.mainVC.println(newLine:"Try to update \(convertTermToString(term: term))")
            for i in 1...20{
                if(lock[i%3]){
                    lock[i%3] = false
                }else{
                    while !lock[i%3]{}
                }
                doFetch(urlString: "http://registrar-prod.unet.brandeis.edu/registrar/schedule/search?strm=\(String(term))&view=all&status=&time=time&day=mon&day=tues&day=wed&day=thurs&day=fri&start_time=07%3A00%3A00&end_time=22%3A30%3A00&block=&keywords=&order=class&search=Search&subsequent=1&page=\(String(i))", term: String(term),index:i)
                
            }
        }
        isDone = true
        self.mainVC.println(newLine:"Update completed!")
        self.mainVC.stopAnimation()
    }
    
    private func convertTermToString(term:Int) -> String{
        var year = "20"+String((term-1000)/10)
        switch term%10 {
        case 1:
            year = year + " Spring"
            break
        case 2:
            year = year + " Summer"
            break
        case 3:
            year = year + " Fall"
            break
        default:
            print("WTF")
        }
        return year
    }
    
    private func doFetch(urlString: String, term:String,index: Int) {
        
        Alamofire.request(urlString).responseString(completionHandler: {
            response in
            print("is Successful?? \(response.result.isSuccess)")
            if let html = response.result.value {
                self.mainVC.println(newLine: "requested \(urlString) successfully, start parsing")
                self.parsing(htmlString: html, term: term)
                self.lock[index%3] = true //release the resource
            }else{
                self.mainVC.println(newLine:"url not working, url: \(urlString)")
                self.lock[index%3] = true //release the resource
            }
        })
        
        
        
    }
    
    private func parsing(htmlString:String, term:String){
        self.mainVC.println(newLine: "working on term \(term)")
        self.mainVC.println(newLine: "doing nothing for now")
    }
    
    
    
    
    func report() -> String{
        return firedb.report()
    }
    
    
    

  
    
    
    
    
}
