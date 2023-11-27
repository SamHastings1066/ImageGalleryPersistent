//
//  ImageGalleryViewController.swift
//  ImageGallery
//
//  Created by sam hastings on 11/10/2023.
//


// TODO: Fix memory leak issue - every time collection view items are rearranged the memory increases.

import UIKit

protocol ImageGalleryViewControllerDelegate {
    func imageGalleryViewController(didUpdateGallery gallery: ImageGallery)
}

class ImageGalleryViewController: UIViewController {
    
    // MARK: - Model
    
    var imageGallery: ImageGallery? 
    
    
    var document: ImageGalleryDocument? // set in DBVC
    
    @IBAction func save(_ sender: UIBarButtonItem? = nil) {
        document?.imageGallery = imageGallery
        if document?.imageGallery != nil {
            document?.updateChangeCount(.done)
        }

    }
    
    @IBAction func close(_ sender: UIBarButtonItem) {
        save()
        if (imageGallery?.images.count) ?? 0 > 0 {
            Task {
                if let thumbnailData = await imageGallery?.images[0].fetchData() {
                    document?.thumbnail = UIImage(data: thumbnailData)
                }
            }
        }

        
        dismiss(animated: true) {
            self.document?.close()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        document?.open() { success in
            if success {
                self.title = self.document?.localizedName
                self.imageGallery = self.document?.imageGallery
                self.imageGalleryCollectionView.reloadData()
            }
        }
    }
    
    
    
    // MARK: - Storyboard
    
    var cellWidth = 150.0
    
    var delegate: ImageGalleryViewControllerDelegate?
    
    
    @IBOutlet weak var imageGalleryCollectionView: UICollectionView! {
        didSet {
            imageGalleryCollectionView.dataSource = self
            imageGalleryCollectionView.delegate = self
            imageGalleryCollectionView.dragDelegate = self
            imageGalleryCollectionView.dropDelegate = self
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(zoomCollectionView(recognizer:)))
            imageGalleryCollectionView.addGestureRecognizer(pinch)
        }
    }
    
    @objc func zoomCollectionView(recognizer: UIPinchGestureRecognizer){
        switch recognizer.state {
        case .changed, .ended:
            cellWidth = max(min(cellWidth * recognizer.scale, imageGalleryCollectionView.frame.width), 75.0)
            flowLayout?.invalidateLayout()
        default: break
        }
    }
    
    
    
    /// Fetches a UIImage from the 'url' by making a network call on a background thread. If the image is successfully retrieved then a closure is called on the main thread to use that UIImage in the 'completion' closure handed to this function to update the UI.
    
    private func setImageViewImage(for cell: ImageCollectionViewCell, with image: UIImage) {
        DispatchQueue.main.async {
            cell.imageView.image = image
            cell.stopLoading()
        }
    }
    
    private func fetchImage(for cell: ImageCollectionViewCell, from url: URL) {
        cell.startLoading()
        let request = URLRequest(url: url)
        if let cachedResponse = URLCache.shared.cachedResponse(for: request), let image = UIImage(data: cachedResponse.data) {
            setImageViewImage(for: cell, with: image)
            print("Cached")
            return
        }
        // Move potentially time consuming network call to the background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let urlContents = try? Data(contentsOf: url), let image = UIImage(data: urlContents) {
                // Cache the fetched image
                let response = URLResponse(url: url, mimeType: nil, expectedContentLength: urlContents.count, textEncodingName: nil)
                let cachedReponse = CachedURLResponse(response: response, data: urlContents)
                URLCache.shared.storeCachedResponse(cachedReponse, for: request)
                
                self?.setImageViewImage(for: cell, with: image)
                print("Not Cached")
            } else {
                DispatchQueue.main.async {
                    cell.stopLoading()
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            //if let url = sender.
            if identifier == "imageSelectedSegue" {
                let destinationVC = segue.destination as? ImageViewController
                if let cell = sender as? UICollectionViewCell, let indexPath = imageGalleryCollectionView.indexPath(for: cell) {
                    destinationVC?.imageURL = imageGallery?.images[indexPath.item].imageURL
                }
                
            }
        }
    }   

    
    
}

// MARK: - Collection view extension

extension ImageGalleryViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDropDelegate, UICollectionViewDragDelegate {
    
    var flowLayout: UICollectionViewFlowLayout? {
        return imageGalleryCollectionView?.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageGallery?.images.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
        if let imageCell = cell as? ImageCollectionViewCell {
            if let url = imageGallery?.images[indexPath.item].imageURL {
                fetchImage(for: imageCell, from: url)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let aspectRatio = imageGallery?.images[indexPath.row].aspectRatio{
            return CGSize(width: cellWidth, height: cellWidth/aspectRatio)
        }
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    
    // MARK: - Dragging
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // This is somehting in the drag session that lets droppees know the drop came from the collection view itself
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        // 32:26 lecture 12
        // grab the image for the cell being dragged
        if let image = (imageGalleryCollectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell)?.imageView.image, let url = imageGallery?.images[indexPath.item].imageURL {
            let itemProvider = NSItemProvider()
            itemProvider.registerObject(image, visibility: .all)
            itemProvider.registerObject(url as NSURL, visibility: .all)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            // if the drag is local the next line prevents another nework call from being made to get the image
            dragItem.localObject = image
            return [dragItem]
        } else {
            return []
        }
        
    }
    
    
    // MARK: - Dropping
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        // Configure collectionView to only handle drops from objects with both UIImage and NSURL representations
        return session.canLoadObjects(ofClass: UIImage.self) && session.canLoadObjects(ofClass: NSURL.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        // the intent argument below allows you to choose whether to drop into a cell or to create a new cell when you drop
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
        
    }
    
    
    
    func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: UICollectionViewDropCoordinator
    ) {
        // The index path within the collectionView where we are dropping
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                // This drop is coming from myself (the collectionView)
                // 45:46 lecture 12
                collectionView.performBatchUpdates {
                    // update the imageGallery model by updating the order of the images
                    if let tempURL = imageGallery?.images.remove(at: sourceIndexPath.item) {
                        imageGallery?.images.insert(tempURL, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                        if let imageGallery = self.imageGallery {
                            self.delegate?.imageGalleryViewController(didUpdateGallery: imageGallery)
                        }
                    }
                }
            } else {
                // This drop is coming from outside the collection view
                // 50:30 lecture 12
                let placeholderContext = coordinator.drop(
                    item.dragItem,
                    to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell") // {closure to intialize the cell}
                )
                var newImage = Image()
                // Fetch the aspect ratio from the dropped image
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    if let image = provider as? UIImage {
                        newImage.aspectRatio = Double(image.size.width / image.size.height)
                    }
                }

                // Fetch the url and replace the placeholder cell once done/
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, error) in
                    DispatchQueue.main.async {
                        placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexpath in
                            // insert the URL into the model (imageGallery.images)
                            if let url = provider as? URL {
                                newImage.imageURL = url
                                self.imageGallery?.images.insert(newImage, at: insertionIndexpath.item)
                                if let imageGallery = self.imageGallery {
                                    self.delegate?.imageGalleryViewController(didUpdateGallery: imageGallery)
                                }
                            } else {
                                placeholderContext.deletePlaceholder()
                            }
                        })
                    }
                }
            }
        }
        // update the image gallery in the GallerySelector
        
    }
    
    
}
