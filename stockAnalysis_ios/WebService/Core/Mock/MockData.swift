//
//  MockData.swift
//  AECastle

import Foundation

class MockData {
    
    enum ReadLocalFileError: Error {
        case fileNameIsNotCorrect(String)
        case fileNameIsNotExists(String)
        case canNotConvertToData
    }
    
    static func fromJsonFile(fileName: String) throws -> Data {
        let splited = fileName.split(separator: ".")
        guard let subFileName = splited.first, let subType = splited.last else {
            throw ReadLocalFileError.fileNameIsNotCorrect("\(fileName) is not correct")
        }
        let fileName = String(subFileName)
        let type = String(subType)
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: type) else {
            throw ReadLocalFileError.fileNameIsNotCorrect("\(fileName).\(type) is not exists")
        }
        let fileURL = URL(fileURLWithPath: filePath)
        do {
            let fileData = try Data(contentsOf: fileURL)
            return fileData
        } catch {
            throw ReadLocalFileError.canNotConvertToData
        }
    }
}
