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
    var photoURLs: [NSURL]!
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        for url in self.photoURLs {
            let urlRequest = NSURLRequest(URL: url)
            NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) -> Void in
                let image = UIImage(data: data!)
                self.addImageToView(image!)
            })
            
        }
    }

    func addImageToView(image: UIImage) {
        let imageView: UIImageView = UIImageView(image: image)
        let width = CGRectGetWidth(self.imageScrollView.frame)
        let imageRatio = image.size.width / image.size.height
        let height = width / imageRatio
        let x: CGFloat = 0
        let y = self.imageScrollView.contentSize.height
        imageView.frame = CGRectMake(x, y, width, height)
        let newHeight: CGFloat = self.imageScrollView.contentSize.height + height
        self.imageScrollView.contentSize = CGSizeMake(320, newHeight)
        self.imageScrollView.addSubview(imageView)
    }
    
}
