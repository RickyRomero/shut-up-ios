//
//  AboutViewController.swift
//  Shut Up
//
//  Created by Ricky Romero on 7/11/15.
//  Copyright © 2015 Ricky Romero. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet var versionLabel: UILabel!
    @IBOutlet var stylesheetUpdateButton: UIButton!
    @IBOutlet var stylesheetUpdateSpinner: UIActivityIndicatorView!

    var forceUpdater: StylesheetUpdate!
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

        self.forceUpdater = StylesheetUpdate(UIApplication.shared, performFetchWithCompletionHandler: { (result: UIBackgroundFetchResult) -> Void in
            DispatchQueue.main.async { [weak self] in
                guard let me = self else { return }

                me.stylesheetUpdateButton.isEnabled = true
                me.stylesheetUpdateSpinner.isHidden = true
                me.stylesheetUpdateSpinner.stopAnimating()

                if result == .failed {
                    me.present(me.connectionAlert, animated: true, completion: nil)
                }
            }
        }, useEtag: false)
    }
}
