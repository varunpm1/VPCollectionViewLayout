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
        /// If vertical flow, then the cells will be placed horizontally first until it fits the current collectionView's width. If the cell doesn't fit, then it'll be moved to next row and same flow follows for remaining cells. If there is a new section, then the cell will be forced to the next row forcefully.
        case vertical
        
        /// If horizontal flow, then the cells will be placed vertically first until it fits the current collectionView's height. If the cell doesn't fit, then it'll be moved to next column and same flow follows for remaining cells. If there is a new section, then the cell will be forced to the next column forcefully.
        case horizontal
    }
    
    /// Set the required layout type from the defined set of types. Defaults to vertical
    var layoutType: CollectionViewLayoutType = .horizontal
    
    // Stored calculated attributes for caching purpose
    private var layoutAttributes: [UICollectionViewLayoutAttributes] = []
    private var maxContentWidth: CGFloat = 0
    private var maxContentHeight: CGFloat = 0
    
    override func prepare() {
        layoutAttributes.removeAll()
        calculateLayoutAttributes()
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: maxContentWidth, height: maxContentHeight)
    }
    
    // Calculate the attributes when invalidating layout
    private func calculateLayoutAttributes() {
        guard let collectionView = collectionView else {
            return
        }
        
        maxContentWidth = 0
        maxContentHeight = 0
        
        var adjustedInsets: CGFloat = 0
        if #available(iOS 11, *) {
            adjustedInsets = collectionView.adjustedContentInset.top
        }
        
        var startXPosition: CGFloat = 0
        var startYPosition: CGFloat = 0
        let adjustedCollectionViewHeight = collectionView.bounds.size.height - adjustedInsets
        
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
            
            // Update content variables based on layout type
            switch layoutType {
            case .vertical:
                // If the section is changed, then set y position value as well
                startYPosition += defaultSectionInsets.top
                startXPosition = defaultSectionInsets.left
                maxContentHeight += defaultSectionInsets.top
            case .horizontal:
                // If the section is changed, then set x position value as well
                startXPosition += defaultSectionInsets.left
                startYPosition = defaultSectionInsets.top
                maxContentWidth += defaultSectionInsets.left
            }
            
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
                    // Check if the cell can be placed in the same row. If not, then increase Y position for height related values and update frame
                    if (startXPosition + defaultInterItemSpacing + layoutAttribute.frame.size.width + defaultSectionInsets.right) <= collectionView.bounds.size.width {
                        // Add spacing only if it's not a first cell
                        if itemIndex != 0 {
                            startXPosition += defaultInterItemSpacing
                        }
                    }
                    else {
                        startXPosition = defaultSectionInsets.left
                        startYPosition = maxContentHeight + defaultLineSpacing
                    }
                    
                    // Update frame origin
                    layoutAttribute.frame.origin = CGPoint(x: startXPosition, y: startYPosition)
                    startXPosition = layoutAttribute.frame.maxX
                    
                    // Get max height for collectionView
                    maxContentHeight = max(maxContentHeight, layoutAttribute.frame.maxY)
                    
                    // If the item is the last item, then add the bottom insets for the section
                    if itemIndex == (collectionView.numberOfItems(inSection: sectionIndex) - 1) {
                        maxContentHeight += defaultSectionInsets.bottom
                        startYPosition = maxContentHeight
                    }
                    
                    // Width doesn't increase here
                    maxContentWidth = collectionView.bounds.size.width
                case .horizontal:
                    // Check if the cell can be placed in the same column. If not, then increase X position for width related values and update frame
                    if (startYPosition + defaultInterItemSpacing + layoutAttribute.frame.size.height + defaultSectionInsets.bottom) <= adjustedCollectionViewHeight {
                        // Add spacing only if it's not a first cell
                        if itemIndex != 0 {
                            startYPosition += defaultInterItemSpacing
                        }
                    }
                    else {
                        startYPosition = defaultSectionInsets.top
                        startXPosition = maxContentWidth + defaultLineSpacing
                    }
                    
                    // Update frame origin
                    layoutAttribute.frame.origin = CGPoint(x: startXPosition, y: startYPosition)
                    startYPosition = layoutAttribute.frame.maxY
                    
                    // Get max width for collectionView
                    maxContentWidth = max(maxContentWidth, layoutAttribute.frame.maxX)
                    
                    // If the item is the last item, then add the bottom insets for the section
                    if itemIndex == (collectionView.numberOfItems(inSection: sectionIndex) - 1) {
                        maxContentWidth += defaultSectionInsets.right
                        startXPosition = maxContentWidth
                    }
                    
                    // Height doesn't increase here
                    maxContentHeight = adjustedCollectionViewHeight
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
