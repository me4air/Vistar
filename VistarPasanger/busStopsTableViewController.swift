//
//  busStopsTableViewController.swift
//  VistarPasanger
//
//  Created by Всеволод on 25.01.2018.
//  Copyright © 2018 me4air. All rights reserved.
//

import UIKit

struct busStopsResponce: Decodable {
    var status: String?
    var hash: Int?
    var stops: Dictionary<String, BusStop>?
}

struct BusStop: Decodable {
    var comment: String?
    var id: Int?
    var lat: Double?
    var lon: Double?
    var name: String?
}

class busStopsTableViewController: UITableViewController {
    
    var allBusStops =  busStopsResponce()
    
    func getBusStopsDataFromServer() {
        guard let url = URL(string: "http://passenger.vistar.su/VPArrivalServer/stoplist") else {return}
        let parameters = ["regionId":"36"]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {return}
        request.httpBody = httpBody
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, erroe) in
            /*if let response = response {
               print(response)
            }*/
            
            guard let data = data else {return}
            do{
                let busStops = try JSONDecoder().decode(busStopsResponce.self, from: data)
                self.allBusStops = busStops
                self.reloadTableViewData()
            } catch {
                print(error)
            }
            }.resume()
        return
    }
    
    func reloadTableViewData(){
        DispatchQueue.main.async {
           self.tableView.reloadData()
        }
        
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        getBusStopsDataFromServer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if allBusStops.stops?.count != nil {
            return (allBusStops.stops?.count)!}
        else {return 1}
    }
    
     // MARK: - Networking
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if allBusStops.stops?.count != nil {
            var stopsArray = Array(self.allBusStops.stops!)
            cell.textLabel?.text=stopsArray[indexPath.row].value.name!
            if let comment = stopsArray[indexPath.row].value.comment{
                cell.detailTextLabel?.text=comment
            } else{
                cell.detailTextLabel?.text=""}
            print((self.allBusStops.stops?.count)!)
            print(stopsArray[1].value.name!)
        }
        else {
            cell.textLabel?.text=""
            
        }
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
