//
//  DetailBusViewController.swift
//  VistarPasanger
//
//  Created by Всеволод on 26.01.2018.
//  Copyright © 2018 me4air. All rights reserved.
//

import UIKit
import CoreData
import MapKit


class DetailBusViewController: UIViewController, UITableViewDelegate, MKMapViewDelegate, UITableViewDataSource {
    
    // MARK: -  Outlets
    //Аутлеты для работы с представлением
    @IBOutlet weak var mapHeight: NSLayoutConstraint!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noInformationLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var busStopNameLabel: UILabel!
    @IBOutlet weak var busStopCommentLabe: UILabel!
    @IBOutlet weak var downButton: UIButton!
    
    //Action отвественный за изменение размера карты
    var isMapSmall = true
    var mapSavedSize = 0.0
    @IBAction func downButtonPresed(_ sender: Any) {
        if isMapSmall {
            mapSavedSize = Double(mapHeight.constant)
            mapHeight.constant = self.view.frame.height-280
            downButton.setImage( UIImage.init(named: "upButton"), for: .normal)
            isMapSmall = false
        }
        else {
            mapHeight.constant = CGFloat(mapSavedSize)
            downButton.setImage( UIImage.init(named: "downButton"), for: .normal)
            isMapSmall = true
        }
        UIView.animate(withDuration: 0.3){
            self.view.layoutIfNeeded()
        }
        
    }
    
    // MARK: - VAR
    // Переменные
    var timer: Timer?
    var busStopName = ""
    var busStopComment = ""
    var bustStopStartPoint = ""
    var busStopCoordinates: [Double] = []
    var busStopList: [String] = []
    var arivalsData: [Arrivals] = []
    var displayArivalsData: [ArivalsToDislplayData] = []
    let mapAnnotation = MKPointAnnotation()
    
