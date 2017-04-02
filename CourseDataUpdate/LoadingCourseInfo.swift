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
    var time: [String]
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
    
    var lock = [true] //only allows at most three connection processes running concurrently. Can increase the size for a faster speed, but possibility of getting error also increases
    
    var numberOfTerms = 0
    
    var currentDone = 0
    
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
        numberOfTerms = a.count * 20
        return a
    }
    
    //this func should be fed with something like [1171,1172,1173,1161,1162,1163.....]
    private func doUpdate(terms:[Int]){
        
        for term in terms{
            self.mainVC.println(newLine:"Updating \(convertTermToString(term: term))")
            for i in 1...20{
                if(lock[i%lock.count]){
                    lock[i%lock.count] = false
                }else{
                    while !lock[i%lock.count]{}
                    self.mainVC.println(newLine: "\(currentDone) out of \(numberOfTerms), \(Double(currentDone/numberOfTerms))% Finished" )
                }
                doFetch(urlString: "http://registrar-prod.unet.brandeis.edu/registrar/schedule/search?strm=\(String(term))&view=all&status=&time=time&day=mon&day=tues&day=wed&day=thurs&day=fri&start_time=07%3A00%3A00&end_time=22%3A30%3A00&block=&keywords=&order=class&search=Search&subsequent=1&page=\(String(i))", term: String(term),index:i)
                
            }
            self.mainVC.println(newLine: "\(Double(currentDone/numberOfTerms))% Finished" )
        }
        isDone = true
        //self.mainVC.println(newLine:"Update completed!")
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
                self.lock[index%(self.lock.count)] = true //release the resource
                
            }else{
                self.mainVC.println(newLine:"url not working, url: \(urlString)")
                self.lock[index%(self.lock.count)] = true //release the resource
            }
        })
        
        
        
    }
    
    private func parsing(htmlString:String, term:String){
        self.mainVC.println(newLine: "working on term \(term)")
        if let doc = Kanna.HTML(html: htmlString, encoding: String.Encoding.utf8) {
            let a = doc.xpath("//table//tr")
            print("Start parsing \(a.count-1) classes data on this page")
            if a.count-1 > 1{
                for i in 1...a.count-1 {
                    firedb.postCourse(course: makeCourse(node: a[i]), term: term)
                    
                }
            }
            
            currentDone += 1
        }else{
            self.mainVC.println(newLine: "parsing failed, term:\(term)")
        }
    }
    
    
    
    private func makeCourse(node: XMLElement)->course{
        let xPathNode = node.css("td")
        print(xPathNode.count)
        if xPathNode.count != 6{
            print("tds.count: \(xPathNode.count)")
            //self.mainVC.println(newLine: "\nfailed to parse given xPathNode\n" )
            return course(id: "", name: "", time: [], block: "", descUrl: "", teacherUrl: "", bookUrl: "", syllUrl: "", requirements: "", location: "", open: "",section: "")
        }
    
        var courseHolder = course(id: "", name: "", time: [], block: "", descUrl: "", teacherUrl: "", bookUrl: "", syllUrl: "", requirements: "", location: "", open: "",section: "")
        
        
        
        //ID, Section, Description
        if let idDoc = Kanna.HTML(html: xPathNode[1].toHTML!, encoding: String.Encoding.utf8) {
            //print(idDoc.toHTML!)
            if let idWithSection = idDoc.xpath("//a[@class='def']")[0].text{
                let temp = idWithSection.components(separatedBy: " ")
                var id = ""
                var section = ""
                var counter = 0
                for s in temp{
                    if s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) != ""{
                        if counter < 2{
                            id = id + s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) + " "
                        }else if counter == 2{
                            section = s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            
                        }
                        counter += 1
                    }
                }
                courseHolder.id = id.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if section == "1"{
                    courseHolder.section = "1"
                }else{
                    courseHolder.id = courseHolder.id + " " + section
                    courseHolder.section = section
                }
                print(courseHolder.id)
                print(courseHolder.section)
            }else{
                print("id nil")
            }
            if let popLink = idDoc.xpath("//a[@class='def']/@href")[0].text{
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
            
        
        }
        
        //ID, Section, Description
        
        
        //Name
        if let nameDoc = Kanna.HTML(html: xPathNode[2].toHTML!, encoding: String.Encoding.utf8) {
            if let name = nameDoc.xpath("//strong")[0].text{
                courseHolder.name = name
                print(name)
            }else{
                print("name nil")
            }
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
        var tempBlock = ""
        if let timeAndLoc  = xPathNode[3].text{
            //courseHolder.open = timeAndLoc
            print("timeAndLoc has 3")
            let details = cutWhiteSpace(text: timeAndLoc)
            if details.count == 3{
                let tempT = details[1].components(separatedBy: "–")
                if tempT.count != 2{
                    print(details[1]+" WTF!? \(tempT.count)")
                }else{
                    courseHolder.time.append("LECTURE\n\(details[0]+"  "+tempT[0]+" – "+tempT[1])")
                    courseHolder.location = details[2]
                }
                print(courseHolder.time)
                
            }else if details.count == 4{
                print("timeAndLoc has 4")
                if details[0].hasPrefix("Block"){
                    tempBlock = details[0]
                    let tempT = details[2].components(separatedBy: "–")
                    if tempT.count != 2{
                        print(details[2]+" WTF!?\(tempT.count)")
                    }else{
                        courseHolder.time.append("LECTURE\n\(details[1]+"  "+tempT[0]+" – "+tempT[1])")
                        courseHolder.location = details[3]
                    }
                }
            }else if details.count > 4{
                print("timeAndLoc has more than 4")
                var tempTime = ""
                if !details[0].hasSuffix(":"){
                    tempTime = "LECTURE\n"
                }
                for de in details{
                    let d = de.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    if d.hasPrefix("Block"){
                        if tempBlock == ""{
                            tempBlock = d
                        }else{
                            tempBlock.append("\n\(d)")
                        }
                    }else if d.hasSuffix(":"){
                        if tempTime != "" || tempTime != "LECTURE\n"{
                            courseHolder.time.append(tempTime)
                        }
                        tempTime = ""
                        tempTime.append(cutTail(input: d).uppercased()+"\n")
                    }else if isDay(str: d){
                        tempTime.append(d + "  ")
                    }else if isTime(str: d){
                        //print("find a time string ")
                        let tT = d.components(separatedBy: "–")
                        if tT.count != 2 {
                            print("\(d) WTF?! ")
                            if courseHolder.location == ""{
                                courseHolder.location = d
                            }else{
                                courseHolder.location.append("\n\(d)")
                            }
                        }else{
                            tempTime.append(tT[0]+" – "+tT[1])
                        }
                    }else{
                        if courseHolder.location == ""{
                            courseHolder.location = d
                        }else{
                            courseHolder.location.append("\n\(d)")
                        }
                    }
                    
                    print("** \(d)")
                }
                if tempTime != ""{
                    courseHolder.time.append(tempTime)
                }
            }
            
            courseHolder.block = tempBlock
            for ttt in courseHolder.time{
                print("time## \(ttt)")
            }
            print("====")
            print("Block: "+courseHolder.block)
            print("LOCATION\(courseHolder.location)")
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
    
    private func isDay(str: String)-> Bool{
        return str.characters.count == 1 || str.contains(",")
    }
    
    private func isTime(str: String)-> Bool{
        return (str.contains("AM") && str.contains("–"))||(str.contains("PM") && str.contains("–"))
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
    
    private func cutTail(input:String) -> String {
        return input.substring(to: input.index(input.startIndex, offsetBy: (input.characters.count-1)))
    }
    

  
    
    
    
    
}
