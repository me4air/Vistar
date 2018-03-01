//
//  DetaiBusDecodableStructs.swift
//  VistarPasanger
//
//  Created by Всеволод on 02.02.2018.
//  Copyright © 2018 me4air. All rights reserved.
//

import Foundation

struct Responce: Decodable {
    var busArrival: [BusAririvals]?
    var status: String
}

struct BusAririvals: Decodable {
    var arrivals: [Arrivals]?
    var fromStopId: Int?
    var toStopId: Int?
}

struct Arrivals: Decodable, Equatable {
    static func ==(lhs: Arrivals, rhs: Arrivals) -> Bool {
        if ((lhs.arrivalTime == rhs.arrivalTime) && (lhs.busRoute == rhs.busRoute) || ((lhs.lat == rhs.lat) && (lhs.lon == rhs.lon))) {
            return true
        }
        else {return false}
    }
    
    var arrivalTime: Int?
    var busRoute: String?
    var lat: Double?
    var lon: Double?
    var rideTime: Int?
}

struct ArivalsToDislplayData {
    var busName: String?
    var arivalTimes: [Int]?
}

struct ArivalsToMarshrutData: Decodable, Equatable {
    static func ==(lhs: ArivalsToMarshrutData, rhs: ArivalsToMarshrutData) -> Bool {
        if ((lhs.arrivalTime == rhs.arrivalTime) && (lhs.fromStopId == rhs.fromStopId) && (lhs.busRoute == rhs.busRoute) || ((lhs.lat == rhs.lat) && (lhs.lon == rhs.lon))) {
            return true
        }
        else {return false}
    }
    
    var fromStopId: String?
    var arrivalTime: Int?
    var busRoute: String?
    var lat: Double?
    var lon: Double?
    var rideTime: Int?
}
