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


struct course {
    var id: String
    var name: String
    var time: String
    var block: String
    var descUrl: String
    var teacherUrl: String
    var bookUrl: String
    var syllUrl: String
    var requirements: String
    var location: String
    var open: String
    var section: String
}

class LoadingCourseInfo {
    
    var isDone = false //indicates if the update process is done or not
    
    let firedb: FirebaseUpdateService //ref of the firebase
    
    let mainVC : ViewController //ref of the ui
    
    var lock = [true,true,true] //only allows at most three connection processes running concurrently. Can increase the size for a faster speed, but possibility of getting error also increases
    
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
                self.mainVC.println(newLine: "requested term \(term) at page \(index) successful, start parsing")
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
        if let doc = Kanna.HTML(html: htmlString, encoding: String.Encoding.utf8) {
            let a = doc.xpath("//table//tr")
            print("Start parsing \(a.count-1) classes data on this page")
            for i in 1...a.count-1 {
                //PROBLEMS!
                //PROBLEMS
                firedb.postCourse(course: makeCourse(node: a[i]), term: term)
            }
        }else{
            self.mainVC.println(newLine: "parsing failed, term:\(term)")
        }
    }
    
    
    
    private func makeCourse(node: XMLElement)->course{
        let xPathNode = node.css("td")
        print(xPathNode.count)
        if xPathNode.count != 6{
            print("tds.count: \(xPathNode.count)")
            self.mainVC.println(newLine: "\nfailed to parse given xPathNode\n" )
            return course(id: "", name: "", time: "", block: "", descUrl: "", teacherUrl: "", bookUrl: "", syllUrl: "", requirements: "", location: "", open: "",section: "")
        }
    
        var courseHolder = course(id: "", name: "", time: "", block: "", descUrl: "", teacherUrl: "", bookUrl: "", syllUrl: "", requirements: "", location: "", open: "",section: "")
        
        
        
        //ID
        if let id = xPathNode[1].xpath("//a/@name")[0].text{
            courseHolder.id = id
            print(id)
        }else{
            print("id nil")
        }
        //ID
        
        //Section
        if let full_id = xPathNode[1].xpath("//a[@name='\(courseHolder.id)']")[0].text{
            print(full_id)
            let temp = full_id.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).components(separatedBy: " ")
            if temp[temp.count-1] == "1"{
                courseHolder.section = "1"
            }else{
                courseHolder.id = courseHolder.id + " " + temp[temp.count-1]
                courseHolder.section = temp[temp.count-1]
            }
            
            
            print("section: "+courseHolder.section)
        }else{
            print("section nil")
        }
        //Section
        
        
        //Description
        if let popLink = xPathNode[1].xpath("//a[@class='def']/@href")[0].text{
            print(popLink)
            let pop = popLink.components(separatedBy: "'")
            if pop.count>0{
                courseHolder.descUrl = "http://registrar-prod.unet.brandeis.edu/registrar/schedule/"+pop[1]
                print(courseHolder.descUrl)
            }else{
                print("descUrl nil, pop has zero elements")

            }
            
        }else{
            print("descUrl nil")
        }
        //Description
        
        
        //Name
        if let name = xPathNode[2].xpath("//strong")[0].text{
            courseHolder.name = name
            print(name)
        }else{
            print("name nil")
        }
        //Name
        
        
        //Requirement
        if let reqHtml = xPathNode[2].toHTML{
            if let doc = Kanna.HTML(html: reqHtml, encoding: String.Encoding.utf8) {
                let reqs = doc.xpath("//span[@class='requirement']")
                for r in reqs{
                    courseHolder.requirements = courseHolder.requirements+r.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)+" "
                }
                print("----"+courseHolder.requirements)
            }
        }
        //Requirement
        
        
        //Time //NOT DONE
        if let timeAndLoc  = xPathNode[3].text{
            courseHolder.open = timeAndLoc
            let details = cutWhiteSpace(text: timeAndLoc)
            for d in details{
                print("** \(d)")
            }
            print(details.count)
        }else{
            print("open nil")
        }
        //Time //NOT DONE
        
        
        //OPEN //NOT DONE
        
        //OPEN //NOT DONE
        
        
        //Teacher
        if let teacherHTML = xPathNode[5].toHTML{
            if let doc = Kanna.HTML(html: teacherHTML, encoding: String.Encoding.utf8) {
                let teacherURLs = doc.xpath("//@href")
                print("teacherURLs.count=\(teacherURLs.count)")
                if teacherURLs.count == 1{
                    courseHolder.teacherUrl = teacherURLs[0].text!
                }else{
                    for s in teacherURLs{
                        courseHolder.teacherUrl = s.text!+"\n"+courseHolder.teacherUrl
                    }
                }
            }
        }else{
            print("teacher nil")
        }
        //Teacher
        
        
        //Syllabus
        if let s = xPathNode[1].toHTML{
            if let syllab = Kanna.HTML(html: s, encoding: String.Encoding.utf8) {
                if syllab.xpath("//@href").count > 1{
                    if let sylla = syllab.xpath("//@href")[1].text{
                        courseHolder.syllUrl = sylla
                        print("this class has syllabus: \(sylla)")
                    }
                }else{
                    print("syllabus nil")
                }
            }
        }
        
        
        
        //Syllabus
        //http://registrar-prod.unet.brandeis.edu/registrar/schedule/course?acad_year=2017&crse_id=000050
        return courseHolder
    }
    
    private func cutWhiteSpace(text: String)->[String]{
        let a = text.components(separatedBy: "\r\n")
        var temp:[String] = []
        for s in a {
            if s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) != "" {
                temp.append(s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            }
        }
        return temp
    }
    
    func report() -> String{
        return firedb.report()
    }
    
    
    

  
    
    
    
    
}
