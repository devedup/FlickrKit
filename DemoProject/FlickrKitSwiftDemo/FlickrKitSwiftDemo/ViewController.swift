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

    var photoURLs: [URL]!
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
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    // MARK: Interesting list using Flickr Model Objects
    
    @IBAction func showTodaysInterestingWasPressed(_ sender: AnyObject) {
        let flickrInteresting = FKFlickrInterestingnessGetList()
        flickrInteresting.per_page = "15"
        
        FlickrKit.shared().call(flickrInteresting) { (response, error) -> Void in
            
            DispatchQueue.main.async(execute: { () -> Void in
                if let response = response, let photoArray = FlickrKit.shared().photoArray(fromResponse: response) {
                    // Pull out the photo urls from the results
                    for photoDictionary in photoArray {
                        let photoURL = FlickrKit.shared().photoURL(for: FKPhotoSize.small240, fromPhotoDictionary: photoDictionary)
                        self.photoURLs.append(photoURL)
                    }
                    self.performSegue(withIdentifier: "SegueToPhotos", sender: self)
                } else {
                    // Iterating over specific errors for each service
                    if let error = error as? NSError {
                        switch error.code {
                        case FKFlickrInterestingnessGetListError.serviceCurrentlyUnavailable.rawValue:
                            break;
                        default:
                            break;
                        }
                        
                        let alert = UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
                        alert.show()
                    }
                }
            })
        }
        
    }
    
    // MARK: My photos using dictionary calls
    
    @IBAction func photostreamButtonPressed(_ sender: AnyObject) {
        if FlickrKit.shared().isAuthorized {
            FlickrKit.shared().call("flickr.photos.search", args: ["user_id": self.userID!, "per_page": "15"] , maxCacheAge: FKDUMaxAge.neverCache, completion: { (response, error) -> Void in
                
                DispatchQueue.main.async(execute: { () -> Void in
                    if let response = response, let photoArray = FlickrKit.shared().photoArray(fromResponse: response) {
                        for photoDictionary in photoArray {
                            let photoURL = FlickrKit.shared().photoURL(for: FKPhotoSize.small240, fromPhotoDictionary: photoDictionary)
                            self.photoURLs.append(photoURL)
                        }
                        self.performSegue(withIdentifier: "SegueToPhotos", sender: self)
                    }
                })
                
            })
        } else {
            let alert = UIAlertView(title: "Error", message: "Please login firs", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
    }
    
    // MARK: Authentication
    
    
    @IBAction func authButtonPressed(_ sender: AnyObject) {
        if(FlickrKit.shared().isAuthorized) {
            FlickrKit.shared().logout()
            self.userLoggedOut()
        } else {
            self.performSegue(withIdentifier: "SegueToAuth", sender: self)
        }
    }
    
    
    func checkAuthentication() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "UserAuthCallbackNotification"), object: nil, queue: OperationQueue.main) { (notification) -> Void in
            let callBackURL: URL = notification.object as! URL
            self.completeAuthOp = FlickrKit.shared().completeAuth(with: callBackURL, completion: { (userName, userId, fullName, error) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if ((error == nil)) {
                        self.userLoggedIn(userName!, userID: userId!)
                    } else {
                        let alert = UIAlertView(title: "Error", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
                        alert.show()
                    }
                    _ = self.navigationController?.popToRootViewController(animated: true)
                });
            })
        }
        
        // Check if there is a stored token - You should do this once on app launch
        self.checkAuthOp = FlickrKit.shared().checkAuthorization { (userName, userId, fullName, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if ((error == nil)) {
                    self.userLoggedIn(userName!, userID: userId!)
                } else {
                    self.userLoggedOut()
                }
            });
        }
    }
    
    func userLoggedIn(_ userName: String, userID: String) {
        self.userID = userID;
        self.authButton.setTitle("Logout", for: UIControlState())
        self.authLabel.text = "You are logged in as \(userName)"
    }
    
    func userLoggedOut() {
        self.authButton.setTitle("Login", for: UIControlState())
        self.authLabel.text = "Login to flickr"
    }
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "SegueToPhotos") {
            let photosVC: PhotosViewController = segue.destination as! PhotosViewController
            photosVC.photoURLs = self.photoURLs
        }
    }

}

