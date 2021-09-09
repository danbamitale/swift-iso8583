//
//  ISODataElement.swift
//  Swift-ISO8583
//
//  Created by Jorge Tapia on 3/15/15.
//  Copyright (c) 2015 Jorge Tapia. All rights reserved.
//

import Foundation

class ISODataElement {
    private(set) var name: String?
    private(set) var value: String?
    private(set) var dataType: String?
    private(set) var length: String?
    
    // MARK: Initializers
    init?(name: String, value: String, dataType: String, length: String, configFileName: String?) {
        if name.isEmpty {
            print("The name cannot be empty.")
            return nil
        }
        
        if dataType.isEmpty || dataType == "DE01" {
            print("DE01 is reserved for the bitmap and cannot be added through this method.")
            return nil;
        }
        
        if isValidDataType(dataType: dataType) {
            print("The data type \(dataType) is invalid. Please visit http://en.wikipedia.org/wiki/ISO_8583#Data_elements to learn more about data types.")
            return nil;
        }
        
        let pathToConfigFile = configFileName != nil ? Bundle.main.path(forResource: "isoconfig", ofType: "plist") : Bundle.main.path(forResource: configFileName, ofType: "plist")
        let dataElementsScheme = NSDictionary(contentsOfFile: pathToConfigFile!)!
        
        if dataElementsScheme.object(forKey: name) != nil {
            let dataElementLength = dataElementsScheme.value(forKeyPath: "\(name).length") as! String
            
            // validate with data type
            if !isValueCompliantWithDataType(value: value, dataType: dataType) {
                print("The value \"\(value)\" is not compliant with data type \"\(dataType)\"")
                return nil;
            }
            
            self.name = name
            self.dataType = dataType
            self.length = length
            
            // set value according to length and data type
            if dataType == "an" || dataType == "ans" && (length as NSString).range(of: ".").location == NSNotFound {
                self.value = ISOHelper.fillStringWithBlankSpaces(string: value, fieldLength: length)
            } else if dataType == "n" && (length as NSString).range(of: ".").location == NSNotFound {
                self.value = ISOHelper.fillStringWithZeroes(string: value, fieldLength: length)
            } else {
                // value has variable length
                if (length as NSString).range(of: ".").location != NSNotFound {
                    var maxLength = -1
                    var numberOfLengthDigits = -1
                    var trueLength = String()
                    
                    if (length.count == 2) {
                        let startIndex = length.index(after: length.startIndex)
                        maxLength = Int(length[startIndex...])!
                        numberOfLengthDigits = 1
                    } else if (length.count == 4) {
                        let startIndex = length.index(length.startIndex, offsetBy: 2)
                        maxLength = Int(length[startIndex...])!
                        numberOfLengthDigits = 2
                    } else if (length.count == 6) {
                        let startIndex = length.index(length.startIndex, offsetBy: 3)
                        maxLength = Int(length[startIndex...])!
                        numberOfLengthDigits = 3
                    }
                    
                    // validate length of value
                    if (value.count > maxLength) {
                        print("The value length \"\(value.count)\" is greater to the provided length \"\(length)\".")
                        return nil
                    }
                    
                    // fill with zeroes if needed
                    if numberOfLengthDigits == 1 {
                        trueLength = "\(value.count)"
                    }
                    
                    if numberOfLengthDigits == 2 && value.count < 10 {
                        trueLength = "0\(value.count)"
                    } else {
                        trueLength = "\(value.count)"
                    }
                    
                    if numberOfLengthDigits == 3 && value.count < 10 {
                        trueLength = "00\(value.count)"
                    } else if numberOfLengthDigits == 3 && value.count >= 10 && value.count < 100 {
                        trueLength = "0\(value.count)"
                    } else if numberOfLengthDigits == 3 && value.count >= 100 && value.count < 1000 {
                        trueLength = "\(value.count)"
                    }
                    
                    self.value = "\(trueLength)\(value)"
                } else {
                    // has no variable value
                    if value.count == Int(length) {
                        self.value = value;
                    } else {
                        print("The value \"\(value)\" length is not equal to the provided length \"\(length)\".");
                        return nil;
                    }
                }
            }
        } else {
            print("Cannot add \(name) because it is not a valid data element defined in the ISO8583 standard or in the isoconfig.plist file or in your custom config file. Please visit http://en.wikipedia.org/wiki/ISO_8583#Data_elements to learn more about data elements.")
            
            return nil;
        }
    }
    
    // MARK: Methods
    
