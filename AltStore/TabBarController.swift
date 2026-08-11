//
//  TabBarController.swift
//  AltStore
//
//  Created by Riley Testut on 9/19/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit
import SwiftUI

import AltStoreCore

extension TabBarController
{
    private enum Tab: Int, CaseIterable
    {
        case browse
        case sources
        case myApps
        case settings
    }
}

class TabBarController: UITabBarController
{
    private var initialSegue: (identifier: String, sender: Any?)?
    
    private var _viewDidAppear = false
    
    private var sourcesViewController: SourcesViewController!
    private var featuredViewController: FeaturedViewController!
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.openPatreonSettings(_:)), name: AppDelegate.openPatreonSettingsDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.importApp(_:)), name: AppDelegate.importAppDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.presentSources(_:)), name: AppDelegate.addSourceDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.openErrorLog(_:)), name: ToastView.openErrorLogNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.openBrowseTab(_:)), name: AppDelegate.searchDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.viewApp(_:)), name: AppDelegate.viewAppDeepLinkNotification, object: nil)
    }
    
    override func viewDidLoad() 
    {
        super.viewDidLoad()

        self.delegate = self
        self.applyTheme()

        guard let viewControllers, viewControllers.count == Tab.allCases.count else { return }

        let browseNavigationController = viewControllers[Tab.browse.rawValue] as! UINavigationController
        browseNavigationController.tabBarItem.image = UIImage(systemName: "bag")
        browseNavigationController.tabBarItem.selectedImage = UIImage(systemName: "bag.fill")
        self.featuredViewController = browseNavigationController.viewControllers.first as? FeaturedViewController

        let sourcesNavigationController = viewControllers[Tab.sources.rawValue] as! UINavigationController
        sourcesNavigationController.tabBarItem.image = UIImage(systemName: "square.stack.3d.up")
        sourcesNavigationController.tabBarItem.selectedImage = UIImage(systemName: "square.stack.3d.up.fill")
        self.sourcesViewController = sourcesNavigationController.viewControllers.first as? SourcesViewController

        let myAppsNavigationController = viewControllers[Tab.myApps.rawValue] as! UINavigationController
        myAppsNavigationController.tabBarItem.image = UIImage(systemName: "square.grid.2x2")
        myAppsNavigationController.tabBarItem.selectedImage = UIImage(systemName: "square.grid.2x2.fill")

        let settingsNavigationController = viewControllers[Tab.settings.rawValue] as! UINavigationController
        settingsNavigationController.tabBarItem.image = UIImage(systemName: "gearshape")
        settingsNavigationController.tabBarItem.selectedImage = UIImage(systemName: "gearshape.fill")
        
        #if MARKETPLACE
        if #available(iOS 18, *)
        {
            let hostingController = UIHostingController(rootView: AppTrackerView(tracker: AppMarketplace.shared.tracker))
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostingController.view.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
            hostingController.view.alpha = 0.0
            self.addChild(hostingController)
            self.view.insertSubview(hostingController.view, at: 0)
            hostingController.didMove(toParent: self)
        }
        #endif
    }
    
    func applyTheme()
    {
        guard self.isViewLoaded else { return }

        let tintColor = UIColor.altPrimary
        self.view.tintColor = tintColor
        self.tabBar.tintColor = tintColor

        for case let navigationController as UINavigationController in self.viewControllers ?? []
        {
            navigationController.navigationBar.tintColor = tintColor
        }

        self.featuredViewController?.collectionView.reloadData()
        self.sourcesViewController?.collectionView.reloadData()

        if let myAppsNavigationController = self.viewControllers?[Tab.myApps.rawValue] as? UINavigationController,
           let myAppsViewController = myAppsNavigationController.viewControllers.first as? MyAppsViewController,
           myAppsViewController.isViewLoaded
        {
            myAppsViewController.collectionView.reloadData()
        }

        if let settingsNavigationController = self.viewControllers?[Tab.settings.rawValue] as? UINavigationController,
           let settingsViewController = settingsNavigationController.viewControllers.first as? SettingsViewController,
           settingsViewController.isViewLoaded
        {
            settingsViewController.view.tintColor = tintColor
            settingsViewController.tableView.reloadData()
        }

        if #available(iOS 15, *)
        {
            let appearance = self.tabBar.standardAppearance
            appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = tintColor
            self.tabBar.standardAppearance = appearance
            self.tabBar.scrollEdgeAppearance = appearance
        }
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        _viewDidAppear = true
        
        if let (identifier, sender) = self.initialSegue
        {
            self.initialSegue = nil
            self.performSegue(withIdentifier: identifier, sender: sender)
        }
        else if let patchedApps = UserDefaults.standard.patchedApps, !patchedApps.isEmpty
        {
            // Check if we need to finish installing untethered jailbreak.
            let activeApps = InstalledApp.fetchActiveApps(in: DatabaseManager.shared.viewContext)
            guard let patchedApp = activeApps.first(where: { patchedApps.contains($0.bundleIdentifier) }) else { return }
            
            self.performSegue(withIdentifier: "finishJailbreak", sender: patchedApp)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        guard let identifier = segue.identifier else { return }
        
        switch identifier
        {
        case "finishJailbreak":
            guard let installedApp = sender as? InstalledApp else { return }
            
            let navigationController = segue.destination as! UINavigationController
            
            let patchViewController = navigationController.viewControllers.first as! PatchViewController
            patchViewController.installedApp = installedApp
            patchViewController.completionHandler = { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }
            
        default: break
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

extension TabBarController: UITabBarControllerDelegate
{
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool
    {
        guard let index = tabBarController.viewControllers?.firstIndex(of: viewController),
              let tab = Tab(rawValue: index)
        else { return true }

        switch tab
        {
        case .browse: AppLifecycleDiagnosticStore.shared.record(.browse)
        case .sources: AppLifecycleDiagnosticStore.shared.record(.sources)
        case .myApps: AppLifecycleDiagnosticStore.shared.record(.myAppsOpening)
        case .settings: AppLifecycleDiagnosticStore.shared.record(.settings)
        }

        return true
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
            self.loadViewIfNeeded() // Initialize sourcesViewController
            self.sourcesViewController?.deepLinkSourceURL = sourceURL
        }
        
        self.selectedIndex = Tab.sources.rawValue
    }
}

private extension TabBarController
{
    @objc func openPatreonSettings(_ notification: Notification)
    {
        self.selectedIndex = Tab.settings.rawValue
    }
    
    @objc func importApp(_ notification: Notification)
    {
        self.selectedIndex = Tab.myApps.rawValue
    }
    
    @objc func openErrorLog(_ notification: Notification)
    {
        self.selectedIndex = Tab.settings.rawValue
    }
    
    @objc func openBrowseTab(_ notification: Notification)
    {
        self.selectedIndex = Tab.browse.rawValue
        
        if let query = notification.userInfo?[AppDelegate.searchDeepLinkQueryKey] as? String
        {
            self.featuredViewController.loadViewIfNeeded()
            self.featuredViewController.searchController.searchBar.text = query
            
            self.featuredViewController.navigationController?.popToRootViewController(animated: false)
            
            // Slight delay to ensure the search controller is actually presented (YOLO).
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.featuredViewController.searchController.isActive = true
                self.featuredViewController.searchController.updateSearchResults(for: self.featuredViewController.searchController)
            }
        }
    }
    
    @objc func viewApp(_ notification: Notification)
    {
        self.selectedIndex = Tab.browse.rawValue
        
        if let presentedViewController = self.presentedViewController
        {
            presentedViewController.dismiss(animated: true) {
                self.viewApp(notification)
            }
            
            return
        }
        
        guard let storeApp = notification.userInfo?[AppDelegate.viewAppDeepLinkStoreAppKey] as? StoreApp else { return }
        
        let appViewController = AppViewController.makeAppViewController(app: storeApp)
        self.featuredViewController.navigationController?.pushViewController(appViewController, animated: true)
    }
}
