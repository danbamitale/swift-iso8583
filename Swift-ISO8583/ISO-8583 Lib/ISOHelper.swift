//
//  ISOHelper.swift
//  Swift-ISO8583
//
//  Created by Jorge Tapia on 3/15/15.
//  Copyright (c) 2015 Jorge Tapia. All rights reserved.
//

import Foundation

class ISOHelper {
    class func stringToArray(string: String?) -> [String]? {
        if string == nil {
            return nil
        }
        
        var chars = [String]()
        
        for char in string! {
            chars.append("\(char)")
        }
        
        return chars
    }
    
    class func arrayToString(array: [String]?) -> String? {
        if array == nil {
            return nil
        }
        
        var string = String()
        
        for char in array! {
            string.append(Character(char))
        }
        
        return string
    }
    
    class func hexToBinaryAsString(hexString: String?) -> String? {
        if hexString == nil {
            return nil
        }
        
        // Validate if it's a hexadecimal number
        let regExPattern = "[0-9A-F]"
        let regEx = try? NSRegularExpression(pattern: regExPattern, options: .allowCommentsAndWhitespace)
        let regExMatches = regEx?.numberOfMatches(in: hexString!, options: .anchored, range: NSMakeRange(0, hexString!.count))
        
        if regExMatches != hexString!.count {
            print("Parameter \(hexString) is an invalid hexadecimal number.")
            return nil;
        }
        
        let conversionTable = ["0": "0000", "1": "0001", "2": "0010", "3": "0011", "4": "0100", "5": "0101", "6": "0110", "7": "0111", "8": "1000", "9": "1001", "A": "1010", "B": "1011", "C": "1100", "D": "1101", "E": "1110", "F": "1111"]
        
        let hexArray = stringToArray(string: hexString)!
        var result = String()
        
        for hexNumber in hexArray {
            result += conversionTable[hexNumber]!
        }
        
        return result
    }
    
    class func binaryToHexAsString(binaryString: String?) -> String? {
        if binaryString == nil {
            return nil
        }
        
        // Validate if it's a binary number
        let regExPattern = "[0-1]"
        let regEx = try? NSRegularExpression(pattern: regExPattern, options: .allowCommentsAndWhitespace)
        let regExMatches = regEx?.numberOfMatches(in: binaryString!, options: .anchored, range: NSMakeRange(0, binaryString!.count))
        
        if regExMatches! != binaryString!.count {
            print("Parameter \(String(describing: binaryString)) is an invalid binary number.")
            return nil;
        }
        
        // Validate that length is correct (multiple of 4)
        if binaryString!.count % 4 != 0 {
            print("Invalid binary string length \(binaryString!.count). It must be multiple of 4.");
            return nil;
        }
        
        let conversionTable = ["0000": "0", "0001": "1", "0010": "2", "0011": "3", "0100": "4", "0101": "5", "0110": "6", "0111": "7", "1000": "8", "1001": "9", "1010": "A", "1011": "B", "1100": "C", "1101": "D", "1110": "E", "1111": "F"]
        
        let binaryArray = NSMutableArray(capacity: binaryString!.count/4)
        var result = String()
        
        
        for i in stride(from: 0, to: binaryString!.count, by: 4) {
            let substringFrom = (binaryString! as NSString).substring(from:i) as NSString
            let substringTo = substringFrom.substring(to:4)
                      
            binaryArray.add(substringTo)
            result += conversionTable[binaryArray.object(at: i / 4) as! String]!
        }
        
        return result
    }
    
    class func fillStringWithZeroes(string: String?, fieldLength: String?) -> String? {
        if string == nil {
            return nil
        }
        
        if fieldLength == nil {
            return nil
        }
        
        if (fieldLength! as NSString).range(of: ".").location != NSNotFound {
            print("The length format is not correct.")
            return string;
        }
        
        let trueLength = Int(fieldLength!)
        let regExPattern = "[0-9]"
        let regEx = try? NSRegularExpression(pattern: regExPattern, options: .allowCommentsAndWhitespace)
        let regExMatches = regEx?.numberOfMatches(in: string!, options: .anchored, range: NSMakeRange(0, string!.count))
        
        if regExMatches != string?.count {
            print("The string provided \"\(string)\" is not a numeric string and cannot be filled with zeroes (0).")
            return string
        }
        
        if string!.count >= trueLength! {
            return string
        }
        
        let zeroesNeeded = trueLength! - string!.count
        var result = String()
        
        for _ in 0..<zeroesNeeded {
            result += "0"
        }
        
        result += string!
        
        return result
    }
    
    class func fillStringWithBlankSpaces(string: String?, fieldLength: String?) -> String? {
        if string == nil {
            return nil
        }
        
        if fieldLength == nil {
            return nil
        }
        
        if (fieldLength! as NSString).range(of: ".").location != NSNotFound {
            print("The length format is not correct.")
            return string;
        }
        
        let trueLength = Int(fieldLength!)
        let regExPattern = "[A-Za-z0-9\\s]"
        let regEx = try? NSRegularExpression(pattern: regExPattern, options: .allowCommentsAndWhitespace)
        let regExMatches = regEx?.numberOfMatches(in: string!, options: .anchored, range: NSMakeRange(0, string!.count))
        
        if regExMatches != string!.count {
            print("The string provided \"\(string)\" is not an alphanumeric string and cannot be filled with blank spaces.")
            return string
        }
        
        if string!.count >= trueLength! {
            return string
        }
        
        let blankSpacesNeeded = trueLength! - string!.count
        var result = String()
        
        for i in 0..<blankSpacesNeeded {
            result += " "
        }
        
        return string! + result
    }
    
    class func limitStringWithQuotes(string: String?) -> String? {
        if string == nil {
            return nil
        }
        
        return "\"\(string)\""
    }
    
    class func trimString(string: String?) -> String? {
        if string == nil {
            return nil
        }
        
        return string?.trimmingCharacters(in: .whitespaces)
    }
}
