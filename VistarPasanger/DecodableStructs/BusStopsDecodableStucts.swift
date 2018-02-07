//
//  BusStopsDecodableStucts.swift
//  VistarPasanger
//
//  Created by Всеволод on 02.02.2018.
//  Copyright © 2018 me4air. All rights reserved.
//

import Foundation

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
