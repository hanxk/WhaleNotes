//
//  ImagesUtil.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/29.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit


class ImageUtil {
    
    private var _dirPath: URL!
    var dirPath:URL {
        return _dirPath
    }
    static let sharedInstance = ImageUtil()
    private init(){
        _dirPath = self.getDirPath()
    }
    
    func saveImage(key: String,imageExtension:String,image: UIImage) -> Bool {
        if let pngRepresentation = image.pngData() {
            do  {
                try pngRepresentation.write(to: URL.init(fileURLWithPath: filePath(forKey: key,imageExtension: imageExtension).absoluteString),
                                            options: .atomic)
                return true
            } catch let err {
                print("Saving file resulted in error: ", err)
                return false
            }
        }
        return false
    }
    
    
    func filePath(forKey key: String,imageExtension: String) -> URL {
        return _dirPath.appendingPathComponent(key + "."+imageExtension)
    }
    
    private func getDirPath() -> URL? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
//        let docURL =  URL(fileURLWithPath: documentsDirectory, isDirectory: true)
        let docURL = URL(string: documentsDirectory)!
        let dataPath = docURL.appendingPathComponent("LocalFiles/NoteImages")
        if !FileManager.default.fileExists(atPath: dataPath.absoluteString) {
            do {
                try FileManager.default.createDirectory(atPath: dataPath.absoluteString, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
        return dataPath
    }
    
    
    
}