    func getCleanValue() -> String? {
        var cleanValue: String? = nil
        let theLength = length! as NSString
        
        if theLength.range(of: ".").location != NSNotFound {
            var fromIndex = value!.index(after: value!.startIndex)
            
            if length!.count == 2 {
                cleanValue = String(value![fromIndex...])
            } else if length!.count == 4 {
                fromIndex = value!.index(value!.startIndex, offsetBy: 2)
                cleanValue = String(value![fromIndex...])
            } else if length!.count == 6 {
                fromIndex = value!.index(value!.startIndex, offsetBy: 3)
                cleanValue = String(value![fromIndex...])
            }
        } else {
            if dataType == "an" || dataType == "ans" {
                return value!.trimmingCharacters(in: .whitespaces)
            } else if dataType == "n" {
                let number = (value! as NSString).floatValue
                cleanValue = "\(number)";
            } else {
                cleanValue = value!
            }
        }
        
        return cleanValue
    }
    
    // MARK: Private methods
    
    private func isValidDataType(dataType: String) -> Bool {
        let pathToDataTypeConfigFile = Bundle.main.path(forResource: "isodatatypes", ofType: "plist")
        let validDataTypes = NSArray(contentsOfFile: pathToDataTypeConfigFile!)
        
        return validDataTypes?.index(of: dataType) ?? -2 > -1
    }
    
    private func isValueCompliantWithDataType(value: String, dataType: String) -> Bool {
        if dataType == "a" {
            let regExPattern = "[A-Za-z\\s]"
            let regEx = try? NSRegularExpression(pattern: regExPattern, options: .allowCommentsAndWhitespace)
            let regExMatches = regEx?.numberOfMatches(in: value, options: .anchored, range: NSMakeRange(0, value.count))
            
            if regExMatches != value.count {
                return false
            } else {
                return true
            }
        }
        
        if dataType == "n" {
            let regExPattern = "[0-9\\.]"
            let regEx = try? NSRegularExpression(pattern: regExPattern, options:.allowCommentsAndWhitespace)
            let regExMatches = regEx?.numberOfMatches(in: value, options: .anchored, range: NSMakeRange(0, value.count))
            
            if regExMatches != value.count {
                return false
            } else {
                return true
            }
        }
        
        if dataType == "s" {
            let regExPattern = "[^A-Za-z0-9\\s]"
            let regEx = try? NSRegularExpression(pattern: regExPattern, options: .allowCommentsAndWhitespace)
            let regExMatches = regEx?.numberOfMatches(in: value, options: .anchored, range: NSMakeRange(0, value.count))
            
            if regExMatches != value.count {
                return false
            } else {
                return true
            }
        }

        if dataType == "an" {
            let regExPattern = "[A-Za-z0-9\\s\\.]"
            let regEx = try? NSRegularExpression(pattern: regExPattern, options: .allowCommentsAndWhitespace)
            let regExMatches = regEx?.numberOfMatches(in: value, options: .anchored, range: NSMakeRange(0, value.count))
            
            if regExMatches != value.count {
                return false
            } else {
                return true
            }
        }
        
        if dataType == "as" {
            let regExPattern = "[A-Za-z0-9\\s\\W]"
            let regEx = try? NSRegularExpression(pattern: regExPattern, options: .allowCommentsAndWhitespace)
            let regExMatches = regEx?.numberOfMatches(in: value, options: .anchored, range: NSMakeRange(0, value.count))
            
            if regExMatches != value.count {
                return false
            } else {
                return true
            }
        }
        
        if dataType == "ans" {
            let regExPattern = "[A-Za-z0-9\\s\\W]"
            let regEx = try? NSRegularExpression(pattern: regExPattern, options: .allowCommentsAndWhitespace)
            let regExMatches = regEx?.numberOfMatches(in: value, options: .anchored, range: NSMakeRange(0, value.count))
            
            if regExMatches != value.count {
                return false
            } else {
                return true
            }
        }
        
        if dataType == "b" {
            let regExPattern = "[0-9A-F]"
            let regEx = try? NSRegularExpression(pattern: regExPattern, options: .allowCommentsAndWhitespace)
            let regExMatches = regEx?.numberOfMatches(in: value, options: .anchored, range: NSMakeRange(0, value.count))
            
            if regExMatches != value.count {
                return false
            } else {
                return true
            }
        }
        
        if dataType == "z" {
            // TODO: correctly validate type z
            return true
        }
        
        return false
    }
}
