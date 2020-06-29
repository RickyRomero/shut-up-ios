//
//  SafariSettingsViewController.swift
//  Shut Up
//
//  Created by Ricky Romero on 9/14/15.
//  Copyright © 2015 Ricky Romero. All rights reserved.
//

import CoreGraphics
import QuartzCore
import UIKit

class SafariSettingsViewController: UIViewController {

    @IBOutlet var doneButton: UIButton!
    @IBOutlet var largeGearView: UIImageView!

    var rotationAnimation: CABasicAnimation!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _ = Timer.scheduledTimer(timeInterval: 3.0,
            target: self,
            selector: #selector(SafariSettingsViewController.timerDidEnd(_:)),
            userInfo: nil,
            repeats: false)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SafariSettingsViewController.enterBackground(_:)),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SafariSettingsViewController.returnToForeground(_:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runSpinAnimationOnView(largeGearView, duration: 1.0, rotations: 4 / 360, loop: Float.infinity)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func timerDidEnd(_ timer: Timer)
    {
        self.doneButton.isEnabled = true;
    }

    @IBAction func userDidDismissTutorial(_ sender: UIButton) {
        let userDefaults = UserDefaults.standard

        userDefaults.set(true, forKey: "TutorialAcknowledged")
        userDefaults.synchronize()

        self.dismiss(animated: true, completion: nil)
    }

    func runSpinAnimationOnView(_ view: UIImageView, duration: Double, rotations: Double, loop: Float)
    {
        self.rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        self.rotationAnimation.fromValue = NSNumber(value: Float(0.0) as Float)
        self.rotationAnimation.toValue = NSNumber(value: Float(Double.pi * 2.0 * rotations * duration) as Float)
        self.rotationAnimation.duration = duration
        self.rotationAnimation.isCumulative = true
        self.rotationAnimation.repeatCount = Float(loop)

        view.layer.add(self.rotationAnimation, forKey: "rotationAnimation")
    }

    @objc func returnToForeground(_ notification: Notification)
    {
        self.runSpinAnimationOnView(largeGearView, duration: 1.0, rotations: 4 / 360, loop: Float.infinity)
    }

    @objc func enterBackground(_ notification: Notification)
    {
        largeGearView.layer.removeAllAnimations()
    }
}
