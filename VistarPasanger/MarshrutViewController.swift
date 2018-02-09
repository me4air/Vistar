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

class MarshrutViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, MKMapViewDelegate
  {

    
    

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBarConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewHightConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    
    var searchActive : Bool = false
    var savedSearchConstraint = 0.0
    let searchController = UISearchController(searchResultsController: nil)
    var keyBoardHeight = 0
    var allBusStops: [BusStops] = []
    var filterdResoultArray: [BusStops] = []

    
    override func viewWillAppear(_ animated: Bool) {
        getDataFromeCoreData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 59
        savedSearchConstraint = Double(searchBarConstraint.constant)
        configureSearchController()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        // Do any additional setup after loading the view.
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
            return (allBusStops.count)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    func busStopToDisplayAT(indexPath: IndexPath) -> BusStops {
        let busStop: BusStops
        if searchController.isActive && searchController.searchBar.text != "" {
            busStop = filterdResoultArray[indexPath.row]
        }
        else {
            busStop = allBusStops[indexPath.row]
        }
        return busStop
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let busStop = busStopToDisplayAT(indexPath: indexPath)
        cell.textLabel?.text = busStop.name
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
        filterdResoultArray = allBusStops.filter({ (busStop) -> Bool in
            return (busStop.name?.lowercased().contains(text.lowercased()))!
        })
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentFor(searchText: searchController.searchBar.text!)
        resizeTableViewForSearch()
        tableView.reloadData()
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
        
    }
    
    
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        if !searchActive {
            searchActive = true
        }
        searchBar.resignFirstResponder()
    }
    

    

}
