//
//  ISOBitmap.swift
//  Swift-ISO8583
//
//  Created by Jorge Tapia on 3/15/15.
//  Copyright (c) 2015 Jorge Tapia. All rights reserved.
//

import Foundation

class ISOBitmap {
    // MARK: Properties
    private(set) var binaryBitmap: [String]?
    private(set) var hasSecondaryBitmap: Bool = false
    private(set) var rawValue: String?
    private(set) var isBinary: Bool = false
    
    // MARK: Initializers
    init?(binaryString: String?) {
        if binaryString == nil {
            return nil
        }
        
        // Validate if it's a binary number
        let regExPattern = "[0-1]"
        let regEx = try? NSRegularExpression(pattern: regExPattern, options: .allowCommentsAndWhitespace)
        let regExMatches = regEx?.numberOfMatches(in: binaryString!, options: .anchored, range: NSMakeRange(0, binaryString!.count))
        
        if regExMatches != binaryString!.count {
            print("Parameter \(binaryString!) is an invalid binary number.")
            return nil;
        }
        
        let firstCharacterIndex = binaryString!.index(after: binaryString!.startIndex)
        hasSecondaryBitmap = String(binaryString![..<firstCharacterIndex]) == "1"
        
        if hasSecondaryBitmap && binaryString!.count != 128 {
            print("Invalid bitmap. Bitmap length must be 128 if the first bit is 1.")
            return nil
        } else if !hasSecondaryBitmap && binaryString!.count != 64 {
            print("Invalid bitmap. Bitmap length must be 64 if the first bit is 0.")
            return nil
        } else {
            rawValue = binaryString
            isBinary = true
            binaryBitmap = ISOHelper.stringToArray(string: binaryString)
        }
    }
    
    init?(hexString: String?) {
        if hexString == nil {
            return nil
        }
        
        // Validate if it's a binary number
        let regExPattern = "[0-9A-F]"
        let regEx = try? NSRegularExpression(pattern: regExPattern, options: .allowCommentsAndWhitespace)
        let regExMatches = regEx?.numberOfMatches(in: hexString!, options: .anchored, range: NSMakeRange(0, hexString!.count))
        
        if regExMatches != hexString!.count {
            print("Parameter \(hexString!) is an invalid binary number.")
            return nil;
        }
        
        let firstCharacterIndex = hexString!.index(after: hexString!.startIndex)
        let startCharacter = String(hexString![..<firstCharacterIndex])
        print("Hex First Character Index: \(startCharacter), Length: \(startCharacter.count)")
        hasSecondaryBitmap =  startCharacter == "8" ||
            startCharacter == "9" ||
            startCharacter == "A" ||
            startCharacter == "B" ||
            startCharacter == "C" ||
            startCharacter == "D" ||
            startCharacter == "E" ||
            startCharacter == "F"
        
        print("Has Secondary Bitmap: \(hasSecondaryBitmap), HexString length: \(hexString!.count)")
        
        if hasSecondaryBitmap && hexString!.count != 32 {
            print("Invalid bitmap. Bitmap length must be 32 if the first bit is 1.")
            return nil
        } else if !hasSecondaryBitmap && hexString!.count != 16 {
            print("Invalid bitmap. Bitmap length must be 16 if the first bit is 0.")
            return nil
        } else {
            rawValue = hexString
            isBinary = false
            binaryBitmap = ISOHelper.stringToArray(string: ISOHelper.hexToBinaryAsString(hexString: hexString))
        }
    }
    
    init?(givenDataElements: [String]?, customConfigFileName: String?) {
        if givenDataElements == nil {
            return nil
        }
        
        let pathToConfigFile = customConfigFileName != nil ? Bundle.main.path(forResource: "isoconfig", ofType: "plist") : Bundle.main.path(forResource: customConfigFileName, ofType: "plist")
        let dataElementsScheme = NSDictionary(contentsOfFile: pathToConfigFile!)
        var bitmapTemplate = ISOHelper.stringToArray(string: "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")!
        
        for dataElement in givenDataElements! {
            if dataElement == "DE01" {
                print("You cannot add DE01 explicitly, its value is automatically inferred.")
                return nil
            }
            
            if dataElementsScheme?.object(forKey: dataElement) != nil {
                print("Cannot add \(dataElement) because it is not a valid data element defined in the ISO8583 standard or in the isoconfig.plist file or in your custom config file. Please visit http://en.wikipedia.org/wiki/ISO_8583#Data_elements to learn more about data elements.")
                return nil
            } else {
                // mark the data element on the bitmap
                let index = Int((dataElement as NSString).substring(from:2))! - 1
                bitmapTemplate[index] = "1"
            }
        }
        
        // Check if it has a secondary bitmap (contains DE65...DE128)
        for dataElement in givenDataElements! {
            let index = Int((dataElement as NSString).substring(from:2))! - 1
            
            if index > 63 {
                bitmapTemplate[index] = "1"
                hasSecondaryBitmap = true
                break
            }
            
            if hasSecondaryBitmap {
                rawValue = ISOHelper.arrayToString(array: bitmapTemplate)
                binaryBitmap = bitmapTemplate
            } else {
                let bitmapTemplateAsString = ISOHelper.arrayToString(array: bitmapTemplate)
                
                rawValue = String(bitmapTemplateAsString![..<bitmapTemplateAsString!.index(bitmapTemplateAsString!.startIndex, offsetBy: 64)])
                binaryBitmap = ISOHelper.stringToArray(string: rawValue)
            }
        }
    }
    
    convenience init?(givenDataElements: [String]?) {
        self.init(givenDataElements: givenDataElements, customConfigFileName: nil)
    }
    
    // MARK: Methods
    func bitmapAsBinaryString() -> String? {
        return isBinary ? rawValue : ISOHelper.hexToBinaryAsString(hexString: rawValue);
    }
    
    func bitmapAsHexString() -> String? {
        return !isBinary ? rawValue : ISOHelper.binaryToHexAsString(binaryString: rawValue);
    }
    
    func dataElementsInBitmap() -> [String]? {
        return dataElementsInBitmap(customConfigFileName: nil)
    }
    
    func dataElementsInBitmap(customConfigFileName: String?) -> [String]? {
        let pathToConfigFile = customConfigFileName == nil ? Bundle.main.path(forResource: "isoconfig", ofType: "plist") : Bundle.main.path(forResource: customConfigFileName, ofType: "plist")
        let dataElementsScheme = NSDictionary(contentsOfFile: pathToConfigFile!)
        var dataElements = [String]()
        
        for i in 0..<binaryBitmap!.count {
            let bit = binaryBitmap![i]
            
            if bit == "1" {
                let index = String(i);
                var key = String()
                
                if customConfigFileName != nil {
                    key = index.count == 1 ? "DE0\(i + 1)" : "DE\(i + 1)"
                } else {
                    let sortDescriptor = NSSortDescriptor(key: String(), ascending: true, comparator: {(object1: Any!, object2: Any!) -> ComparisonResult in
                        return (object1 as! String).compare((object2 as! String), options: .numeric)
                    })
                    let sortedKeys = (dataElementsScheme!.allKeys as NSArray).sortedArray(using: [sortDescriptor])
                    key = sortedKeys[i] as! String
                }
                
                if dataElementsScheme?.object(forKey: key) != nil {
                    dataElements.append(key)
                }
            }
        }
        
        return dataElements
    }
}
