//
//  DetailBusViewController.swift
//  VistarPasanger
//
//  Created by Всеволод on 26.01.2018.
//  Copyright © 2018 me4air. All rights reserved.
//

import UIKit

class DetailBusViewController: UIViewController {
    @IBOutlet weak var busStopNameLabel: UILabel!

    @IBOutlet weak var busStopCommentLabe: UILabel!
    var busStopName = ""
    var busStopComment = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        busStopNameLabel.adjustsFontSizeToFitWidth = true
        busStopNameLabel.minimumScaleFactor = 0.2
        busStopNameLabel.text = busStopName
        busStopCommentLabe.text = busStopComment
        guard let url = URL(string: "http://passenger.vistar.su/VPArrivalServer/arrivaltimeslist") else {return}
        let parameters = ["regionId":"36" , "fromStopId": ["428"] , "toStopId": ["429","430","431"]] as [String : Any]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {return}
        request.httpBody = httpBody
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, erroe) in
            if let response = response {
             print(response)
                print("hello4")
             }
            guard let data = data else {return}
            do{
                let busStops = try JSONSerialization.jsonObject(with: data, options: [])
                print(busStops)
            } catch {
                print(error)
            }
            }.resume()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
