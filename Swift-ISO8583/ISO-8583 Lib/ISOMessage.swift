//
//  ISOMessage.swift
//  Swift-ISO8583
//
//  Created by Jorge Tapia on 3/14/15.
//  Copyright (c) 2015 Jorge Tapia. All rights reserved.
//

import Foundation

class ISOMessage {
    // MARK: Properties
    
    private(set) var mti: String?
    var bitmap: ISOBitmap?
    private(set) var hasSecondaryBitmap: Bool
    private(set) var usesCustomConfiguration: Bool
    
    var dataElements: NSMutableDictionary?
    
    private var dataElementsScheme: NSDictionary
    private var validMTIs: NSArray
    
    // MARK: Initializers
    
    init() {
        let pathToConfigFile = Bundle.main.path(forResource: "isoconfig", ofType: "plist")
        dataElementsScheme = NSMutableDictionary(contentsOfFile: pathToConfigFile!)!
        dataElements = NSMutableDictionary(capacity: dataElementsScheme.count)
        
        let pathToMTIConfigFile = Bundle.main.path(forResource: "isoMTI", ofType: "plist")
        validMTIs = NSArray(contentsOfFile: pathToMTIConfigFile!)!
        
        usesCustomConfiguration = false
        hasSecondaryBitmap = false
    }
    
    convenience init?(isoMessage: String, customConfigurationFileName: String?, customMTIFileName: String?) {
        self.init()
        
        _ = useCustomConfigurationFiles(customConfigurationFileName: customConfigurationFileName, customMTIFileName: customMTIFileName)
        
        let headerEndIndex = isoMessage.index(isoMessage.startIndex, offsetBy: 3)
        let isoHeaderPresent = isoMessage[isoMessage.startIndex..<headerEndIndex] == "ISO"
        
        if !isoHeaderPresent {
            // Sets MTI
            let mtiEndIndex = isoMessage.index(isoMessage.startIndex, offsetBy: 4)
            _ = setMTI(mti: String(isoMessage[isoMessage.startIndex..<mtiEndIndex]))
            
            print("MTI: \(mti!)")
            
            let startBitmapFirstBitIndex = isoMessage.index(isoMessage.startIndex, offsetBy: 4)
            let endBitmapFirstBitIndex = isoMessage.index(after: startBitmapFirstBitIndex)
            
            let bitmapFirstBit = isoMessage[startBitmapFirstBitIndex..<endBitmapFirstBitIndex]
            
            // Sets bitmap
            hasSecondaryBitmap = bitmapFirstBit == "8" || bitmapFirstBit == "9" || bitmapFirstBit == "A" || bitmapFirstBit == "B" || bitmapFirstBit == "C" || bitmapFirstBit == "D" || bitmapFirstBit == "E" || bitmapFirstBit == "F"
            
            let endBitmapIndex = hasSecondaryBitmap ? isoMessage.index(startBitmapFirstBitIndex, offsetBy: 32) : isoMessage.index(startBitmapFirstBitIndex, offsetBy: 16)
            let bitmapHexString = isoMessage[startBitmapFirstBitIndex..<endBitmapIndex]
            
            print("Bitmap Hex String: \(bitmapHexString)")
            bitmap = ISOBitmap(hexString: String(bitmapHexString))
            
            
            // Extract and set values for data elements
            let dataElementValues = String(isoMessage[endBitmapIndex...])
            print("dataElementValues: \(dataElementValues)")
            let theValues = extractDataElementValues(isoMessageDataElementValues: dataElementValues, dataElements: bitmap?.dataElementsInBitmap())
            
            print("MTI: \(mti!)")
            print("Bitmap: \(bitmap!.rawValue!)")
            print("Data: \(dataElementValues)")
            print("Values: \(theValues ?? [])")
        } else {
            // TODO: with iso header
        }
    }
    
    convenience init?(isoMessage: String) {
        self.init(isoMessage: isoMessage, customConfigurationFileName: nil, customMTIFileName: nil)
    }
    
    // MARK: Methods
    
    func setMTI(mti: String) -> Bool {
        if (isValidMTI(mti: mti)) {
            self.mti = mti
            return true
        } else {
            print("The MTI is not valid. Please set a valid MTI like the ones described in the isoMTI.plist or your custom MTI configuration file.")
            return false
        }
    }
    
    func addDataElement(elementName: String?, value: String?) -> Bool {
        return addDataElement(elementName: elementName, value: value, customConfigFileName: nil)
    }
    
    func addDataElement(elementName: String?, value: String?, customConfigFileName: String?) -> Bool {
        return false
    }
    
