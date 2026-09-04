//
//  AltAppIconsViewController.swift
//  AltStore
//
//  Created by Riley Testut on 2/14/24.
//  Copyright © 2024 Riley Testut. All rights reserved.
//

import UIKit
import SwiftUI

import AltStoreCore
import Roxas

extension UIApplication
{
    static let didChangeAppIconNotification = Notification.Name("io.altstore.AppManager.didChangeAppIcon")
}

private final class AltIcon: Decodable
{
    static let defaultIconName: String = "AppIcon"
    
    var name: String
    var imageName: String
    
    private enum CodingKeys: String, CodingKey
    {
        case name
        case imageName
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.imageName = try container.decode(String.self, forKey: .imageName)
    }
}

extension AltAppIconsViewController
{
    private enum Section: String, CaseIterable, Decodable, CodingKeyRepresentable
    {
        case glass
        
        var localizedName: String {
            NSLocalizedString("AltForge", comment: "")
        }
    }
}

class AltAppIconsViewController: UICollectionViewController
{
    private lazy var dataSource = self.makeDataSource()
    
    private var iconsBySection = [Section: [AltIcon]]()
    
    private var headerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewListCell>!
    private var isChangingIcon = false
    private var pendingIconName: String?
        
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Change App Icon", comment: "")
        
        let collectionViewLayout = self.makeLayout()
        self.collectionView.collectionViewLayout = collectionViewLayout

        self.collectionView.backgroundColor = .systemGroupedBackground
        self.collectionView.indicatorStyle = .default
        self.view.tintColor = .altPrimary

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemGroupedBackground
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        self.navigationItem.standardAppearance = appearance
        self.navigationItem.scrollEdgeAppearance = appearance
        
        do
        {
            let fileURL = Bundle.main.url(forResource: "AltIcons", withExtension: "plist")!
            let data = try Data(contentsOf: fileURL)
            
            let icons = try PropertyListDecoder().decode([Section: [AltIcon]].self, from: data)
            
            self.iconsBySection = icons
        }
        catch
        {
            Logger.main.error("Failed to load alternate icons. \(error.localizedDescription, privacy: .public)")
        }
        
        self.dataSource.proxy = self
        self.collectionView.dataSource = self.dataSource
        
        self.collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: RSTCellContentGenericCellIdentifier)
        self.collectionView.register(UICollectionViewListCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: UICollectionView.elementKindSectionHeader)
                
        self.headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { (headerView, elementKind, indexPath) in
            let section = Section.allCases[indexPath.section]

            var configuration = UIListContentConfiguration.groupedHeader()
            configuration.text = section.localizedName
            configuration.textProperties.color = .secondaryLabel
            headerView.contentConfiguration = configuration
            
            headerView.backgroundConfiguration = .clear()
        }
    }
}

private extension AltAppIconsViewController
{
    func makeLayout() -> UICollectionViewCompositionalLayout
    {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.showsSeparators = true
        configuration.backgroundColor = .clear
        configuration.headerMode = .supplementary
                
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        return layout
    }
    
    func makeDataSource() -> RSTCompositeCollectionViewDataSource<AltIcon>
    {
        let dataSources = Section.allCases.compactMap { self.iconsBySection[$0] }.filter { !$0.isEmpty }.map { icons in
            let dataSource = RSTArrayCollectionViewDataSource(items: icons)
            return dataSource
        }
        
        let dataSource = RSTCompositeCollectionViewDataSource(dataSources: dataSources)
        dataSource.cellConfigurationHandler = { [weak self] cell, icon, indexPath in
            let cell = cell as! UICollectionViewListCell
            
            let imageWidth = 44.0

            var config = cell.defaultContentConfiguration()
            config.text = NSLocalizedString(icon.name, comment: "Alternate app icon name")
            config.textProperties.color = .label
            
            let image = UIImage(named: icon.imageName)
            config.image = image
            config.imageProperties.maximumSize = CGSize(width: imageWidth, height: imageWidth)
            config.imageProperties.cornerRadius = imageWidth / 5.0 // Copied from AppIconImageView
            
            cell.contentConfiguration = config

            if self?.pendingIconName == icon.imageName
            {
                let activityIndicator = UIActivityIndicatorView(style: .medium)
                activityIndicator.color = .altPrimary
                activityIndicator.startAnimating()
                cell.accessories = [.customView(configuration: .init(customView: activityIndicator, placement: .trailing(), tintColor: .altPrimary))]
                cell.accessibilityValue = NSLocalizedString("Applying…", comment: "App icon change in progress")
                cell.accessibilityTraits.remove(.selected)
            }
            else if UIApplication.shared.alternateIconName == icon.imageName || (UIApplication.shared.alternateIconName == nil && icon.imageName == AltIcon.defaultIconName)
            {
                cell.accessories = [.checkmark(options: .init(tintColor: .altPrimary))]
                cell.accessibilityValue = NSLocalizedString("Selected", comment: "Accessibility value for the selected app icon")
                cell.accessibilityTraits.insert(.selected)
            }
            else
            {
                cell.accessories = []
                cell.accessibilityValue = nil
                cell.accessibilityTraits.remove(.selected)
            }
                      
            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColorTransformer = UIConfigurationColorTransformer { [weak cell] _ in
                if let state = cell?.configurationState, state.isHighlighted || state.isSelected
                {
                    return .tertiarySystemFill
                }

                return .secondarySystemGroupedBackground
            }
            cell.backgroundConfiguration = backgroundConfiguration
        }
        
        return dataSource
    }
}

extension AltAppIconsViewController
{
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
    {
        let headerView = self.collectionView.dequeueConfiguredReusableSupplementary(using: self.headerRegistration, for: indexPath)
        return headerView
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        guard !self.isChangingIcon else
        {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }

        let icon = self.dataSource.item(at: indexPath)
        let currentIconName = UIApplication.shared.alternateIconName ?? AltIcon.defaultIconName
        guard currentIconName != icon.imageName else
        {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }

        self.isChangingIcon = true
        self.pendingIconName = icon.imageName
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reconfigureItems(at: [indexPath])
        UISelectionFeedbackGenerator().selectionChanged()
        
        // If assigning primary icon, pass "nil" as alternate icon name.
        let imageName = (icon.imageName == AltIcon.defaultIconName) ? nil : icon.imageName
        UIApplication.shared.setAlternateIconName(imageName) { error in
            DispatchQueue.main.async {
                self.isChangingIcon = false
                self.pendingIconName = nil

                let affectedIconNames = [currentIconName, icon.imageName]
                let affectedIndexPaths = collectionView.indexPathsForVisibleItems.filter { indexPath in
                    affectedIconNames.contains(self.dataSource.item(at: indexPath).imageName)
                }
                collectionView.reconfigureItems(at: affectedIndexPaths)

                if let error
                {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    let alertController = UIAlertController(title: NSLocalizedString("Unable to Change App Icon", comment: ""),
                                                            message: error.userFacingPresentation.combinedMessage,
                                                            preferredStyle: .alert)
                    alertController.addAction(.ok)
                    self.present(alertController, animated: true)
                }
                else
                {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    NotificationCenter.default.post(name: UIApplication.didChangeAppIconNotification, object: icon)
                }
            }
        }
    }
}

@available(iOS 17, *)
#Preview(traits: .portrait) {
    let altAppIconsViewController = AltAppIconsViewController(collectionViewLayout: UICollectionViewFlowLayout())
    
    let navigationController = UINavigationController(rootViewController: altAppIconsViewController)
    return navigationController
}
