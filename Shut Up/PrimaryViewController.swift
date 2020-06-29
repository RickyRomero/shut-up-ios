//
//  PrimaryViewController.swift
//  Shut Up
//
//  Created by Ricky Romero on 7/12/15.
//  Copyright © 2015 Ricky Romero. All rights reserved.
//

import UIKit
import SafariServices
import KeyboardAdjuster


class PrimaryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var whitelistTableView: UITableView!
    @IBOutlet var addView: WhitelistAddView!
    @IBOutlet var domainField: UITextField!
    @IBOutlet var flexView: UIView!

    var currentResponder: UITextField?

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        BlocklistController.sharedInstance.readWhitelist()
        BlocklistController.sharedInstance.readBlocklistCSS()

        self.whitelistTableView.allowsMultipleSelectionDuringEditing = false;



        var bottomBoundaryConstraint: NSLayoutConstraint
        var keyboardTopConstraint: NSLayoutConstraint
        
        bottomBoundaryConstraint = flexView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottomBoundaryConstraint.isActive = true
        
        keyboardTopConstraint = flexView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor)
        keyboardTopConstraint.priority = UILayoutPriority(rawValue: 999)
        keyboardTopConstraint.isActive = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Clipboard listener
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(PrimaryViewController.getClipboardString(_:)),
                                                name: UIApplication.didBecomeActiveNotification,
                                                object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        let tutorialAcknowledged: Bool? = UserDefaults.standard.bool(forKey: "TutorialAcknowledged")

        if (!tutorialAcknowledged!)
        {
            self.performSegue(withIdentifier: "firstRunSafariSettings", sender: self)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc func getClipboardString(_ notification: Notification)
    {
        let tutorialAcknowledged: Bool? = UserDefaults.standard.bool(forKey: "TutorialAcknowledged")
        
        if (tutorialAcknowledged!)
        {
            if let clipboardContents = UIPasteboard.general.string
            {
                var domainString = ""
                if (detectDomainNameInFullURLString(clipboardContents) != "")
                {
                    domainString = detectDomainNameInFullURLString(clipboardContents)
                }
                
                if (domainString != "" && !BlocklistController.sharedInstance.domainExistsInWhitelist(domainString))
                {
                    let alert = UIAlertController(title: "URL detected", message: "It looks like you have a URL on your clipboard. Do you want to allow comments on " + domainString + "?", preferredStyle: UIAlertController.Style.alert)
                    
                    alert.view.tintColor = AppUtilities.sharedInstance.mainTintColor
                    let addAction = UIAlertAction(title: "Allow", style: UIAlertAction.Style.default) {
                        (UIAlertAction) -> Void in
                        
                        self.addDomainToTable(domainString)
                    }
                    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (UIAlertAction) -> Void in }
                    alert.addAction(cancelAction)
                    alert.addAction(addAction)
                    present(alert, animated: true) { () -> Void in }
                }
                else
                {
                    print("No URL detected.")
                }
            }
        }
    }

    func addDomainToTable(_ domain: String)
    {
        let index = BlocklistController.sharedInstance.addDomainToWhitelist(domain)

        if (index > -1)
        {
            self.flashField(UIColor(red: 0, green: 185 / 255, blue: 91 / 255, alpha: 1))

            self.whitelistTableView.insertRows(at: [IndexPath(row: index, section: 0)], with: UITableView.RowAnimation.automatic)

            self.domainField.text = ""
        }
        else
        {
            self.flashField(UIColor.red)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return BlocklistController.sharedInstance.whitelist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let tableIdentifier = "domainWhitelist"
        var cell = tableView.dequeueReusableCell(withIdentifier: tableIdentifier)

        if (cell == nil)
        {
            print("Creating a new cell.")
            cell = DomainTableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: tableIdentifier)
        }

        cell!.textLabel!.text = BlocklistController.sharedInstance.whitelist[indexPath.row]

        cell!.backgroundColor = cell!.contentView.backgroundColor

        return cell!
    }

    func tableView(_ tableview: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true;
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete
        {
            let domainToRemove = BlocklistController.sharedInstance.whitelist[indexPath.row]
            BlocklistController.sharedInstance.removeDomainFromWhitelist(domainToRemove)
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        }
    }

    @IBAction func userDidTapAddField(_ sender: WhitelistAddView) {
        self.domainField.becomeFirstResponder()
    }

    @IBAction func textFieldEditingDidBegin(_ sender: UITextField)
    {
        self.currentResponder = sender
        NSLog("Text field was tapped.")
    }

    @IBAction func didUpdateDomainName(_ sender: UITextField) {
        let value = sender.text!

        if (detectCorrectlyFormattedDomainName(value) != "")
        {
            print(detectCorrectlyFormattedDomainName(value))
        }
        else if (detectDomainNameInFullURLString(value) != "")
        {
            self.addView.showURLWarning()
            print(detectDomainNameInFullURLString(value))
        }
    }

    @IBAction func didReceiveDomainName(_ sender: UITextField) {
        let value = sender.text!
        print("Received Value: " + sender.text!)

        if (value == "")
        {
            self.currentResponder?.resignFirstResponder()
        }
        else
        {
            if (detectCorrectlyFormattedDomainName(value) != "")
            {
                addDomainToTable(detectCorrectlyFormattedDomainName(value))
            }
            else if (detectDomainNameInFullURLString(value) != "")
            {
                addDomainToTable(detectDomainNameInFullURLString(value))
            }
            else
            {
                self.flashField(UIColor.red)
            }
        }
    }

    @IBAction func editingDidEnd(_ sender: UITextField) {
        self.domainField.text = ""
    }

    func flashField(_ color: UIColor)
    {
        let oldColor = self.addView.layer.backgroundColor;
        self.addView.layer.backgroundColor = color.cgColor
        
        UIView.animate(withDuration: 0.5, animations: {
            self.addView.layer.backgroundColor = oldColor
        })
    }

    func detectDomainNameInFullURLString(_ unparsedURL: String) -> String
    {
        let url = URL(string: unparsedURL)
        
        if (url != nil)
        {
            if ((url!.scheme == "http" || url!.scheme == "https") && url!.host != nil)
            {
                return detectCorrectlyFormattedDomainName(url!.host!)
            }
        }

        return ""
    }

    func detectCorrectlyFormattedDomainName(_ domain: String) -> String
    {
        // First check: Is it the correct length?
        if (domain.count > 253)
        {
            print("Domain is too long.")
            return ""
        }
        
        // Second check: Does it have the correct number of dots?
        let subdivisions = domain.components(separatedBy: ".").count - 1;
        if (subdivisions < 1 || subdivisions > 126)
        {
            print("Too few (or many) subdivisions used.")
            return ""
        }

        // Final check: Does it pass a regex test?
        let domainNameRegex = try! NSRegularExpression(pattern: "^(?:[^\\.\\s\\:\\/\\?\\#]{1,63}\\.){1,126}[^\\.\\s\\:\\/\\?\\#]{1,63}$", options: NSRegularExpression.Options())
        let domainNameCount = domainNameRegex.numberOfMatches(in: domain,
            options: NSRegularExpression.MatchingOptions(),
            range: NSMakeRange(0, domain.count))

        if (domainNameCount == 0)
        {
            print("Didn't find a domain name.")
            return ""
        }

        return domain
    }

    @IBAction func userDidDismissKeyboard(_ sender: UISwipeGestureRecognizer) {
        self.currentResponder?.resignFirstResponder()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
