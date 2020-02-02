//
//  URLProtocolStub.swift
//  EmpresasAppTests
//
//  Created by Anderson on 02/02/20.
//  Copyright © 2020 Anderson. All rights reserved.
//

import Foundation

// MARK: - URLProtocolStub class
class URLProtocolStub: URLProtocol {
    private static var stub: Stub?
    private static var requestObserver: ( (URLRequest) -> Void)?
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }

    override class func canInit(with request: URLRequest) -> Bool {
        //Intercep all requests
        requestObserver?(request)
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        
        if let data = URLProtocolStub.stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = URLProtocolStub.stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let error = URLProtocolStub.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
    
    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        stub = Stub(data: data, response: response, error: error)
    }
    
    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stub = nil
        requestObserver = nil
    }
    
    static func observeRquests(observer: @escaping (URLRequest) -> Void) {
        requestObserver = observer
    }
}