    //MARK: -  View live cyle
    //Подгатавливаемся к появлению представления
    override func viewWillAppear(_ animated: Bool) {
        mapAnnotation.title = busStopName
        mapAnnotation.subtitle = busStopComment
        mapAnnotation.coordinate = CLLocationCoordinate2D(latitude: busStopCoordinates[0], longitude: busStopCoordinates[1])
        getBusStopList()
        getBusArraivalTime()
        tableView.isHidden = true
        noInformationLabel.isHidden = true
        startTimer()
    }
    //Настраиваем представление после загрузки
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
        mapView.delegate = self
        mapView.addAnnotation(mapAnnotation)
        mapView.camera.centerCoordinate.latitude = busStopCoordinates[0]
        mapView.camera.centerCoordinate.longitude = busStopCoordinates[1]
        mapView.camera.altitude = 800
        mapView.camera.pitch = 50
        downButton.alpha = 0.6
        // Do any additional setup after loading the view.
    }
    //избавляемся от лишнего при попытке закрыть представление
    override func viewWillDisappear(_ animated: Bool) {
        displayArivalsData = []
        arivalsData = []
        self.mapView.annotations.forEach {
            if ($0 is BusPointAnnotation) {
                self.mapView.removeAnnotation($0)
            }
        }
        stopTimer()
    }
    
    // MARK: - Timer
    //запускаем таймер автообновления
    func startTimer() {
        
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(self.loop), userInfo: nil, repeats: true)
        }
    }
    //останавливаем таймер автообновления
    func stopTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    //Loop-функция которая крутится в таймере
    @objc func loop() {
        self.mapView.annotations.forEach {
            if ($0 is BusPointAnnotation) {
                self.mapView.view(for: $0)?.fadeOut()
            }
        }
        let when = DispatchTime.now() + 0.5
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.mapView.annotations.forEach {
                if ($0 is BusPointAnnotation) {
                    self.mapView.removeAnnotation($0)
                }
            }
            self.arivalsData = []
            self.displayArivalsData = []
            self.getBusArraivalTime()
            self.reloadMapViewWithBuses()
        }
    }
    
    // MARK: - Geting Data
    //Получаем список всех остановок
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
    //Получаем с сервера данные о прибытии автобусов на выбранную остановку
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
    
    //Фильтруем данные и удаляем дубликаты
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
    
    //Реорганизовываем данные для отображения в таблице
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
    
    //Проверяем есть ли уже такой маршрут в данных для отображения
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
    
    //Служебная фкнкция
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //Ассинхронно перегружаем таблицу и карту когда получили данные
    func reloadTableViewData(){
        DispatchQueue.main.async {
            if self.arivalsData.count != 0 {
                self.tableView.isHidden = false}
            else {
                self.noInformationLabel.isHidden = false
            }
            self.reorganizeDataForDisplay()
            self.reloadMapViewWithBuses()
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
        }
    }
    
    
    // MARK: - MapView
    
    //Перегружаем карту с новыми аннотациями
    func reloadMapViewWithBuses(){
        if self.arivalsData.count != 0 {
            for i in 0...self.arivalsData.count-1{
                let busAnotation = BusPointAnnotation()
                busAnotation.coordinate.latitude = self.arivalsData[i].lat!
                busAnotation.coordinate.longitude = self.arivalsData[i].lon!
                busAnotation.title = self.arivalsData[i].busRoute
                self.mapView.addAnnotation(busAnotation)
            }
        }
    }
    
    //Анимируем появление аннотаций
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        views.forEach { (view) in
            view.alpha = 0.0
            view.fadeIn()
        }
    }
    
    //Настраиваем кастомные маркеры с подписями для пользователя, остановок и автобусов
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKAnnotationView(annotation: self.mapAnnotation, reuseIdentifier: "busStop")
        if (annotation is BusPointAnnotation) {
            annotationView.image = UIImage(named: "ridingbusIcon")
        }
        else {
            if !annotation.isKind(of: MKUserLocation.self) {annotationView.image = UIImage(named: "busStopIcon")
            } else{
                annotationView.image = UIImage(named: "personIcon")
            }
            
        }
        annotationView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let label = UILabel(frame: CGRect(x: 0, y: 60, width: 200, height: 50))
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 30)
        label.textColor = #colorLiteral(red: 0.1712999683, green: 0.1712999683, blue: 0.1712999683, alpha: 1)
        if !annotation.isKind(of: MKUserLocation.self) {
            label.text = annotation.title!
        } else{
            label.text = "Вы здесь"   
        }
        label.sizeToFit()
        label.center = CGPoint(x: label.center.x-label.frame.width/2+annotationView.frame.width, y: 80)
        annotationView.layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        annotationView.layer.shadowRadius = 2
        annotationView.layer.shadowOpacity = 0.5
        annotationView.layer.shadowOffset = CGSize(width: 0, height: 2)
        if (annotation is BusPointAnnotation) {
            annotationView.layer.shadowPath = UIBezierPath(ovalIn: annotationView.bounds).cgPath
        }
        else {
            if !annotation.isKind(of: MKUserLocation.self) {
                annotationView.layer.shadowPath = UIBezierPath(rect: annotationView.bounds).cgPath
            } else{
                annotationView.layer.shadowPath = UIBezierPath(ovalIn: annotationView.bounds).cgPath
            }
            
        }
        annotationView.addSubview(label)
        return annotationView
    }
    
    // MARK: - TABLE VIEW
    
    //получаем количество секций
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //получаем количество строк
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if displayArivalsData.count != 0 {
            return (displayArivalsData.count)
        } else{
            return 0
        }
    }
    
    //Снимаем выделение
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //получаем конкрутную cell и заносим в нее данные
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! busArrivalTableViewCell
        var aditionalTimes = " "
        if displayArivalsData.count != 0{
            if displayArivalsData[indexPath.row].arivalTimes!.count >= 2 {
                aditionalTimes = ""
                for i in 1...displayArivalsData[indexPath.row].arivalTimes!.count-1{
                    aditionalTimes = aditionalTimes + String(displayArivalsData[indexPath.row].arivalTimes![i]/60) + " Мин. \n"
                }}
            cell.arivalTime.text = String(describing: displayArivalsData[indexPath.row].arivalTimes![0]/60) + " Мин."
            cell.busName.text = String(describing: displayArivalsData[indexPath.row].busName!)
            cell.aditionalrivalTime.text = aditionalTimes
        } else{
            cell.arivalTime.text = ""
            cell.busName.text = ""
        }
        
        return cell
    }
    
    
}

// MARK: -  Extensions

//Расширяем стандартный массив, чтобы он умел удалять из себя дубликаты
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

//Расширяем UIView, чтобы мы могли анимировать появление элементов по alpha

public extension UIView {
    
    func fadeIn(duration: TimeInterval = 0.5) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1.0
        })
    }
    
    
    func fadeOut(duration: TimeInterval = 0.5) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
    }
    
}
