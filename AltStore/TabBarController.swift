//
//  TabBarController.swift
//  AltStore
//
//  Created by Riley Testut on 9/19/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

@preconcurrency import UIKit
import SwiftUI
import SpananiUI

extension TabBarController
{
    private enum Tab: Int, CaseIterable
    {
        case news
        case sources
        case browse
        case myApps
        case settings
    }
}

final class TabBarController: UITabBarController
{
    private var initialSegue: (identifier: String, sender: Any?)?
    
    private var _viewDidAppear = false
    
    private var sourcesViewController: SourcesViewController!
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.importApp(_:)), name: AppDelegate.importAppDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.presentSources(_:)), name: AppDelegate.addSourceDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.openErrorLog(_:)), name: ToastView.openErrorLogNotification, object: nil)
    }
    
    override func viewDidLoad() 
    {
        super.viewDidLoad()
        debugLog("[TabBarController] viewDidLoad()")
        
        let browseNavigationController = self.viewControllers![Tab.browse.rawValue] as! UINavigationController
        browseNavigationController.tabBarItem.image = UIImage(systemName: "bag")
        
        let sourcesNavigationController = self.viewControllers![Tab.sources.rawValue] as! UINavigationController
        self.sourcesViewController = sourcesNavigationController.viewControllers.first as? SourcesViewController

        #if !os(tvOS)
        SpananiFont.register()
        let host = UIHostingController(rootView: SpananiRoot(model: SpananiBridge.shared.model))
        host.view.backgroundColor = .clear
        addChild(host); host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view); host.didMove(toParent: self)
        tabBar.isHidden = true
        self.spananiHost = host
        SpananiBridge.shared.start()
        #endif
    }

    #if !os(tvOS)
    private var spananiHost: UIViewController?

    // The overlay can end up without the device's top/bottom safe area (content under the Dynamic Island): top it up from the window.
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        guard let host = self.spananiHost, let window = self.view.window else { return }
        let current = host.additionalSafeAreaInsets
        let derived = UIEdgeInsets(top: host.view.safeAreaInsets.top - current.top, left: 0, bottom: host.view.safeAreaInsets.bottom - current.bottom, right: 0)
        let needed = UIEdgeInsets(top: max(0, window.safeAreaInsets.top - derived.top), left: 0, bottom: max(0, window.safeAreaInsets.bottom - derived.bottom), right: 0)
        if needed != current { host.additionalSafeAreaInsets = needed }
    }
    #endif
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        debugLog("[TabBarController] viewDidAppear() — TabBarController is now visible")
        
        _viewDidAppear = true
        
        if let (identifier, sender) = self.initialSegue
        {
            self.initialSegue = nil
            self.performSegue(withIdentifier: identifier, sender: sender)
        }
    }
    
    override func performSegue(withIdentifier identifier: String, sender: Any?)
    {
        guard _viewDidAppear else {
            self.initialSegue = (identifier, sender)
            return
        }
        
        super.performSegue(withIdentifier: identifier, sender: sender)
    }
}

extension TabBarController
{
    @objc func presentSources(_ sender: Any)
    {
        if let presentedViewController = self.presentedViewController
        {
            presentedViewController.dismiss(animated: true) {
                self.presentSources(sender)
            }
            
            return
        }
                
        if let notification = (sender as? Notification), let sourceURL = notification.userInfo?[AppDelegate.addSourceDeepLinkURLKey] as? URL
        {
            self.sourcesViewController?.deepLinkSourceURL = sourceURL
        }
        
        self.selectedIndex = Tab.sources.rawValue
    }
}

private extension TabBarController
{
    @objc func importApp(_ notification: Notification)
    {
        self.selectedIndex = Tab.myApps.rawValue
    }

    @objc func openErrorLog(_ notification: Notification)
    {
        self.selectedIndex = Tab.settings.rawValue
    }
}
