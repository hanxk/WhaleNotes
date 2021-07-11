//
//  LocalFileUtil.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/7/11.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit

enum LocalFileConstants {
    static let imagePath = FileManager.getDocumentsDirectory().path + "/LocalFiles/NoteImages"
}

class LocalFileUtil {
    
//    private var _dirPath: URL!
//    var dirPath:URL {
//        return _dirPath
//    }
    static let shared = LocalFileUtil()

    func saveFileInfo(fileInfo:FileInfo) throws -> Bool  {
        let dirPath = LocalFileConstants.imagePath.stringByAppendingPath(fileInfo.fileId)
        try self.tryCreateDirPath(dirPath: dirPath)
        let filePath = dirPath.stringByAppendingPath(fileInfo.fileName)
        try self.createFile(fileURL: URL(fileURLWithPath: filePath), data: self.getImageData(fileInfo:fileInfo) )
        return true
    }
    
    func getFilePath(fileId:String,fileName:String) -> String {
        let path = "\(LocalFileConstants.imagePath)/\(fileId)/\(fileName)"
        return path
    }
    
    func getFilePathURL(fileId:String,fileName:String) -> URL {
        return URL(fileURLWithPath: getFilePath(fileId: fileId, fileName: fileName))
    }
}

extension LocalFileUtil {
    private func tryCreateDirPath(dirPath:String) throws {
        if !FileManager.default.directoryExists(atPath: dirPath) {
            try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    private func createFile(fileURL:URL,data:Data?) throws {
        guard let data = data else { return }
        try data.write(to: fileURL,
                           options: .atomic)
        logi("保存成功：\(fileURL.path)")
    }
    
    
    private func getImageData(fileInfo:FileInfo) -> Data? {
        let fileType = fileInfo.fileType.lowercased()
        if fileType == "png" {
            return fileInfo.image.pngData()
        }
        if fileType == "jpeg" || fileType == "jpg" {
            return fileInfo.image.jpegData(compressionQuality: 0.8)
        }
        return nil
    }
}


struct FileInfo {
    let fileId:String
    let fileName:String
    let fileType:String
    let image:UIImage
}
extension FileManager {

    func directoryExists(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = self.fileExists(atPath: path, isDirectory:&isDirectory)
        return exists && isDirectory.boolValue
    }
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
