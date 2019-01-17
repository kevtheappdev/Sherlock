//
//  SherlockTests.swift
//  SherlockTests
//
//  Created by Kevin Turner on 12/20/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import XCTest
@testable import Sherlock

class SherlockTests: XCTestCase {
    var expectation: XCTestExpectation!
    var fulfilled = false
    var expected: [serviceType] = [.wikipedia, .google, .facebook, .twitter]

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        // TODO: have way to specify the exact services to include
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    
    func testAutoOrdering(){
        // test autoordering
        expectation = self.expectation(description: "Wait for autoorder")
        let _ = SherlockServiceManager.main.begin(Query: "Xcode")
        SherlockServiceManager.main.delegate = self
        self.waitForExpectations(timeout: 2, handler: nil)
        
        expectation = self.expectation(description: "Wait for autoorder")
        let _ = SherlockServiceManager.main.begin(Query: "Kevin Turner")
        expected = [.facebook, .twitter, .google, .wikipedia]
        fulfilled = false
        self.waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testShortcuts() {
        let shortcuts = SherlockShortcutManager.main.shortcuts
        for shortcut in shortcuts {
            let query = SherlockServiceManager.main.begin(Query: shortcut.activationText)
            XCTAssert(query.isEmpty)
            var updatedServices = SherlockServiceManager.main.userServices
            var expectedServices = shortcut.services
            
            updatedServices.sort(by: {(a: SherlockService, b: SherlockService) in
                return a.type.rawValue < b.type.rawValue
            })
            
            expectedServices.sort(by: {(a: serviceType, b: serviceType) in
                return a.rawValue < b.rawValue
            })
            
            for (service, expectedService) in zip(updatedServices, expectedServices) {
                print("service: \(service.type.rawValue) expected: \(expectedService.rawValue)")
                XCTAssert(service.type == expectedService)
            }
        }
    }
    

}

extension SherlockTests: SherlockServiceManagerDelegate {
    func resultsChanged(_ services: [SherlockService]) {
        
        
        var match = false
        for (service, expectedService) in zip(services, expected) {
            print("services: \(service.type)")
            if service.type == expectedService {
                match = true
            }
        }
        
        if !fulfilled && match {
            expectation.fulfill()
            fulfilled = true
        }
        
    }
    
    func resultsCleared() {
        
    }
    
}
