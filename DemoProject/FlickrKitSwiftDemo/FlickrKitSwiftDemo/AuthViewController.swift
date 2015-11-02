//
//  AuthViewController.swift
//  FlickrKitSwiftDemo
//
//  Created by David Casserly on 02/11/2015.
//  Copyright © 2015 DevedUpLtd. All rights reserved.
//

import UIKit
import FlickrKitFramework

class AuthViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    override func viewWillAppear(animated: Bool) {
        // This must be defined in your Info.plist
        // See FlickrKitDemo-Info.plist
        // Flickr will call this back. Ensure you configure your flickr app as a web app
        let callbackURLString = "flickrkitdemo://auth"
        
        // Begin the authentication process
        let url = NSURL(string: callbackURLString)
        FlickrKit.sharedFlickrKit().beginAuthWithCallbackURL(url, permission: FKPermissionDelete, completion: { (url, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if ((error == nil)) {
                    let urlRequest = NSMutableURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 30)
                    self.webView.loadRequest(urlRequest)
                } else {
                    let alert = UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                }
            });
        })        
    }

    // MARK: WebViewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        //If they click NO DONT AUTHORIZE, this is where it takes you by default... maybe take them to my own web site, or show something else
        
        let url = request.URL
        
        // If it's the callback url, then lets trigger that
        if  !(url?.scheme == "http") && !(url?.scheme == "https") {
            if (UIApplication.sharedApplication().canOpenURL(url!)) {
                UIApplication.sharedApplication().openURL(url!)
                return false
            }
        }
        return true
        
    }
    
}
