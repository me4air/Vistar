//
//  busStopsTableViewController.swift
//  VistarPasanger
//
//  Created by Всеволод on 25.01.2018.
//  Copyright © 2018 me4air. All rights reserved.

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


class busStopsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var busSegmentedControl: UISegmentedControl!
    
    //Массив остановок для работы с БД CoreData
    var busStops: [BusStops] = []
    var searchController: UISearchController!
    var filterdResoultArray: [BusStops] = []
    var nearableBusStops: [BusStops] = []
    
    
    
    @IBAction func busSegmentValueChanged(_ sender: Any) {
        let value = busSegmentedControl.selectedSegmentIndex
        switch value {
        case 0:
            print(0)
        case 1:
            print(1)
        case 2:
            print(2)
        default:
            break
        }
    }
    
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
                print (error.localizedDescription)
            }
        }
    }
    
    // Подгружаем таблицу и данные из БД
    override func viewWillAppear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<BusStops> = BusStops.fetchRequest()
        do {
            busStops = try context.fetch(fetchRequest)
        } catch {print(error.localizedDescription)}
    }
    
    func filterContentFor (searchText text: String){
        filterdResoultArray = busStops.filter({ (busStop) -> Bool in
            return (busStop.name?.lowercased().contains(text.lowercased()))!
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 85
        tableView.rowHeight = UITableViewAutomaticDimension
        setupNavigationBar()
        definesPresentationContext = true
        getBusStopsDataFromServer()
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: iOS 11
    
    func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // Считаем количество ячеек в таблице
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if busStops.count != 0 {
            if searchController.isActive && searchController.searchBar.text != ""{
                return filterdResoultArray.count
            } else {
                return (busStops.count)
            }
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Получаем Cell для оборажения из поиска
    
    func busStopToDisplayAT(indexPath: IndexPath) -> BusStops {
        let busStop: BusStops
        if searchController.isActive && searchController.searchBar.text != "" {
            busStop = filterdResoultArray[indexPath.row]
        }
        else {
            busStop = busStops[indexPath.row]
        }
        return busStop
    }
    
    // Настраиваем кажду новую переиспользуемую cell
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! BusStopTableViewCell
        if busStops.count != 0 {
            let busStop = busStopToDisplayAT(indexPath: indexPath)
            cell.nameLabel.text=busStop.name!
            if let comment = busStop.comment{
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
    
    
    
    // Готовимся к переходу по detailBusStopSegue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailBusStopSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let dvc = segue.destination  as! DetailBusViewController
                
                if let name = busStopToDisplayAT(indexPath: indexPath).name {
                    dvc.busStopName = name
                }
                if let comment = busStopToDisplayAT(indexPath: indexPath).comment {
                    dvc.busStopComment = comment
                }
                let busStart = String(Int(busStopToDisplayAT(indexPath: indexPath).id))
                dvc.bustStopStartPoint = busStart
                
            }
        }
    }
    
    
    
}

extension busStopsTableViewController: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        filterContentFor(searchText: searchController.searchBar.text!)
        tableView.reloadData()
    }
}
