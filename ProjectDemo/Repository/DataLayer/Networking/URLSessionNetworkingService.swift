//
//  NetworkingService.swift
//  ProjectDemo
//
//  Created by Manh Hung on 25/10/24.
//

import Foundation
import Reachability

// swiftlint:disable all
final class URLSessionNetworkingService: NSObject, NetworkingServiceProtocol, URLSessionDelegate {
    static var shared: URLSessionNetworkingService = URLSessionNetworkingService()
    
    func requestAPI<T: Codable>(request: URLRequestConverterProtocol & APIConfigurationProtocol) async throws -> T? {
        guard let urlRequest = request.asUrlRequest() else {
            throw RequestError.unknown
        }
        do {
            let (data, urlResponse) = try await URLSession(configuration: .default, delegate: self, delegateQueue: nil).data(for: urlRequest)
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw RequestError.unknown
            }
            switch httpResponse.statusCode {
            case 200..<300:
                return try JSONDecoder().decode(T.self, from: data)
            case 500...:
                throw APIError.internalError
            default:
                throw APIError.errorResponse(.init(statusCode: httpResponse.statusCode,
                                                   responseData: data))
            }
        } catch {
            if let error = error as? APIError {
                switch error {
                case .internalError:
                    await Utils.showAlertError()
                    throw error
                case .noInternet:
                    await Utils.showAlertError(message: ProjectLanguage.noInternetConnection)
                    throw error
                default:
                    throw error
                }
            } else if let error = error as? URLError {
                switch error.code {
                case .timedOut:
                    await Utils.showAlertError()
                    throw APIError.timeout
                case .notConnectedToInternet:
                    throw APIError.noInternet
                default:
                    throw RequestError.unknown
                }
            } else {
                throw error
            }
        }
    }
}