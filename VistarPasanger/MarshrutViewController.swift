//
//  MarshrutViewController.swift
//  VistarPasanger
//
//  Created by Всеволод on 07.02.2018.
//  Copyright © 2018 me4air. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MarshrutViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, MKMapViewDelegate, CLLocationManagerDelegate
  {

    
    
    @IBOutlet weak var searchConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableViewHightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    
    var searchActive : Bool = false
    var savedSearchConstraint = 0.0
    let searchController = UISearchController(searchResultsController: nil)
    var locationManager = CLLocationManager()
    var keyBoardHeight = 0
    var allBusStops: [BusStops] = []
    var busStopsForSearch: [BusStops] = []
    var filterdResoultArray: [BusStops] = []
    var busStopsForMap: [BusStops] = []
    var userLocation:CLLocation = CLLocation(latitude: 0.0, longitude: 0.0)
    let mapAnnotation = MKPointAnnotation()
    var savedMapHieght = 9800.0
    

    
    override func viewWillAppear(_ animated: Bool) {
        tableView.isScrollEnabled = false
        getDataFromeCoreData()
        determineMyCurrentLocation()
        mapView.camera.altitude = 9800
        busStopsForSearch = clearBusStopsFromDuplicates(busStops: allBusStops)
        busStopsForMap = filterBusStopsForMap(busStops: allBusStops)
        refreshMapAnnotations()     
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 65
        savedSearchConstraint = Double(searchConstraint.constant)
        configureSearchController()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        locationManager.startUpdatingHeading()
        mapView.delegate = self
        determineMyCurrentLocation()
        mapView.camera.centerCoordinate.latitude = userLocation.coordinate.latitude
        mapView.camera.centerCoordinate.longitude = userLocation.coordinate.longitude
        
    }

    override func viewWillDisappear(_ animated: Bool) {
       locationManager.stopUpdatingLocation()
    }
    
    func clearBusStopsFromDuplicates(busStops: [BusStops]) -> [BusStops] {
        var clearedBusStops: [BusStops] = []
        var isUnicue = true
        if busStops.count != 0 {
            clearedBusStops.append(busStops[0])
            for i in 0...busStops.count-1 {
                for j in 0...clearedBusStops.count-1{
                    if((clearedBusStops[j].name?.lowercased() == busStops[i].name?.lowercased())){
                        isUnicue = false
                    }
                }
                if isUnicue {
                    clearedBusStops.append(busStops[i])
                }
                isUnicue = true
            }
        }
        return clearedBusStops
    }
    
    func filterBusStopsForMap(busStops: [BusStops]) -> [BusStops]{
        var filteredBusStops: [BusStops] = []
        var isUnicue = true
        var firstCoordinates = CLLocation(latitude: 0.0, longitude: 0.0)
        var secondCoordinates = CLLocation(latitude: 0.0, longitude: 0.0)
        if busStops.count != 0 {
            filteredBusStops.append(busStops[0])
            for i in 0...busStops.count-1 {
                for j in 0...filteredBusStops.count-1{
                    firstCoordinates = CLLocation(latitude: filteredBusStops[j].lat, longitude: filteredBusStops[j].lon)
                    secondCoordinates = CLLocation(latitude: busStops[i].lat, longitude: busStops[i].lon)
                    let distance = firstCoordinates.distance(from: secondCoordinates)
                    let hypotenuse = (distance*distance+mapView.camera.altitude*mapView.camera.altitude).squareRoot()
                    let angle = acos(mapView.camera.altitude/hypotenuse)
                    if(angle<(4 * .pi/180)){
                        isUnicue = false
                    }
                }
                if isUnicue {
                    filteredBusStops.append(busStops[i])
                }
                isUnicue = true
            }
        }
        return filteredBusStops
    }
    
    
    func createBusStopAnnotationSet(busStopName: String) -> [BusStops]{
        var busStopsForAnnotation: [BusStops] = []
        for i in 0...allBusStops.count-1{
            if allBusStops[i].name == busStopName {
                busStopsForAnnotation.append(allBusStops[i])
            }
        }
        busStopsForAnnotation = filterBusStopsForMap(busStops: busStopsForAnnotation)
        return busStopsForAnnotation
    }
    
    func addBusStopsOnMap(){
        if self.busStopsForMap.count != 0 {
            for i in 0...self.busStopsForMap.count-1{
                let busAnotation = BusPointAnnotation()
                busAnotation.coordinate.latitude = self.busStopsForMap[i].lat
                busAnotation.coordinate.longitude = self.busStopsForMap[i].lon
                busAnotation.title = self.busStopsForMap[i].name
                self.mapView.addAnnotation(busAnotation)
            }
        }
    }
    
    func refreshMapAnnotations(){
            clearMapAnnotations()
        if searchController.searchBar.text != ""{
            mapView.removeAnnotations(mapView.annotations)
            if filterdResoultArray.count != 0{
            var annotatinBusStopList: [BusStops] = []
            for i in 0...filterdResoultArray.count-1{
                annotatinBusStopList.append(contentsOf: createBusStopAnnotationSet(busStopName: filterdResoultArray[i].name!))
                }
                for i in 0...annotatinBusStopList.count-1{
                let busAnotation = BusPointAnnotation()
                busAnotation.coordinate.latitude = annotatinBusStopList[i].lat
                busAnotation.coordinate.longitude = annotatinBusStopList[i].lon
                busAnotation.title = annotatinBusStopList[i].name
                self.mapView.addAnnotation(busAnotation)
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.addBusStopsOnMap()
            }
            
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKAnnotationView(annotation: self.mapAnnotation, reuseIdentifier: "busStop")
        if (annotation is BusPointAnnotation) {
            annotationView.image = UIImage(named: "busStopIcon")
            annotationView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            let label = UILabel(frame: CGRect(x: 0, y: 60, width: 200, height: 50))
            var text = ""
             if !annotation.isKind(of: MKUserLocation.self) {
                text = annotation.title!!
             } else{
             text = "Вы здесь"
             }
            label.attributedText = NSMutableAttributedString(string: text,
                                                             attributes: stroke(font: UIFont(name: "AppleSDGothicNeo-Bold", size: 32)!,
                                                                                strokeWidth: 3, insideColor: #colorLiteral(red: 0.3122831257, green: 0.3381157644, blue: 0.3756441717, alpha: 1), strokeColor: #colorLiteral(red: 0.9177109772, green: 0.9177109772, blue: 0.9177109772, alpha: 1)))
            label.textAlignment = NSTextAlignment.center
            label.sizeToFit()
            label.center = CGPoint(x: label.center.x-label.frame.width/2+annotationView.frame.width, y: 80)
            annotationView.layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            annotationView.layer.shadowRadius = 2
            annotationView.layer.shadowOpacity = 0.5
            annotationView.layer.shadowOffset = CGSize(width: 0, height: 2)
            if (annotation is BusPointAnnotation) {
                annotationView.layer.shadowPath = UIBezierPath(rect: annotationView.bounds).cgPath
            }
            annotationView.addSubview(label)
        }
         return annotationView
    }
    
    public func stroke(font: UIFont, strokeWidth: Float, insideColor: UIColor, strokeColor: UIColor) -> [NSAttributedStringKey: Any]{
        return [
            NSAttributedStringKey.strokeColor : strokeColor,
            NSAttributedStringKey.foregroundColor : insideColor,
            NSAttributedStringKey.strokeWidth : -strokeWidth,
            NSAttributedStringKey.font : font
        ]
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if abs(mapView.camera.altitude-savedMapHieght) > 20 {
            if busStopsForMap.count != filterBusStopsForMap(busStops: allBusStops).count{
                busStopsForMap = filterBusStopsForMap(busStops: allBusStops)
                refreshMapAnnotations()}
        }
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        savedMapHieght = mapView.camera.altitude
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        views.forEach { (view) in
            view.alpha = 0.0
            view.fadeIn(duration: 0.3)

        }
    }
    
    func clearMapAnnotations(){
        
        self.mapView.annotations.forEach {
            if ($0 is BusPointAnnotation) {
                self.mapView.view(for: $0)?.fadeOut(duration: 0.3)
            }
        }
        
    }
    
    func determineMyCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
        self.userLocation = locationManager.location!
    }
    
    //вызывается при изменении геопозиции
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        self.userLocation = userLocation
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func keyboardWillShow(notification: NSNotification)  {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight : Int = Int(keyboardSize.height)
            self.keyBoardHeight = keyboardHeight
        }
    }
    
    // MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != ""{
            return filterdResoultArray.count
        } else {
            return (busStopsForSearch.count)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        searchController.searchBar.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        searchBarSearchButtonClicked(searchController.searchBar)
        if mapView.annotations.count != 0 {
            mapView.camera.centerCoordinate = mapView.annotations[0].coordinate
            mapView.camera.altitude = 9800
        }
    }
    

    
    func busStopToDisplayAT(indexPath: IndexPath) -> BusStops {
        let busStop: BusStops
        if searchController.isActive && searchController.searchBar.text != "" {
            busStop = filterdResoultArray[indexPath.row]
        }
        else {
            busStop = busStopsForSearch[indexPath.row]
        }
        return busStop
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let busStop = busStopToDisplayAT(indexPath: indexPath)
        cell.textLabel?.text = busStop.name
        cell.detailTextLabel?.text = busStop.comment
        return cell
    }
    
    func configureSearchController() {
        
        self.searchController.searchResultsUpdater = self
        self.searchController.delegate = self
        self.searchController.searchBar.delegate = self
        
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.dimsBackgroundDuringPresentation = true
        self.searchController.obscuresBackgroundDuringPresentation = false
        
        searchController.searchBar.placeholder = "Куда поедем?"
        searchController.searchBar.sizeToFit()
        searchController.searchBar.becomeFirstResponder()
        tableView.tableHeaderView = searchController.searchBar
        
    }
    
    //MARK: CoreData
    
    func getDataFromeCoreData(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
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

    
    //MARK: Search Bar
    
    
    func filterContentFor (searchText text: String){
        filterdResoultArray = busStopsForSearch.filter({ (busStop) -> Bool in
            return (busStop.name?.lowercased().contains(text.lowercased()))!
        })
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentFor(searchText: searchController.searchBar.text!)
        resizeTableViewForSearch()
        tableView.reloadData()
        refreshMapAnnotations()
    }
    
    func getDistanceBetweenSearchAndKeyboard() -> CGFloat {
        return self.view.frame.height-CGFloat(self.keyBoardHeight)
    }
    
    func openSearch(){
        UIView.animate(withDuration: 0.4) {
            self.searchConstraint.constant=0
            self.tableViewHightConstraint.constant = self.getDistanceBetweenSearchAndKeyboard()
            self.view.layoutIfNeeded()
            self.tableView.isScrollEnabled = true
            
        }
    }
    
    func resizeTableViewForSearch(){
        if searchController.searchBar.text != ""{
        UIView.animate(withDuration: 0.2) {
            if (CGFloat(self.filterdResoultArray.count) * self.tableView.rowHeight < self.getDistanceBetweenSearchAndKeyboard()){
                self.tableViewHightConstraint.constant = CGFloat(self.filterdResoultArray.count) * self.tableView.rowHeight + self.searchController.searchBar.frame.height
            }
            else {
                self.tableViewHightConstraint.constant = self.getDistanceBetweenSearchAndKeyboard()
            }
            self.view.layoutIfNeeded()
            
            }
        }
    }
    
    func closeSearch(){
        UIView.animate(withDuration: 0.4) {
            self.searchConstraint.constant=CGFloat(self.savedSearchConstraint)
            self.tableViewHightConstraint.constant = self.searchController.searchBar.frame.height
            self.searchController.isActive = false
            self.view.layoutIfNeeded()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        refreshMapAnnotations()
        searchActive = false
        closeSearch()
        self.dismiss(animated: true, completion: nil)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
        openSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        let text = searchBar.text
        closeSearch()
        searchBar.text = text
        if mapView.annotations.count != 0 {
            mapView.camera.centerCoordinate = mapView.annotations[0].coordinate
        }
        busStopsForMap = filterBusStopsForMap(busStops: filterdResoultArray)
        refreshMapAnnotations()
        
    }
    
    
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        if !searchActive {
            searchActive = true
        }
        searchBar.resignFirstResponder()
    }
    


}




