//
//  ImageGalleryDocument.swift
//  ImageGalleryPersistent
//
//  Created by sam hastings on 25/10/2023.
//

import UIKit

class ImageGalleryDocument: UIDocument {
    
    var imageGallery: ImageGallery?
    var thumbnail: UIImage?
    
    // Converts from model to data
    // This function reurns an "Any" and not a "Data", since this Any could represent a File wrapper i.e. a directory full of files
    override func contents(forType typeName: String) throws -> Any {
        // imageGallery is my model. Any time I want my controller to save my model, I take my controllers model and store it in this imageGallery model (i.e. the document).
        return imageGallery?.json ?? Data() // 49:48
    }
    
    // converts from data to model
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
        if let json = contents as? Data {
            imageGallery = ImageGallery(json: json)
        }
    }
    
    override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocument.SaveOperation) throws -> [AnyHashable : Any] {
        var attributes = try super.fileAttributesToWrite(to: url, for: saveOperation)
        if let thumbnail = self.thumbnail {
            attributes[URLResourceKey.thumbnailDictionaryKey] = [URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey: thumbnail]
        }
        return attributes
    }
}

