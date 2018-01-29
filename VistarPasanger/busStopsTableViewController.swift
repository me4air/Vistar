//
//  busStopsTableViewController.swift
//  VistarPasanger
//
//  Created by Всеволод on 25.01.2018.
//  Copyright © 2018 me4air. All rights reserved.
//

import UIKit
import CoreData


//Реализуем 2 Decodable структуры, чтобы swift сам распарсил из JSON

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
    
    //Массив остановок для работы с БД CoreData
    var busStops: [BusStops] = []
    
    //Функция получения данных о остановках с сервера
    func getBusStopsDataFromServer() {
        
        //Готовим параметры
        guard let url = URL(string: "http://passenger.vistar.su/VPArrivalServer/stoplist") else {return}
        let parameters = ["regionId":"36"]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {return}
        request.httpBody = httpBody
        //Начинаем сесисю пробуем получить и распарсить данные
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, erroe) in
            if let response = response {
               print(response)
            }
            guard let data = data else {return}
            
            do{
                let busStops = try JSONDecoder().decode(busStopsResponce.self, from: data)
                if UserDefaults.standard.integer(forKey: "BusHash") != busStops.hash {
                    self.deleteAllRecordsAboutBusStops()
                    UserDefaults.standard.set(busStops.hash, forKey: "BusHash")
                    self.reloadTableViewDataAndSaveInCoreData(allBusStops: busStops)
                }
            } catch {
                print(error)
            }
            }.resume()
        return
    }
    
    //Обновляем табличку и сохраняем данные в CoreData когда сервер нам что-то пришлет
        func reloadTableViewDataAndSaveInCoreData(allBusStops: busStopsResponce){
        DispatchQueue.main.async {
            for i in 0...allBusStops.stops!.values.count-1{
                self.saveData(busStops: Array(allBusStops.stops!.values)[i])
            }
            self.tableView.reloadData()
        }
        
    }
  
    //Сохранение данных в CoreData
    func saveData(busStops: BusStop){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "BusStops", in: context)
        let taskObject = NSManagedObject(entity: entity!, insertInto: context) as! BusStops
        taskObject.comment = busStops.comment
        taskObject.id = Double(busStops.id!)
        taskObject.name = busStops.name
        taskObject.lat = busStops.lat!
        taskObject.lon = busStops.lon!
        
        do {
            try context.save()
            self.busStops.append(taskObject)
        }
        catch {
            print(error.localizedDescription)
        } 
        
    }
    
    //Очищаем БД. Функция нужна на тот случай если с сервера пришли данные отличные от БД
    func deleteAllRecordsAboutBusStops(){
         DispatchQueue.main.async {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BusStops")
        fetchRequest.includesPropertyValues = false
        do {
            let items = try context.fetch(fetchRequest) as! [NSManagedObject]
            
            for item in items {
                context.delete(item)
            }
            try context.save()
            
        } catch {
            print ("There was an error")
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<BusStops> = BusStops.fetchRequest()
        
        do {
            busStops = try context.fetch(fetchRequest)
        } catch {print(error.localizedDescription)}
        print(busStops.count)
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
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if busStops.count != 0 {
            return (busStops.count)
        }
        else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! BusStopTableViewCell
        if busStops.count != 0 {
            cell.nameLabel.text=busStops[indexPath.row].name!
            if let comment = busStops[indexPath.row].comment{
                cell.commentLabel.text=comment
            } else{
                cell.commentLabel.text=""
            }
        }
        else {
            cell.nameLabel.text=""
            cell.commentLabel.text=""
            
        }
        return cell
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if segue.identifier == "detailBusStopSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let dvc = segue.destination  as! DetailBusViewController
                if let name = busStops[indexPath.row].name {
                    dvc.busStopName = name
                }
                if let comment = busStops[indexPath.row].comment {
                    dvc.busStopComment = comment
                }    
            }
        }
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
