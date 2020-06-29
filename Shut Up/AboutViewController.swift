//
//  AboutViewController.swift
//  Shut Up
//
//  Created by Ricky Romero on 7/11/15.
//  Copyright © 2015 Ricky Romero. All rights reserved.
//

import UIKit
import Alamofire

class AboutViewController: UIViewController {

    @IBOutlet var versionLabel: UILabel!
    @IBOutlet var stylesheetUpdateButton: UIButton!
    @IBOutlet var stylesheetUpdateSpinner: UIActivityIndicatorView!

    var requestTimer: Timer!
    var forceUpdater: StylesheetUpdate!
    var viewIsVisible = false
    var connectionIsRunning = false

    var connectionAlert: UIAlertController!

    override func viewDidLoad() {
        super.viewDidLoad()

        let version = UIApplication.versionBuild()

        versionLabel.text = "Version \(version)"

        self.stylesheetUpdateSpinner.isHidden = true

        self.connectionAlert = UIAlertController(title: "Connection failed", message: "Shut Up couldn't connect to rickyromero.com to update the stylesheet. Please check your Internet connection and try again.", preferredStyle: UIAlertController.Style.alert)
        self.connectionAlert.view.tintColor = AppUtilities.sharedInstance.mainTintColor
        self.connectionAlert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.viewIsVisible = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.viewIsVisible = false
        self.forceUpdater?.sessionManager?.session.invalidateAndCancel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapOSSButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "SegueToOSS", sender: sender)
    }

    @IBAction func didDismissView(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func didRequestStylsheetUpdate(_ sender: UIButton) {
        self.stylesheetUpdateButton.isEnabled = false
        self.stylesheetUpdateSpinner.isHidden = false
        self.stylesheetUpdateSpinner.startAnimating()
        self.connectionIsRunning = true

        self.requestTimer = Timer.scheduledTimer(timeInterval: 10.0,
                                                 target: self,
                                                 selector: #selector(AboutViewController.cancelRequest(_:)),
                                                 userInfo: nil,
                                                 repeats: false)

        // Hit the background thread for the download task.
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            self.forceUpdater = StylesheetUpdate(UIApplication.shared, performFetchWithCompletionHandler: { (result: UIBackgroundFetchResult) -> Void in
                // Get back on the main thread for the UI update.
                DispatchQueue.main.async {
                    let viewIsInWindowHierarchy = (self.isViewLoaded && (self.view.window != nil))
                    self.requestTimer.invalidate()

                    if viewIsInWindowHierarchy && self.connectionIsRunning // Check to make sure we haven't been dismissed
                    {
                        self.stylesheetUpdateButton.isEnabled = true
                        self.stylesheetUpdateSpinner.isHidden = true
                        self.stylesheetUpdateSpinner.stopAnimating()

                        self.connectionIsRunning = false

                        if result == UIBackgroundFetchResult.failed && self.viewIsVisible {
                            self.present(self.connectionAlert!, animated: true, completion: nil)
                        }
                    }
                }
            }, useEtag: false)
        }
    }

    @objc func cancelRequest(_ timer: Timer)
    {
        let viewIsInWindowHierarchy = (self.isViewLoaded && (self.view.window != nil))
        if viewIsInWindowHierarchy && self.connectionIsRunning // Check to make sure we haven't been dismissed
        {
            self.stylesheetUpdateButton.isEnabled = true
            self.stylesheetUpdateSpinner.isHidden = true
            self.stylesheetUpdateSpinner.stopAnimating()

            self.forceUpdater?.sessionManager?.session.invalidateAndCancel()
            self.connectionIsRunning = false

            if (self.viewIsVisible)
            {
                self.present(self.connectionAlert!, animated: true, completion: nil)
            }
        }
    }
}