    func useCustomConfigurationFiles(customConfigurationFileName: String?, customMTIFileName: String?) -> Bool {
        if customConfigurationFileName == nil {
            print("The customConfigurationFileName cannot be nil.")
            return false
        }
        
        if customMTIFileName == nil {
            print("The customMTIFileName cannot be nil.")
            return false
        }
        
        let pathToConfigFile = Bundle.main.path(forResource: customConfigurationFileName, ofType: "plist")
        dataElementsScheme = NSDictionary(contentsOfFile: pathToConfigFile!)!
        dataElements = NSMutableDictionary()
        
        let pathToMTIConfigFile = Bundle.main.path(forResource: customMTIFileName, ofType: "plist")
        validMTIs = NSArray(contentsOfFile: pathToMTIConfigFile!)!
        
        usesCustomConfiguration = true
        
        return true
    }
    
    func getHexBitmap1() -> String? {
        let hexBitmapString = (bitmap?.bitmapAsHexString())!
        let endIndex = hexBitmapString.index(hexBitmapString.startIndex, offsetBy: 16)
        return String(hexBitmapString[..<endIndex])
    }
    
    func getBinaryBitmap1() -> String? {
        let binaryBitmapString = ISOHelper.hexToBinaryAsString(hexString: bitmap?.bitmapAsHexString())!
        let endIndex = binaryBitmapString.index(binaryBitmapString.startIndex, offsetBy: 64)
        return String(binaryBitmapString[..<endIndex])
    }
    
    func getHexBitmap2() -> String? {
        let isBinary = bitmap!.isBinary
        
        let bitmapString = bitmap!.rawValue!
        
        let length = bitmapString.count
        
        if isBinary && length != 128 {
            print("This bitmap does not have a secondary bitmap.")
            return nil
        } else if !isBinary && length != 32 {
            print("This bitmap does not have a secondary bitmap.")
            return nil
        } else if isBinary && length == 128 {
            return ISOHelper.binaryToHexAsString(binaryString: String(bitmapString[bitmapString.index(bitmapString.startIndex, offsetBy: 64)...]))
        } else if isBinary && length == 32 {
            return ISOHelper.binaryToHexAsString(binaryString: String(bitmapString[bitmapString.index(bitmapString.startIndex, offsetBy: 16)...]))
        }
        
        return nil
    }
    
    // MARK: Private methods
    
    private func isValidMTI(mti: String) -> Bool {
        return validMTIs.index(of: mti) > -1
    }
    
    private func extractDataElementValues(isoMessageDataElementValues: String?, dataElements: [String]?) -> [String]? {
        var dataElementCount = 0
        var fromIndex = -1
        var toIndex = -1
        var values = [String]()
        
        for dataElement in dataElements! {
            if dataElement == "DE01" {
                continue
            }
            
            let length = dataElementsScheme.value(forKeyPath: "\(dataElement).Length") as! NSString
            
            // fixed length values
            if length.range(of: ".").location == NSNotFound {
                let trueLength = Int(length as String)
                
                if dataElementCount == 0 {
                    fromIndex = 0
                    toIndex = trueLength!
                    
                    let valuesAsNSString = isoMessageDataElementValues! as NSString
                    let value = (valuesAsNSString.substring(from: fromIndex) as NSString).substring(to: toIndex)
                    values.append(value)
                    fromIndex = trueLength!
                } else {
                    toIndex = trueLength!
                    let valuesAsNSString = isoMessageDataElementValues! as NSString
                    let value = (valuesAsNSString.substring(from: fromIndex) as NSString).substring(to: toIndex)
                    values.append(value)
                    fromIndex += trueLength!
                }
            } else {
                // variable length values
                var trueLength = -1
                var numberOfLengthDigits = 0
                let valuesAsNSString = isoMessageDataElementValues! as NSString
                
                if (length as String).count == 2 {
                    numberOfLengthDigits = 1
                } else if (length as String).count == 4 {
                    numberOfLengthDigits = 2
                } else if (length as String).count == 6 {
                    numberOfLengthDigits = 3
                }
                
                if dataElementCount == 0 {
                    trueLength = Int((valuesAsNSString.substring(from:fromIndex) as NSString).substring(to: toIndex))! + numberOfLengthDigits
                    fromIndex = 0 + numberOfLengthDigits
                    toIndex = trueLength - numberOfLengthDigits
                    let value = (valuesAsNSString.substring(from: fromIndex) as NSString).substring(to: toIndex)
                    values.append(value)
                    fromIndex = trueLength;
                } else {
                    trueLength = Int((valuesAsNSString.substring(from:fromIndex) as NSString).substring(to:numberOfLengthDigits))! + numberOfLengthDigits
                    toIndex = trueLength
                    let value = (valuesAsNSString.substring(to: fromIndex + numberOfLengthDigits) as NSString).substring(to: toIndex - numberOfLengthDigits)
                    values.append(value)
                    fromIndex += trueLength
                }
            }
            
            dataElementCount += 1
        }
        
        return values
    }
}
