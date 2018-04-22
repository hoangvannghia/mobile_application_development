//
//  Api.swift
//  Ex2
//
//  Created by hoang van nghia on 4/22/18.
//  Copyright © 2018 hoang van nghia. All rights reserved.
//

import Foundation
import Moya
import PromiseKit

enum Api {
   case getRate
}

extension Api: TargetType {
   var baseURL: URL {
      return URL(string: "http://data.fixer.io/api")!
   }
   
   var path: String {
      switch self {
      case .getRate:
         return "/latest"
      }
   }
   
   var method: Moya.Method {
      switch self {
      case .getRate:
         return .get
      }
   }
   
   var sampleData: Data {
      return Data()
   }
   
   var task: Task {
      switch self {
      case .getRate:
         return .requestParameters(parameters: [
            "access_key": "ee310f30bd1627522755881906ee708a",
            "symbols": "VND,USD"
            ], encoding: URLEncoding.default)
      }
   }
   
   var headers: [String : String]? {
      return nil
   }
}

enum ApiError: Error {
   case internet
   case server
}

struct ApiWorker {
   private let provider = MoyaProvider<Api>()
   
   func getRates() -> Promise<(usd: Double, eur: Double)> {
      return Promise.init(resolver: { resolver in
         provider.request(.getRate, completion: { (rs) in
            switch rs {
            case .success(let data):
               if let body = (try? data.mapJSON()) as? NSDictionary, let rates = body["rates"] as? NSDictionary {
                  if let eurToVnd = rates["VND"] as? Double, let eurToUsd = rates["USD"] as? Double {
                     let usd = eurToVnd / eurToUsd
                     resolver.fulfill((usd: usd, eur: eurToVnd))
                  } else {
                     resolver.reject(ApiError.server)
                  }
               }
            case .failure:
               resolver.reject(ApiError.internet)
            }
         })
         
         
      })
   }
}



























