//
//  SAStickyHeaderViewController.swift
//  SAStickyHeader
//
//  Created by Stefan Arambasich on 9/17/2015.
//  Copyright (c) 2015 Stefan Arambasich. All rights reserved.
//

import UIKit

/**
    Class implementing a sticky header layout.
*/
open class SAStickyHeaderViewController: UIViewController, UIScrollViewDelegate {

    /// The header view itself, or the behind view
    @IBOutlet open weak var headerView: UIView?
    /// The scroll view containing our content, or the front view.
    @IBOutlet open weak var scrollView: UIScrollView?
    
    /// Default header height - how tall to set the header view
    /// when the scroll offset is zero.
    open var headerHeightDefault: CGFloat = 192.0
    
    /// Whether to hide the navigation bar when the top of the table
    /// view content is reached via scrolling
    open var hidesNavigationBar: Bool = true {
        didSet {
            if hidesNavigationBar {
                if let scrollView = scrollView {
                    scrollViewDidScroll(scrollView)
                }
            } else {
                navigationController?.navigationBar.alpha = 1.0
            }
        }
    }
    
    /// The constraint dictating the height of the header view
    var headerHeightConstraint: NSLayoutConstraint! {
        guard let constraint = headerView?.constraints.filter({
            $0.firstItem === self.headerView &&
                $0.firstAttribute == .height
        }).first else {
            return nil
        }

        return constraint
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        configureViews()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stopKeyboardSupport()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        configureKeyboardSupport()
    }

    @objc func keyboardWillBeHidden(_ notification: Notification) {
        guard let scrollView = scrollView, let userInfo = notification.userInfo as? [String: AnyObject],
            let _ = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey]?.cgRectValue else {
                return
        }

        scrollView.contentInset =
            UIEdgeInsets(top: headerHeightDefault, left: 0.0, bottom: 0.0, right: 0.0)
        scrollView.frame = CGRect(x: scrollView.frame.origin.x, y: scrollView.frame.origin.y,
                                  width: scrollView.frame.size.width,
                                  height: view.frame.size.height - keyboardFrame.size.height)
    }

    @objc func keyboardWillBeShown(_ notification: Notification) {
        scrollView?.contentInset =
            UIEdgeInsets(top: headerHeightDefault, left: 0.0, bottom: 0.0, right: 0.0)
    }
}

private extension SAStickyHeaderViewController {

    /**
        Finalizes and sets all views to their 'initial' state.
    */
     func configureViews() {
        if headerView?.superview != view {
            view.addSubview(headerView!)
        }
        
        if scrollView?.superview != view {
            view.addSubview(scrollView!)
        }
        
        if headerHeightConstraint == nil {
            if let headerView = headerView {
                let c = NSLayoutConstraint(item: headerView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: headerHeightDefault)
                headerView.addConstraint(c)
            }
        }

        scrollView?.contentInset = UIEdgeInsets(top: headerHeightDefault, left: 0.0, bottom: 0.0, right: 0.0)
        scrollView?.contentOffset = CGPoint(x: 0.0, y: -headerHeightDefault)
        scrollView?.delegate = self
        
        if let scrollView = scrollView {
            scrollViewDidScroll(scrollView)
        }
    }

    // MARK: Keyboard
    func configureKeyboardSupport() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillBeShown(_:)),
                                               name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillBeHidden(_:)),
                                               name: .UIKeyboardWillHide, object: nil)
    }

    func stopKeyboardSupport() {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Navigation bar
    func setNavigationBarAlpha(withOffset deltaUnits: CGFloat) {
        guard hidesNavigationBar else {
            navigationController?.navigationBar.alpha = 1.0
            return
        }

        let alpha: CGFloat
        switch deltaUnits {
        case -CGFloat.greatestFiniteMagnitude ..< headerHeightDefault - 64.0:
            alpha = 0.0
        case headerHeightDefault - 64.0 ..< headerHeightDefault:
            alpha = 1.0 - ((headerHeightDefault - deltaUnits) / 64.0)
        default:
            alpha = 1.0
        }

        navigationController?.navigationBar.alpha = alpha
    }

}

// MARK: - UIScrollViewDelegate
extension SAStickyHeaderViewController {

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else { return }

        let deltaUnits = scrollView.contentOffset.y + headerHeightDefault,
        height = max(0, min(headerHeightDefault - deltaUnits, headerHeightDefault - deltaUnits))
        headerHeightConstraint.constant = height
        setNavigationBarAlpha(withOffset: deltaUnits)
    }
}
