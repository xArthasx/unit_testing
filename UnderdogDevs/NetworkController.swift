//
//  NetworkController.swift
//  UnderdogDevs
//
//  Created by Fernando Olivares on 12/15/20.
//

import Foundation

protocol Fetcher {
    func fetch(request: NetworkController.Request, completion: @escaping (Result<Data, Error>) -> Void)
}


class NetworkController {
    
    let baseURL: String
    init(baseURL: String = "https://swapi.dev/api") {
        self.baseURL = baseURL
    }
    
    enum FetchError : Error {
        case network(Error)
        case missingResponse
        case unexpectedResponse(Int)
        case invalidData
        case invalidJSON(Error)
    }
    
    enum Request {
        case planets
    }
    
    func fetchPlanets(using fetcher: Fetcher, completion: @escaping (Result<[Planet], FetchError>) -> Void) {
        
        // Requesting from Network
        fetcher.fetch(request: .planets) { (result: Result<Data, Error>) in
        
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let planetsResult = try decoder.decode(PlanetResult.self, from: data)
                    completion(.success(planetsResult.results))
                } catch {
                    completion(.failure(.invalidJSON(error)))
                }
                
            case .failure(let error):
                //completion(.failure(error))
            break
            }
        }
    }
}

extension URLSession : Fetcher {
    func fetch(request: NetworkController.Request,
               completion: @escaping (Result<Data, Error>) -> Void) {
        
        let url = URL(string: baseURL + "/planets")!
        let request = URLRequest(url: url)
        let newTask = URLSession.shared.dataTask(with: request) { (possibleData, possibleResponse, possibleError) in
            
            guard possibleError == nil else {
                completion(.failure(possibleError!))
                return
            }
            
            guard let response = possibleResponse as? HTTPURLResponse else {
                let error = NSError(domain: "NetworkSession",
                                    code: 0,
                                    userInfo: [NSLocalizedFailureErrorKey: "Invalid HTTP URL code"])
                completion(.failure(error))
                return
            }
            
            guard (200...299).contains(response.statusCode) else {
                let error = NSError(domain: "NetworkSession",
                                    code: response.statusCode,
                                    userInfo: [NSLocalizedFailureErrorKey: "Unexpected HTTP code (>200)"])
                completion(.failure(error))
                return
            }
            
            guard let receivedData = possibleData else {
                let error = NSError(domain: "NetworkSession",
                                    code: response.statusCode,
                                    userInfo: [NSLocalizedFailureErrorKey: "Invalid data"])
                completion(.failure(error))
                return
            }
            
            completion(.success(receivedData))
        }
        
        newTask.resume()
    }
    
    
}
