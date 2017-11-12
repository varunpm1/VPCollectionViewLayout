//
//  VPCollectionViewLayout.swift
//  VPCollectionViewLayoutExample
//
//  Created by Varun P M on 05/11/17.
//  Copyright © 2017 Varun P M. All rights reserved.
//

import UIKit

class VPCollectionViewLayout: UICollectionViewFlowLayout {
    // Enum that contains all possible combination of layout type
    enum CollectionViewLayoutType {
        case vertical
    }
    
    /// Set the required layout type from the defined set of types. Defaults to vertical
    var layoutType: CollectionViewLayoutType = .vertical
    
    // Stored calculated attributes for caching purpose
    private var layoutAttributes: [UICollectionViewLayoutAttributes] = []
    private var maxContentHeight: CGFloat = 0
    
    override func prepare() {
        layoutAttributes.removeAll()
        calculateLayoutAttributes()
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: collectionView!.bounds.size.width, height: maxContentHeight)
    }
    
    // Calculate the attributes when invalidating layout
    private func calculateLayoutAttributes() {
        guard let collectionView = collectionView else {
            return
        }
        
        for sectionIndex in stride(from: 0, to: collectionView.numberOfSections, by: 1) {
            // Fetch the default values for spacing, if set
            var defaultSectionInsets: UIEdgeInsets = sectionInset
            var defaultInterItemSpacing: CGFloat = minimumInteritemSpacing
            var defaultLineSpacing: CGFloat = minimumLineSpacing
            
            if let delagteFlowLayout = collectionView.delegate as? UICollectionViewDelegateFlowLayout {
                // Get the insets from the controller/view if the insets delegate has been implemented
                if delagteFlowLayout.responds(to: #selector(delagteFlowLayout.collectionView(_:layout:insetForSectionAt:))) {
                    defaultSectionInsets = delagteFlowLayout.collectionView!(collectionView, layout: self, insetForSectionAt: sectionIndex)
                }
                
                // Get the inter item spacing from the controller/view if the inter item spacing delegate has been implemented
                if delagteFlowLayout.responds(to: #selector(delagteFlowLayout.collectionView(_:layout:minimumInteritemSpacingForSectionAt:))) {
                    defaultInterItemSpacing = delagteFlowLayout.collectionView!(collectionView, layout: self, minimumInteritemSpacingForSectionAt: sectionIndex)
                }
                
                // Get the line spacing from the controller/view if the line spacing delegate has been implemented
                if delagteFlowLayout.responds(to: #selector(delagteFlowLayout.collectionView(_:layout:minimumLineSpacingForSectionAt:))) {
                    defaultLineSpacing = delagteFlowLayout.collectionView!(collectionView, layout: self, minimumLineSpacingForSectionAt: sectionIndex)
                }
            }
            
            maxContentHeight += defaultSectionInsets.top
            
            for itemIndex in stride(from: 0, to: collectionView.numberOfItems(inSection: sectionIndex), by: 1) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                let layoutAttribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                
                // Get the item size from the controller/view if the itemSize delegate has been implemented
                if let delagteFlowLayout = collectionView.delegate as? UICollectionViewDelegateFlowLayout {
                    if delagteFlowLayout.responds(to: #selector(delagteFlowLayout.collectionView(_:layout:sizeForItemAt:))) {
                        let itemSize = delagteFlowLayout.collectionView!(collectionView, layout: self, sizeForItemAt: indexPath)
                        
                        layoutAttribute.frame.size = itemSize
                    }
                }
                
                // Calculate the proper layout for each cases
                switch layoutType {
                case .vertical:
                    layoutAttribute.frame.origin.x = defaultSectionInsets.left
                    layoutAttribute.frame.origin.y = maxContentHeight
                    maxContentHeight = layoutAttribute.frame.maxY
                    
                    // If the item is the last item, then add the bottom insets for the section
                    if itemIndex == (collectionView.numberOfItems(inSection: sectionIndex) - 1) {
                        maxContentHeight += defaultSectionInsets.bottom
                    }
                    else {
                        maxContentHeight += defaultLineSpacing
                    }
                }
                
                layoutAttributes.append(layoutAttribute)
            }
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return false
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var matchingLayoutAttributes = [UICollectionViewLayoutAttributes]()
        
        for attribute in layoutAttributes {
            if attribute.frame.intersects(rect) {
                matchingLayoutAttributes.append(attribute)
            }
        }
        
        return matchingLayoutAttributes
    }
}
