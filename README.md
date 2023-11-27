# ImageGallery

![ImageGallery Promo](image-gallery-promo.gif)

## Overview

ImageGallery is an iOS application built using UIKit. It leverages advanced iOS features allowing users to store and manage images from the internet. Users can drag and drop images into a CollectionView-based gallery. The application provides persistent document handling with full support for creating, naming, opening, and arranging Image Gallery documents.

## Features

### 🏗️ Architecture
- **Model-View-Controller**: This design approach was selected to delineate the Model from the View, thereby improving maintainability and scalability. It ensures a clean separation of concerns, making the application easier to extend and maintain.

### 👆 User Interaction
- **Drag and Drop**: Provides an intuitive interface for users to interact directly with images, enhancing user engagement and simplifying the UI.

### 🖼️ Layout and Presentation
- **CollectionView**: Utilizes a robust grid layout to present images in an organized manner, making optimal use of screen real estate.
- **ScrollView**: Empowers users with smooth navigation, allowing them to zoom and pan through galleries for a better viewing experience.

### ⚡ Performance and Efficiency
- **Multithreading**: Implements concurrent programming to manage image fetching and caching, ensuring that the UI remains responsive at all times.
- **URLCache**: Employed to cache images locally, which reduces network usage and provides a faster, seamless user experience even when offline.

### 💾 Data Management
- **Codable**: Used for its straightforward and efficient way of encoding and decoding model objects into JSON, simplifying data persistence.
- **FileManager**: Leveraged for its local document management capabilities, ensuring data persistence and document integrity.

### 📱iOS Framework Integration
- **UIDocument**: Integrates seamlessly with iOS's document model, providing a familiar and consistent document handling experience across iOS platforms.
- **UIDocumentBrowserViewController**: Offers a full document browsing experience, aligning with the native iOS file management workflow.



## Installation
Clone the repository and run it using Xcode. Ensure you have the latest version of Xcode and Swift.
