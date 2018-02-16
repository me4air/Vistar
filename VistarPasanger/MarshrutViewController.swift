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

    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBarConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewHightConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    
    var searchActive : Bool = false
    var savedSearchConstraint = 0.0
    let searchController = UISearchController(searchResultsController: nil)
    var locationManager = CLLocationManager()
    var keyBoardHeight = 0
    var allBusStops: [BusStops] = []
    var busStopsForSearch: [BusStops] = []
    var filterdResoultArray: [BusStops] = []
    var userLocation:CLLocation = CLLocation(latitude: 0.0, longitude: 0.0)
    

    
    override func viewWillAppear(_ animated: Bool) {
        getDataFromeCoreData()
        determineMyCurrentLocation()
        busStopsForSearch = clearBusStopsFromDuplicates(busStops: allBusStops)
        addBusStopsOnMap()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 65
        savedSearchConstraint = Double(searchBarConstraint.constant)
        configureSearchController()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        locationManager.startUpdatingHeading()
        mapView.delegate = self
        determineMyCurrentLocation()
        mapView.camera.centerCoordinate.latitude = userLocation.coordinate.latitude
        mapView.camera.centerCoordinate.longitude = userLocation.coordinate.longitude
        mapView.camera.altitude = 9800
    }

    override func viewWillDisappear(_ animated: Bool) {
       locationManager.stopUpdatingLocation()
    }
    
    func clearBusStopsFromDuplicates(busStops: [BusStops]) -> [BusStops] {
        var clearedBusStops: [BusStops] = []
        var isUnicue = true
       // var firstCoordinates = CLLocation(latitude: 0.0, longitude: 0.0)
       // var secondCoordinates = CLLocation(latitude: 0.0, longitude: 0.0)
        if busStops.count != 0 {
            clearedBusStops.append(busStops[0])
            for i in 0...busStops.count-1 {
                for j in 0...clearedBusStops.count-1{
                   // firstCoordinates = CLLocation(latitude: clearedBusStops[j].lat, longitude: clearedBusStops[j].lon)
                  //  secondCoordinates = CLLocation(latitude: busStops[i].lat, longitude: busStops[i].lon)
                    if((clearedBusStops[j].name?.lowercased() == busStops[i].name?.lowercased()) /*&& firstCoordinates.distance(from: secondCoordinates)<100*/){
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
    
    func createBusStopAnnotationSet(busStopName: String) -> [BusStops]{
        var busStopsForAnnotation: [BusStops] = []
        for i in 0...allBusStops.count-1{
            if allBusStops[i].name == busStopName {
                busStopsForAnnotation.append(allBusStops[i])
            }
        }
        return busStopsForAnnotation
    }
    
    func addBusStopsOnMap(){
        if self.allBusStops.count != 0 {
            for i in 0...self.allBusStops.count-1{
                let busAnotation = BusPointAnnotation()
                busAnotation.coordinate.latitude = self.allBusStops[i].lat
                busAnotation.coordinate.longitude = self.allBusStops[i].lon
                busAnotation.title = self.allBusStops[i].name
                self.mapView.addAnnotation(busAnotation)
            }
        }
    }
    
    func refreshMapAnnotations(){
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
        searchBar.addSubview(searchController.searchBar)
        
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
        return self.view.frame.height-68-CGFloat(self.keyBoardHeight)
    }
    
    func openSearch(){
        UIView.animate(withDuration: 0.4) {
            self.searchBarConstraint.constant=0
            self.tableViewHightConstraint.constant = self.getDistanceBetweenSearchAndKeyboard()
            self.view.layoutIfNeeded()
            
        }
    }
    
    func resizeTableViewForSearch(){
        if searchController.searchBar.text != ""{
        UIView.animate(withDuration: 0.2) {
            if (CGFloat(self.filterdResoultArray.count) * self.tableView.rowHeight < self.getDistanceBetweenSearchAndKeyboard()){
                self.tableViewHightConstraint.constant = CGFloat(self.filterdResoultArray.count) * self.tableView.rowHeight
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
            self.searchBarConstraint.constant=CGFloat(self.savedSearchConstraint)
            self.tableViewHightConstraint.constant = 0
            self.searchController.isActive = false
            self.view.layoutIfNeeded()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        addBusStopsOnMap()
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
        
    }
    
    
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        if !searchActive {
            searchActive = true
        }
        searchBar.resignFirstResponder()
    }
    

    

}
