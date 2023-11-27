//
//  Image.swift
//  ImageGallery
//
//  Created by sam hastings on 13/10/2023.
//

import Foundation

struct Image: Codable {
    
    /// The URL of the image
    var imageURL: URL?
    
    /// The ratio of the cell's width to its height
    var aspectRatio: Double?

    func fetchData() async -> Data? {
        if let imageURL = imageURL {
            let request = URLRequest(url: imageURL)
            //Retreive thumbnail from cache
            if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
                print("Retreiving thumbnail from cache")
                return cachedResponse.data
            }
            // the code below can be commented out because the thumbnail data should already be stored in the cache when the image was first downloaded
//            if let data = try? Data(contentsOf: imageURL) {
//                let response = URLResponse(url: imageURL, mimeType: nil, expectedContentLength: data.count, textEncodingName: nil)
//                let cachedResponse = CachedURLResponse(response: response, data: data)
//                print("Adding thumbnail to cache")
//                URLCache.shared.storeCachedResponse(cachedResponse, for: request)
//                return data
//            }
        }
        return nil
    }
}
