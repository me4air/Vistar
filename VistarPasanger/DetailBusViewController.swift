//
//  DetailBusViewController.swift
//  VistarPasanger
//
//  Created by Всеволод on 26.01.2018.
//  Copyright © 2018 me4air. All rights reserved.
//

import UIKit
import CoreData

struct Responce: Decodable {
    var busArrival: [BusAririvals]?
    var status: String
}

struct BusAririvals: Decodable {
    var arrivals: [Arrivals]?
    var fromStopId: Int?
    var toStopId: Int?
}

struct Arrivals: Decodable, Equatable {
    static func ==(lhs: Arrivals, rhs: Arrivals) -> Bool {
        if ((lhs.arrivalTime == rhs.arrivalTime) && (lhs.busRoute == rhs.busRoute)) {
            return true
        }
        else {return false}
    }
    
    var arrivalTime: Int?
    var busRoute: String?
    var lat: Double?
    var lon: Double?
    var rideTime: Int?
}

struct ArivalsToDislplayData {
    var busName: String?
    var arivalTimes: [Int]?
}

class DetailBusViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var noInformationLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var busStopNameLabel: UILabel!
    @IBOutlet weak var busStopCommentLabe: UILabel!
    
    
    var busStopName = ""
    var busStopComment = ""
    var bustStopStartPoint = ""
    var busStopList: [String] = []
    var arivalsData: [Arrivals] = []
    var displayArivalsData: [ArivalsToDislplayData] = []
    
    override func viewWillAppear(_ animated: Bool) {
        getBusStopList()
        getBusArraivalTime()
        tableView.isHidden = true
        noInformationLabel.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        busStopNameLabel.adjustsFontSizeToFitWidth = true
        busStopNameLabel.minimumScaleFactor = 0.2
        busStopNameLabel.text = busStopName
        busStopCommentLabe.text = busStopComment
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Do any additional setup after loading the view.
    }
    
    func getBusStopList(){
        var busStops: [BusStops] = []
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<BusStops> = BusStops.fetchRequest()
        
        do {
            busStops = try context.fetch(fetchRequest)
            for i in 0...busStops.count-1{
                busStopList.append(String(Int(busStops[i].id)))
            }
        } catch {print(error.localizedDescription)}
    }
    
    func getBusArraivalTime(){
        guard let url = URL(string: "http://passenger.vistar.su/VPArrivalServer/arrivaltimeslist") else {return}
        let parameters = ["regionId":"36" , "fromStopId": [bustStopStartPoint] , "toStopId": busStopList] as [String : Any]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {return}
        request.httpBody = httpBody
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, erroe) in
            DispatchQueue.main.async {
            if let response = response {
                 print(response)
            }
            guard let data = data else {return}
            do{
                let busArivals = try JSONDecoder().decode(Responce.self, from: data)
                self.reloadTableViewData()
                self.filterBusStopsArrival(response: busArivals)
            } catch {
                print(error)
                }
                
            }
            }.resume()
    }
    
    func filterBusStopsArrival(response: Responce){
        if let arrivalCounts =  response.busArrival?.count{
            for i in 0...arrivalCounts-1{
                if let arrival = response.busArrival![i].arrivals {
                    for i in 0...arrival.count-1{
                       let newArrival: Arrivals = Arrivals(arrivalTime: arrival[i].arrivalTime!, busRoute: arrival[i].busRoute!, lat: arrival[i].lat!, lon:  arrival[i].lon!, rideTime: arrival[i].rideTime!)
                        arivalsData.append(newArrival)
                        
                    }
                }
            }
            self.arivalsData = arivalsData.removeDuplicates()
        }
        
    }
    
    func reorganizeDataForDisplay(){
        if arivalsData.count != 0 {
            displayArivalsData.append(ArivalsToDislplayData(busName: arivalsData[0].busRoute, arivalTimes: []))
            for i in 0...arivalsData.count-1{
                if !(isInArray(displayArivals: displayArivalsData, busName: arivalsData[i].busRoute!)){
                    displayArivalsData.append(ArivalsToDislplayData(busName: arivalsData[i].busRoute, arivalTimes: []))
                }
            }
            for i in 0...displayArivalsData.count-1{
                for j in 0...arivalsData.count-1{
                    if displayArivalsData[i].busName == arivalsData[j].busRoute{
                        displayArivalsData[i].arivalTimes?.append(arivalsData[j].arrivalTime!)
                    }
                }
            }
        }
        
    }
    
    func isInArray(displayArivals: [ArivalsToDislplayData], busName: String) -> Bool{
        var answer = false
        if displayArivals.count > 0 {
            for i in 0...displayArivals.count-1{
                if displayArivals[i].busName == busName{
                    answer = true
                }
            }
        }
        return answer
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - TABLE VIEW
    
    func reloadTableViewData(){
        DispatchQueue.main.async {
            if self.arivalsData.count != 0 {
                self.tableView.isHidden = false}
            else {
                self.noInformationLabel.isHidden = false
            }
            self.reorganizeDataForDisplay()
            print(self.displayArivalsData)
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
        }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if displayArivalsData.count != 0 {
            return (displayArivalsData.count)
        } else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! busArrivalTableViewCell
        var aditionalTimes = " "
        if displayArivalsData.count != 0{
        if displayArivalsData[indexPath.row].arivalTimes!.count >= 2 {
            aditionalTimes = ""
            for i in 1...displayArivalsData[indexPath.row].arivalTimes!.count-1{
                aditionalTimes = aditionalTimes + String(displayArivalsData[indexPath.row].arivalTimes![i]/60) + " Мин. \n"
            }}
            print(displayArivalsData.count)
            cell.arivalTime.text = String(describing: displayArivalsData[indexPath.row].arivalTimes![0]/60) + " Мин."
            cell.busName.text = String(describing: displayArivalsData[indexPath.row].busName!)
            cell.aditionalrivalTime.text = aditionalTimes
        } else{
            cell.arivalTime.text = ""
            cell.busName.text = ""
        }
       
        return cell
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        
        return result
    }
}
