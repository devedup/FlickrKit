//
//  ViewController.swift
//  FlickrKitSwiftDemo
//
//  Created by David Casserly on 14/10/2015.
//  Copyright © 2015 DevedUpLtd. All rights reserved.
//

import UIKit
import FlickrKitFramework

class ViewController: UIViewController {

    var photoURLs: [NSURL]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.photoURLs = []
    }

    @IBAction func showTodaysInterestingWasPressed(sender: AnyObject) {
        let flickrInteresting = FKFlickrInterestingnessGetList()
        flickrInteresting.per_page = "15"
        
        FlickrKit.sharedFlickrKit().call(flickrInteresting) { (response, error) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                if (response != nil) {
                    // Pull out the photo urls from the results
                    let topPhotos = response["photos"] as! [NSObject: AnyObject]
                    let photoArray = topPhotos["photo"] as! [[NSObject: AnyObject]]
                    for photoDictionary in photoArray {
                        let photoURL = FlickrKit.sharedFlickrKit().photoURLForSize(FKPhotoSizeSmall240, fromPhotoDictionary: photoDictionary)
                        self.photoURLs.append(photoURL)
                    }
                    self.performSegueWithIdentifier("SegueToPhotos", sender: self)
                    
                   // photoArray
                    
                    
                    //var photoURLS = response.map({$0["photos.photo"]! as [String: AnyObject]})
                    
                    
                    
                    /*
                    response.forEach({ () -> () in
                        
                    });
                    for (

                    for (NSDictionary *photoDictionary in [response valueForKeyPath:@"photos.photo"]) {
                        NSURL *url = [[FlickrKit sharedFlickrKit] photoURLForSize:FKPhotoSizeSmall240 fromPhotoDictionary:photoDictionary];
                        [photoURLs addObject:url];
                    }
                    
                    FKPhotosViewController *fivePhotos = [[FKPhotosViewController alloc] initWithURLArray:photoURLs];
                    [self.navigationController pushViewController:fivePhotos animated:YES];
                    
*/
                } else {
                    /*
                    Iterating over specific errors for each service

                    switch (error.code) {
                    case FKFlickrInterestingnessGetListError_ServiceCurrentlyUnavailable:
                        
                        break;
                    default:
                        break;
                    }
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [alert show];
*/
                }
            })
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "PhotosSegue") {
            let photosVC: PhotosViewController = segue.destinationViewController as! PhotosViewController
            photosVC.photoURLs = self.photoURLs
        }
    }

}

