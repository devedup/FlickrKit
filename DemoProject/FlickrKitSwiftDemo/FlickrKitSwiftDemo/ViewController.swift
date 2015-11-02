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
    var completeAuthOp: FKDUNetworkOperation!
    var checkAuthOp: FKDUNetworkOperation!
    var userID: String?
    @IBOutlet weak var authButton: UIButton!
    @IBOutlet weak var authLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.photoURLs = []
        
        self.checkAuthentication()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    // MARK: Interesting list using Flickr Model Objects
    
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
                } else {
                    // Iterating over specific errors for each service
                    switch error.code {
                    case FKFlickrInterestingnessGetListError.ServiceCurrentlyUnavailable.rawValue:
                        break;
                    default:
                        break;
                    }
                    
                    let alert = UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                }
            })
        }
        
    }
    
    // MARK: My photos using dictionary calls
    
    @IBAction func photostreamButtonPressed(sender: AnyObject) {
        if FlickrKit.sharedFlickrKit().authorized {
            FlickrKit.sharedFlickrKit().call("flickr.photos.search", args: ["user_id": self.userID!, "per_page": "15"] , maxCacheAge: FKDUMaxAgeNeverCache, completion: { (response, error) -> Void in
                
                let topPhotos = response["photos"] as! [NSObject: AnyObject]
                let photoArray = topPhotos["photo"] as! [[NSObject: AnyObject]]
                for photoDictionary in photoArray {
                    let photoURL = FlickrKit.sharedFlickrKit().photoURLForSize(FKPhotoSizeSmall240, fromPhotoDictionary: photoDictionary)
                    self.photoURLs.append(photoURL)
                }
                self.performSegueWithIdentifier("SegueToPhotos", sender: self)
            })
        } else {
            let alert = UIAlertView(title: "Error", message: "Please login firs", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    // MARK: Authentication
    
    
    @IBAction func authButtonPressed(sender: AnyObject) {
        if(FlickrKit.sharedFlickrKit().authorized) {
            FlickrKit.sharedFlickrKit().logout()
            self.userLoggedOut()
        } else {
            self.performSegueWithIdentifier("SegueToAuth", sender: self)
        }
    }
    
    
    func checkAuthentication() {
        NSNotificationCenter.defaultCenter().addObserverForName("UserAuthCallbackNotification", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            let callBackURL: NSURL = notification.object as! NSURL
            self.completeAuthOp = FlickrKit.sharedFlickrKit().completeAuthWithURL(callBackURL, completion: { (userName, userId, fullName, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if ((error == nil)) {
                        self.userLoggedIn(userName, userID: userId)
                    } else {
                        let alert = UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
                        alert.show()
                    }
                    self.navigationController?.popToRootViewControllerAnimated(true)
                });
            })
        }
        
        // Check if there is a stored token - You should do this once on app launch
        self.checkAuthOp = FlickrKit.sharedFlickrKit().checkAuthorizationOnCompletion { (userName, userId, fullName, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if ((error == nil)) {
                    self.userLoggedIn(userName, userID: userId)
                } else {
                    self.userLoggedOut()
                }
            });
        }
    }
    
    func userLoggedIn(userName: String, userID: String) {
        self.userID = userID;
        self.authButton.setTitle("Logout", forState: UIControlState.Normal)
        self.authLabel.text = "You are logged in as \(userName)"
    }
    
    func userLoggedOut() {
        self.authButton.setTitle("Login", forState: UIControlState.Normal)
        self.authLabel.text = "Login to flickr"
    }
    
    // MARK: Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "SegueToPhotos") {
            let photosVC: PhotosViewController = segue.destinationViewController as! PhotosViewController
            photosVC.photoURLs = self.photoURLs
        }
    }

}

