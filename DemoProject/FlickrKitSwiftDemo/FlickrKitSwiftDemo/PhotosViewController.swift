//
//  PhotosViewController.swift
//  FlickrKitSwiftDemo
//
//  Created by David Casserly on 14/10/2015.
//  Copyright © 2015 DevedUpLtd. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController {

    @IBOutlet weak var imageScrollView: UIScrollView!
    var photoURLs: [URL]!
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        for url in self.photoURLs {
            let urlRequest = URLRequest(url: url)
            NSURLConnection.sendAsynchronousRequest(urlRequest, queue: OperationQueue.main, completionHandler: { (response, data, error) -> Void in
                let image = UIImage(data: data!)
                self.addImageToView(image!)
            })
            
        }
    }

    func addImageToView(_ image: UIImage) {
        let imageView: UIImageView = UIImageView(image: image)
        let width = self.imageScrollView.frame.width
        let imageRatio = image.size.width / image.size.height
        let height = width / imageRatio
        let x: CGFloat = 0
        let y = self.imageScrollView.contentSize.height
        imageView.frame = CGRect(x: x, y: y, width: width, height: height)
        let newHeight: CGFloat = self.imageScrollView.contentSize.height + height
        self.imageScrollView.contentSize = CGSize(width: 320, height: newHeight)
        self.imageScrollView.addSubview(imageView)
    }
    
}
