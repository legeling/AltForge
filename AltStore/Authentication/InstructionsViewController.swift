//
//  InstructionsViewController.swift
//  AltStore
//
//  Created by Riley Testut on 9/6/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit

class InstructionsViewController: UIViewController
{
    var completionHandler: (() -> Void)?
    
    var showsBottomButton: Bool = false
    
    @IBOutlet private var contentStackView: UIStackView!
    @IBOutlet private var dismissButton: UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.view.backgroundColor = .systemGroupedBackground
        self.applySemanticTextColors(to: self.contentStackView)
        self.dismissButton.backgroundColor = .altPrimary
        self.dismissButton.setTitleColor(UIColor.altPrimary.contrastingForegroundColor, for: .normal)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemGroupedBackground
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        self.navigationController?.navigationBar.barStyle = .default
        self.navigationController?.navigationBar.tintColor = .altPrimary
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        if UIScreen.main.isExtraCompactHeight
        {
            self.contentStackView.layoutMargins.top = 0
            self.contentStackView.layoutMargins.bottom = self.contentStackView.layoutMargins.left
        }
        
        self.dismissButton.clipsToBounds = true
        self.dismissButton.layer.cornerRadius = 16
        
        if self.showsBottomButton
        {
            self.navigationItem.hidesBackButton = true
        }
        else
        {
            self.dismissButton.isHidden = true
        }
    }

    private func applySemanticTextColors(to view: UIView)
    {
        for subview in view.subviews
        {
            if let label = subview as? UILabel
            {
                if label.font.pointSize >= 60
                {
                    label.textColor = .tertiaryLabel
                }
                else if label.font.fontDescriptor.symbolicTraits.contains(.traitBold)
                {
                    label.textColor = .label
                }
                else
                {
                    label.textColor = .secondaryLabel
                }
            }

            self.applySemanticTextColors(to: subview)
        }
    }
}

private extension InstructionsViewController
{
    @IBAction func dismiss()
    {
        self.completionHandler?()
    }
}
