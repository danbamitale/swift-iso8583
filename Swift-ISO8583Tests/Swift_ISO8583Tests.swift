//
//  Swift_ISO8583Tests.swift
//  Swift-ISO8583Tests
//
//  Created by Jorge Tapia on 3/14/15.
//  Copyright (c) 2015 Jorge Tapia. All rights reserved.
//

import UIKit
import XCTest
@testable import Swift_ISO8583

class Swift_ISO8583Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDefaultUnpack() {
        let isoMessage3 = ISOMessage(isoMessage: "0200B2200000001000000000000000800000000123000000000123000000012300012314Value for DE44027This is the value for DE105")
        print("Hex bitmap 1: \(isoMessage3?.getHexBitmap1() ?? "")")
        print("Bin bitmap 1: \(isoMessage3?.getBinaryBitmap1() ?? "" )")
        print("Hex bitmap 2: \(isoMessage3?.getHexBitmap2() ?? "")")
    }
    
    func testTamsIso0800Unpack() {
        let isoMessage3 = ISOMessage(isoMessage: "080022380000008000009A000009031749581749581749580903FG001234")
        print("Hex bitmap 1: \(isoMessage3?.getHexBitmap1() ?? "")")
        print("Bin bitmap 1: \(isoMessage3?.getBinaryBitmap1() ?? "" )")
        print("Hex bitmap 2: \(isoMessage3?.getHexBitmap2() ?? "")")
    }
    
    func testTamsIso1800Unpack() {
        let isoMessage3 = ISOMessage(isoMessage: "180082300100820000010000000010000000071408330208330220200114083383106424465000F2ACF7574901A8D2BB154D232C2FD05E0000000000000000000000000000000006424465", customConfigurationFileName: "customConfig", customMTIFileName: "customMTI")
        print("Hex bitmap 1: \(isoMessage3?.getHexBitmap1() ?? "")")
        print("Bin bitmap 1: \(isoMessage3?.getBinaryBitmap1() ?? "" )")
        print("Hex bitmap 2: \(isoMessage3?.getHexBitmap2() ?? "")")
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
