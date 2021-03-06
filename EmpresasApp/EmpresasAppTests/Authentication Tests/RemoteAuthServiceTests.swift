//
//  RemoteAuthService.swift
//  EmpresasAppTests
//
//  Created by Anderson on 29/01/20.
//  Copyright © 2020 Anderson. All rights reserved.
//

import XCTest
@testable import EmpresasApp


class RemoteAuthServiceTests: XCTestCase {
    
    func test_init_doesNotRequestAuthenticationDataFromEndpoint() {
        let (_,client) = makeSUT()
        
        XCTAssertNil(client.postRequest)
    }
    
    func test_authenticate_requestDataFromEndpointURL() {
        let endpointURL = URL(string: "https://test-authentication.com")!
        let email = "email@email.com"
        let password = "123123"
        let (sut,client) = makeSUT(endpointURL: endpointURL)

        sut.authenticate(email: email, password: password){ _ in }

        XCTAssertEqual(client.postRequest?.url,endpointURL)
    }
    
    func test_authenticate_resquestwithEmailPasswordIntoBody() {
        let (sut,_) = makeSUT()
        let email = "email@email.com"
        let password = "123123"
        
        sut.authenticate(email: email, password: password){ _ in }
        
        XCTAssertEqual(sut.body,["email": email,"password":password])
        
    }
    
    func test_authenticate_deliversErrorOnClientConnectivityError() {
        let email = "email@email.com"
        let password = "123123"
        let (sut,client) = makeSUT()
        
        var capturedResult: Result<Investor,RemoteAuthService.AuthenticationError> = .failure(.generic)
        
        sut.authenticate(email: email, password: password) { result in capturedResult = result
        }
        
        let clientError = NSError(domain:"Test",code:0)
        client.complete(whith: clientError)
        
        XCTAssertEqual(capturedResult,.failure(.connectivity))
    }
    
    func test_authentication_deliversUnauthorizedErrorOn401HttpResponse() {
        let email = "email@email.com"
        let password = "123123"
        let (sut,client) = makeSUT()
        
        var capturedResult: Result<Investor,RemoteAuthService.AuthenticationError> = .failure(.generic)
        sut.authenticate(email: email, password: password) { result in capturedResult = result
        }
        
        client.complete(whithStatusCode: 401)
        
        XCTAssertEqual(capturedResult, .failure(.unauthorized))
    }
    
    func test_authentication_deliversBadRequestErrorOn400HttpResponse() {
        let email = "email@email.com"
        let password = "123123"
        let (sut,client) = makeSUT()
        
        var capturedResult: Result<Investor,RemoteAuthService.AuthenticationError> = .failure(.generic)
        sut.authenticate(email: email, password: password) { result in capturedResult = result
        }
        
        client.complete(whithStatusCode: 400)
        
        XCTAssertEqual(capturedResult, .failure(.badRequest))
    }
    
    func test_authentication_deliversForbiddenErrorOn403HttpResponse() {
        let email = "email@email.com"
        let password = "123123"
        let (sut,client) = makeSUT()
        
        var capturedResult: Result<Investor,RemoteAuthService.AuthenticationError> = .failure(.generic)
        sut.authenticate(email: email, password: password) { result in capturedResult = result
        }
        
        client.complete(whithStatusCode: 403)
        
        XCTAssertEqual(capturedResult, .failure(.forbidden))
    }
    
    func test_authentication_deliversErrorOn200HttpResponseWithInvalidData() {
        let email = "email@email.com"
        let password = "123123"
        let (sut,client) = makeSUT()
        
        var capturedResult: Result<Investor,RemoteAuthService.AuthenticationError> = .failure(.generic)
        sut.authenticate(email: email, password: password) { result in capturedResult = result
        }
        
        let invalidJSON = Data("Invalid json".utf8)
        client.complete(whithStatusCode: 200,data: invalidJSON)
        
        XCTAssertEqual(capturedResult, .failure(.invalidData))
    }
    
    func test_authentication_deliversInvestorOn200HttpResponseWithValidJSON() {
        let email = "email@email.com"
        let password = "123123"
        let (sut,client) = makeSUT()
        
        var capturedResults = [Result<Investor,RemoteAuthService.AuthenticationError>]()
        
        sut.authenticate(email: email, password: password) { result in capturedResults.append(result)
        }
        
        client.complete(whithStatusCode: 200, data: makeValidJSONData())
        
        
        XCTAssertEqual(capturedResults, [.success(makeValidInvestor())])
        
    }
    
    func test_authorizationState_deliversAuthStateWithAccessTokenClientAndUIDAfterSuccessAuthorizationURLResponse() {
        let accessToken = "fqnQtzqRNfDlDdo05IWfpQ"
        let client = "9RMMRW0AGQlY2LSlMom5IQ"
        let uid = "testeapple@ioasys.com.br"
        let successHTTPURLResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!, statusCode: 200, httpVersion: nil, headerFields: makeSuccessHttpHeader())!
                
        
        let authState = AuthState.extractAuthState(from: successHTTPURLResponse)
        
        XCTAssertEqual(authState.accessToken, accessToken)
        XCTAssertEqual(authState.client, client)
        XCTAssertEqual(authState.uid, uid)
    }
    
    // MARK: - Helpers
    private func makeSUT(endpointURL: URL = URL(string: "https://test-authentication.com")! ) -> (sut: RemoteAuthService, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteAuthService(endpointURL: endpointURL,client: client)
        return (sut,client)
    }
    
    private func makeValidInvestor() -> Investor {
        let portfolio = Portfolio(enterprisesNumber: 0, enterprises: [])
        return Investor(id: 1,
                        investorName: "Test Apple",
                        email: "testeapple@ioasys.com.br",
                        city: "BH",
                        country: "Brasil",
                        balance: 350000.0,
                        photo: "/uploads/investor/photo/1/cropped4991818370070749122.jpg",
                        portfolio: portfolio,
                        portfolioValue: 350000.0,
                        firstAccess: false,
                        superAngel: false)
    }
    
    private func makeValidJSONData() -> Data {        
        let bundle = Bundle(for: type(of: self))
        
        guard let url = bundle.url(forResource: "validJSON", withExtension: ".json") else {
            XCTFail("Missing file: validJSON.json")
            return Data()
        }
        
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            return data
        } catch let error{
            XCTFail(error.localizedDescription)
        }
        return Data()
    }
    
    private func makeSuccessHttpHeader() -> [String: String] {
        return ["x-content-type-options": "nosniff",
        "access-token": "fqnQtzqRNfDlDdo05IWfpQ",
        "Vary": "Accept-Encoding",
        "Etag": "W/\"ec6476a676156a668bdfbe403e4af5dd\"",
        "client": "9RMMRW0AGQlY2LSlMom5IQ",
        "expiry": "1581782592",
        "Content-Type": "application/json; charset=utf-8",
        "Content-Encoding": "gzip",
        "Server": "nginx/1.13.12",
        "token-type": "Bearer",
        "Date": "Sat, 01 Feb 2020 16:03:13 GMT",
        "uid": "testeapple@ioasys.com.br",
        "x-frame-options": "SAMEORIGIN",
        "x-request-id": "4b884ec56d6b0d07af418874d41effa0",
        "x-xss-protection": "1; mode=block",
        "x-runtime": "0.521951",
        "Cache-Control": "max-age=0, private, must-revalidate"]
    }
}

