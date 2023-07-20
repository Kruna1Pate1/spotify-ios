//
//  APIManager+Inerceptor.swift
//  My Spotify
//
//  Created by Krunal Patel on 06/07/23.
//

import Alamofire

class APIManagerInterceptor: RequestInterceptor {
    
    // MARK: - Vars & Lets
    private let refreshTokenViewModel = RefreshTokenViewModel()
    private var isRetrying = false
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var newRequest = urlRequest
        if urlRequest.url?.absoluteString.hasPrefix(AppConstants.baseApi) == true {
            newRequest.setValue("Bearer \(KeychainHelper.shared.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        } else if urlRequest.url?.absoluteString.hasPrefix(AppConstants.baseAuth) == true {
            if let basicCredential =  "\(AppConstants.clientId):\(AppConstants.clientSecret)".data(using: .utf8)?.base64EncodedString() {
                newRequest.setValue("Basic " + basicCredential, forHTTPHeaderField: "Authorization")
            }
        }
        completion(.success(newRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        if (request.error?.responseCode == 401) {
            guard !isRetrying else { return }
            
            isRetrying = true
            refreshTokenViewModel.isSuccess.bind { [weak self] isSucsess in
                isSucsess ? completion(.retry) : completion(.doNotRetry)
                self?.isRetrying = false
            }
            refreshTokenViewModel.callRefreshToken()
        } else {
            completion(.doNotRetry)
        }
    }
}
