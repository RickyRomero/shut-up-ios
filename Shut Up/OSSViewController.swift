//
//  OSSViewController.swift
//  Shut Up
//
//  Created by Ricky Romero on 7/11/15.
//  See LICENSE.md for license information.
//

import UIKit

class OSSViewController: UIViewController, NSLayoutManagerDelegate {
    @IBOutlet var attributionTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        attributionTextView.layoutManager.delegate = self

        let fileLocation = Bundle.main.path(forResource: "Acknowledgments", ofType: "txt")
        let text: String

        do
        {
            text = try String(contentsOfFile: fileLocation!)
        }
        catch
        {
            print(error)
            text = ""
        }

        attributionTextView.contentInset.top = 20

        attributionTextView.text = text
        attributionTextView.textColor = UIColor(white: 1.0, alpha: 1.0)
        attributionTextView.isScrollEnabled = false // HACK: Scroll view scrolls down when we add content to it
    }

    override func viewDidAppear(_ animated: Bool) {
        attributionTextView.isScrollEnabled = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func layoutManager(_ layoutManager: NSLayoutManager, lineSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
        return 7
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
