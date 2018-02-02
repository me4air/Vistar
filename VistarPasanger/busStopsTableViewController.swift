//
//  busStopsTableViewController.swift
//  VistarPasanger
//
//  Created by Всеволод on 25.01.2018.
//  Copyright © 2018 me4air. All rights reserved.

import UIKit
import CoreData
import CoreLocation

//Основной класс

class busStopsTableViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var busSegmentedControl: UISegmentedControl!
    
    //Массив остановок для работы с БД CoreData
    var allBusStops: [BusStops] = []
    
    var searchController: UISearchController!
    var locationManager:CLLocationManager!
    var userLocation:CLLocation = CLLocation(latitude: 0.0, longitude: 0.0)
    
    //Вспомогательные массивы
    var busStops: [BusStops] = []
    var filterdResoultArray: [BusStops] = []
    var nearableBusStops: [BusStops] = []
    var favorietsBusStops: [BusStops] = []
    
    var userLon: Double = 0.0
    var userLat: Double = 0.0
    
    //IBAction реагирующий на смену SegmentedControll
    
    @IBAction func busSegmentValueChanged(_ sender: Any) {
        let value = busSegmentedControl.selectedSegmentIndex
        switch value {
        case 0:
            busStops = nearableBusStops
        case 1:
            filterByFavoriets()
            busStops = favorietsBusStops
        case 2:
            busStops = allBusStops
        default:
            break
        }
        updateSearchResults(for: searchController)
        tableView.reloadData()
    }
    // MARK: - Parsing
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
                let allbusStops = try JSONDecoder().decode(busStopsResponce.self, from: data)
                if UserDefaults.standard.integer(forKey: "BusHash") != allbusStops.hash {
                    self.deleteAllRecordsAboutBusStops()
                    UserDefaults.standard.set(allbusStops.hash, forKey: "BusHash")
                    self.reloadTableViewDataAndSaveInCoreData(allBusStops: allbusStops)
                }
            } catch {
                print(error)
            }
            }.resume()
        return
    }
    
    // MARK: - CoreData
    
    //Обновляем табличку и сохраняем данные в CoreData когда сервер нам что-то пришлет
    func reloadTableViewDataAndSaveInCoreData(allBusStops: busStopsResponce){
        DispatchQueue.main.async {
            for i in 0...allBusStops.stops!.values.count-1{
                if (Array(allBusStops.stops!.values)[i].name!.count > 0){
                    self.saveData(busStops: Array(allBusStops.stops!.values)[i])
                }
            }
            self.allBusStops = self.allBusStops.sorted(by: { (this, that) -> Bool in
                if (this.name! <= that.name!){
                    return true
                } else {
                    return false
                }
            })
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
        taskObject.name = busStops.name?.trimmingCharacters(in: .whitespaces)
        taskObject.lat = busStops.lat!
        taskObject.lon = busStops.lon!
        taskObject.isFavorite = false
    
        do {
            try context.save()
            self.allBusStops.append(taskObject)
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
        determineMyCurrentLocation()
        let fetchRequest: NSFetchRequest<BusStops> = BusStops.fetchRequest()
        do {
            allBusStops = try context.fetch(fetchRequest)
        } catch {print(error.localizedDescription)}
        allBusStops = allBusStops.sorted(by: { (this, that) -> Bool in
            if (this.name! <= that.name!){
                return true
            } else {
                return false
            }
        })
    }
    
    // Фильт для поиска
    func filterContentFor (searchText text: String){
        filterdResoultArray = busStops.filter({ (busStop) -> Bool in
            return (busStop.name?.lowercased().contains(text.lowercased()))!
        })
    }
    
    //Что делаем когда view загрузился
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
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
    
    // MARK: - iOS 11
    
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
    
    // Убираем выделение с нажатой ячейки
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Добавить в избранное по свайпу слева на право
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var title = "В избранные"
        var stopToFavorite: BusStops
        if searchController.isActive && searchController.searchBar.text != "" {
            stopToFavorite = filterdResoultArray[indexPath.row]
        } else {
            stopToFavorite = busStops[indexPath.row]
        }
        if stopToFavorite.isFavorite == true {
            title = "Убрать из избранного"
        }
        let favorite = UIContextualAction(style: .normal, title: title) { (action, view, sucsess) in
            self.favorietsAction(stopToFavorite: stopToFavorite)
        }
        
        if stopToFavorite.isFavorite == true {
            favorite.backgroundColor = #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)
        } else {
            favorite.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        }
        
        return UISwipeActionsConfiguration(actions: [favorite])
    }
    
    //добавить в избранное по свайпу справа на лево
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var title = "В избранные"
        var stopToFavorite: BusStops
        if searchController.isActive && searchController.searchBar.text != "" {
            stopToFavorite = filterdResoultArray[indexPath.row]
        } else {
            stopToFavorite = busStops[indexPath.row]
        }
        
        if stopToFavorite.isFavorite == true {
            title = "Убрать из избранного"
        }
        let favorite = UITableViewRowAction(style: .normal, title: title) { (action, indexPath) in
            self.favorietsAction(stopToFavorite: stopToFavorite)
        }
        
        if stopToFavorite.isFavorite == true {
            favorite.backgroundColor = #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)
        } else {
            favorite.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        }
        
        return [favorite]
    }
    
    // action для cellAction
    
    func favorietsAction(stopToFavorite: BusStops) {
        if stopToFavorite.isFavorite != true{
            stopToFavorite.isFavorite = true
            
        }
        else{
            stopToFavorite.isFavorite = false
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let objectToChange = stopToFavorite
        context.refresh(objectToChange, mergeChanges: true)
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
        if self.busSegmentedControl.selectedSegmentIndex == 1{
            busSegmentValueChanged((Any).self)
        }
        self.tableView.reloadData()
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
            if busStop.isFavorite {
                cell.favoriteImage.image = UIImage(named: "star")
            } else {
                cell.favoriteImage.image = nil
            }
        }
        else {
            cell.nameLabel.text=""
            cell.commentLabel.text=""
            
        }
        return cell
    }
    
    //  MARK: - Segue
    
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
    
    // MARK: - Filter
    
    func filterByFavoriets(){
        favorietsBusStops = []
        if allBusStops.count != 0 {
            for i in 0...allBusStops.count-1{
                if allBusStops[i].isFavorite {
                    favorietsBusStops.append(allBusStops[i])
                }
            }
        }
    }
    
    // MARK: - Location
    
    //настраиваем сервис получения геопозиции
    func determineMyCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    //получаем расстояние в метрах между текущим положением и локацией с координатами
    func getDistanceBetweenPoints(firstLocatin: CLLocation, secondLan: Double, secondLon: Double) -> Double{
        let coordinate2 = CLLocation(latitude: secondLan, longitude: secondLon)
        let distanceInMeters = firstLocatin.distance(from: coordinate2)
        return distanceInMeters
    }
    
    //вызывается при изменении геопозиции
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        if (userLocation.distance(from: self.userLocation)>50){
            self.userLocation = userLocation
            filterArrayByLocation(distance: 500)
            busStops=nearableBusStops
            tableView.reloadData()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
    //создаем массив билжайших остановок
    func filterArrayByLocation(distance: Double){
        if (allBusStops.count != 0){
            nearableBusStops = []
            for i in 0...allBusStops.count-1 {
                if (getDistanceBetweenPoints(firstLocatin: userLocation, secondLan: allBusStops[i].lat, secondLon: allBusStops[i].lon) <= distance){
                    nearableBusStops.append(allBusStops[i])
                }
            }
        }
    }
    
    
}

//реализуем расширение для фильтрации по строке поиска
extension busStopsTableViewController: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        filterContentFor(searchText: searchController.searchBar.text!)
        tableView.reloadData()
    }
}
