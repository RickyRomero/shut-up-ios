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
    }

    override func viewDidAppear(_ animated: Bool) {
        var osName = "iOS"
        if UIDevice.current.userInterfaceIdiom == .pad {
            osName = "iPadOS"
        }

        presentTutorialIfNecessary()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    func presentTutorialIfNecessary() {
        let tutorialAcknowledged: Bool? = UserDefaults.standard.bool(forKey: "TutorialAcknowledged")

        if (!tutorialAcknowledged!)
        {
            var modalStyle = UIModalPresentationStyle.overFullScreen
            if UIDevice.current.userInterfaceIdiom == .pad {
                modalStyle = .formSheet
            }

            let vc = storyboard?.instantiateViewController(withIdentifier: "SafariSettingsVc") as! SafariSettingsViewController
            vc.modalPresentationStyle = modalStyle
            present(vc, animated: true, completion: nil)
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

    func tableView(_ tableview: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }

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

    func handleQuickAction(_ type: String) {
        func showError(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)

            alert.view.tintColor = AppUtilities.sharedInstance.mainTintColor
            alert.addAction(okButton)
            present(alert, animated: true) { () -> Void in }
        }

        switch type {
            case "AddAction":
                self.domainField.becomeFirstResponder()
            case "PasteAction":
                guard let clipboardContents = UIPasteboard.general.string else {
                    showError(
                        title: "Clipboard is empty",
                        message: "Copy a link to your clipboard and try again."
                    )
                    return
                }

                let domainString = detectDomainNameInFullURLString(clipboardContents)
                guard !domainString.isEmpty else {
                    showError(
                        title: "URL not detected",
                        message: "Copy a link to your clipboard and try again."
                    )
                    return
                }

                guard !BlocklistController.sharedInstance.domainExistsInWhitelist(domainString) else {
                    showError(
                        title: "URL already whitelisted",
                        message: "\(domainString) is already set to show comments."
                    )
                    return
                }
                
                self.addDomainToTable(domainString)
            default: break
        }
    }

    @IBAction func userDidDismissKeyboard(_ sender: UISwipeGestureRecognizer) {
        self.currentResponder?.resignFirstResponder()
    }
}
