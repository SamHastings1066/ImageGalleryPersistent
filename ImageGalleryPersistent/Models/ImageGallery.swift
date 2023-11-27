//
//  ImageGallery.swift
//  ImageGallery
//
//  Created by sam hastings on 11/10/2023.
//

import Foundation

struct ImageGallery: Codable {
    
    /// The images that the image gallery will display
    var images = [Image]()
    
    /// The unique name of the image gallery
    var name: String!
    
    /// A json representation of the image gallery
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    init(images: [Image], name: String ) {
        self.images = images
        self.name = name
    }
    
    /// Intilaises an image gallery from its json representation
    init(json: Data) {
        if let newValue = try? JSONDecoder().decode(ImageGallery.self, from: json) {
            self = newValue
        } else {
            //print("New image Gallery created")
            self.init(images: [Image](), name: "New tings")
        }
    }
}
