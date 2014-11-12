//
//  PagingView.swift
//  PagingView-Swift
//
//  Created by Emar on 11/10/14.
//  Copyright (c) 2014 谈文钊. All rights reserved.
//

import UIKit

extension Array {
    func forEach(doThis: (element: T) -> Void) {
        for e in self {
            doThis(element: e)
        }
    }
}

@objc protocol PagingViewDataSource {
    
    func numberOfPagesInPagingView(pagingView: PagingView) -> Int
    
    func pagingView(pagingView: PagingView, pageAtIndex index: Int) -> PagingPage
    
}

@objc protocol PagingViewDelegate {
    
    optional func willChangePageInPagingView(pagingView: PagingView)
    optional func didChangePageInPagingView(pagingView: PagingView)
    
    optional func pagingView(pagingView: PagingView, singleTapSelectedPage page: PagingPage)
    optional func pagingView(pagingView: PagingView, doubleTapSelectedPage page: PagingPage, atLocation location:CGPoint)
    
}

class PagingPage: UIView {
    var index: Int = 0
    private(set) var reuseIdentifier: String?
    
    required init(reuseIdentifier: String) {
        self.reuseIdentifier = reuseIdentifier
        super.init(frame: CGRectZero)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func pageDidAppear() {}
    func pageDidDisappear() {}
    
}

class PagingView: UIView, UIScrollViewDelegate, UIGestureRecognizerDelegate {

    enum PagingViewScrollDirection {
        case Horizontal, Vertical
    }
    
    var padding: CGFloat = 10.0 {
        didSet {
            self.scrollView!.frame = self.frameForScrollView()
        }
    }
    
    var scrollDirection: PagingViewScrollDirection! = .Horizontal {
        didSet {
            self.scrollView!.frame = self.frameForScrollView()
        }
    }
    
    var selectedPage: PagingPage? {
        var findPage: PagingPage?
        for page in self.visiblePages! {
            if page.index == self.selectedIndex {
                findPage = page as? PagingPage
                break
            }
        }
        return findPage
        
    }
    
    var pageControl: UIPageControl? {
        didSet {
            self.pageControl?.numberOfPages = self.dataSource!.numberOfPagesInPagingView(self)
        }
    }
    
    
    weak var delegate: PagingViewDelegate?
    weak var dataSource: PagingViewDataSource? {
        didSet {
            self.setupContentSize()
            self.setPageAtIndex(0, animated: false)
        }
    }
    
    private var scrollView: UIScrollView?
    private var visiblePages: NSMutableSet?
    private var recycledPages = Dictionary<String, NSMutableSet>()
    private var selectedIndex: Int?
    private var visibleRange: NSRange?
    
    private var registerPages = Dictionary<String, AnyClass>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.scrollView = UIScrollView(frame: CGRectZero)
        self.scrollView!.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        self.scrollView!.pagingEnabled = true
        self.scrollView!.showsHorizontalScrollIndicator = false
        self.scrollView!.showsVerticalScrollIndicator = false
        self.scrollView!.decelerationRate = UIScrollViewDecelerationRateFast
        self.scrollView!.delegate = self
        self.addSubview(self.scrollView!)
        
        self.visiblePages = NSMutableSet()
        self.scrollView!.frame = self.frameForScrollView()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("layoutPages"), name: UIDeviceOrientationDidChangeNotification, object: UIDevice.currentDevice())
        
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layoutPages() {
        self.setupContentSize()
        
        if self.scrollDirection == .Horizontal {
            self.scrollView!.contentOffset = CGPointMake(CGFloat(self.selectedIndex!) * CGRectGetWidth(self.scrollView!.bounds), 0)
        } else {
            self.scrollView!.contentOffset = CGPointMake(0, CGFloat(self.selectedIndex!) * CGRectGetHeight(self.scrollView!.bounds))
        }
        
        for page in self.visiblePages! {
            
        }
    }
    
    func setPageAtIndex(index: Int, animated: Bool) {
        self.selectedIndex = index
        var visibleRect = self.frameForPageAtIndex(index)
        if self.scrollDirection == .Horizontal {
            visibleRect.origin.x -= self.padding
            visibleRect.size.width += 2 * self.padding
        } else {
            visibleRect.origin.y -= self.padding
            visibleRect.size.height += 2 * self.padding
        }
        self.scrollView?.scrollRectToVisible(visibleRect, animated: animated)
        self.tilePages()
    }
    
    func setupContentSize() {
        let scrollViewFrame = self.frameForScrollView()
        if self.scrollDirection == .Horizontal {
            self.scrollView!.contentSize = CGSizeMake(CGRectGetWidth(scrollViewFrame) * CGFloat(self.dataSource!.numberOfPagesInPagingView(self)), CGRectGetHeight(scrollViewFrame))
        } else {
            self.scrollView!.contentSize = CGSizeMake(CGRectGetWidth(scrollViewFrame), CGRectGetHeight(scrollViewFrame) * CGFloat(self.dataSource!.numberOfPagesInPagingView(self)))
        }
    }
    
    // MARK: Frame Calculations
    
    func frameForScrollView() -> CGRect {
        var frame = self.bounds
        if self.scrollDirection == .Horizontal {
            frame.origin.x -= self.padding
            frame.size.width += 2 * self.padding
        } else {
            frame.origin.y -= self.padding
            frame.size.height += 2 * self.padding
        }
        
        return frame
    }
    
    func frameForPageAtIndex(index: Int) -> CGRect {
        let scrollViewFrame = self.frameForScrollView()
        var pageFrame = scrollViewFrame
        
        if self.scrollDirection == .Horizontal {
            pageFrame.size.width -= 2 * self.padding
            pageFrame.origin.x = CGRectGetWidth(scrollViewFrame) * CGFloat(index) + self.padding
        } else {
            pageFrame.size.height -= 2 * self.padding
            pageFrame.origin.y = CGRectGetHeight(scrollViewFrame) * CGFloat(index) + self.padding
        }
        
        return pageFrame
    }
    
    // MARK: Tiling and page configuration
    
    func findVisible() -> (fromIndex: Int, toIndex: Int) {
        var visible = (fromIndex: 0, toIndex: 0)
        let visibleBounds = self.scrollView!.bounds;
        if self.scrollDirection == .Horizontal {
            visible.fromIndex = Int(floor(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds)))
            visible.toIndex = Int(floor(CGRectGetMaxX(visibleBounds) - 1) / CGRectGetWidth(visibleBounds))
        } else {
            visible.fromIndex = Int(floor(CGRectGetMinY(visibleBounds) / CGRectGetHeight(visibleBounds)))
            visible.toIndex = Int(floor(CGRectGetMaxY(visibleBounds) - 1) / CGRectGetHeight(visibleBounds))
        }
        
        visible.fromIndex = max(visible.fromIndex - 1, 0)
        visible.toIndex = min(visible.toIndex, self.dataSource!.numberOfPagesInPagingView(self) - 1)
        
        return visible
    }
    
    func isDisplayingPageForIndex(index: Int) -> Bool {
        var foundPage = false
        
        for page in self.visiblePages! {
            if page.index == index {
                foundPage = true
                break
            }
        }
        
        return foundPage
    }
    
    func configurePage(page: PagingPage, forIndex index: Int) {
        page.index = index
        page.frame = self.frameForPageAtIndex(index)
        page.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        page.clipsToBounds = true
        
        page.gestureRecognizers?.forEach({ (element) -> Void in
            page.removeGestureRecognizer(element as UIGestureRecognizer)
        })
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: Selector("singleTap:"))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.delegate = self
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: Selector("doubleTap:"))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = self
        
        singleTapGesture.requireGestureRecognizerToFail(doubleTapGesture)
        page.addGestureRecognizer(singleTapGesture)
        page.addGestureRecognizer(doubleTapGesture)
    }
    
    func singleTap(tapGesture: UITapGestureRecognizer) {
        var tapPage = tapGesture.view as PagingPage
        self.delegate?.pagingView?(self, singleTapSelectedPage: tapPage)
    }
    
    func doubleTap(tapGesture: UITapGestureRecognizer) {
        var tapPage = tapGesture.view as PagingPage
        self.delegate?.pagingView?(self, doubleTapSelectedPage: tapPage, atLocation: tapGesture.locationInView(tapPage))
    }
    
    func tilePages() {
        let visible = self.findVisible()
        
        // Recycle no-longer-visible pages
        let minusPages = NSMutableSet()
        for page in self.visiblePages! {
            if page.index < visible.fromIndex || page.index > visible.toIndex {
                var recycleSet: AnyObject? = self.recycledPages[page.reuseIdentifier!!]
                if recycleSet == nil {
                    recycleSet = NSMutableSet()
                    self.recycledPages[page.reuseIdentifier!!] = recycleSet as? NSMutableSet
                }
                recycleSet?.addObject(page)
                minusPages.addObject(page)
                page.removeFromSuperview()
            }
        }
        
        self.visiblePages?.minusSet(minusPages)
        self.visibleRange = NSMakeRange(visible.fromIndex, visible.toIndex - visible.fromIndex + 1)
        
        // add missing pages
        
        for index in visible.fromIndex...visible.toIndex {
            if !self.isDisplayingPageForIndex(index) {
                let page = self.dataSource!.pagingView(self, pageAtIndex: index)
                self.configurePage(page, forIndex: index)
                self.scrollView?.addSubview(page)
                self.visiblePages?.addObject(page)
            }
        }
        
    }
    
    func registerClass(pageClass: AnyClass, forPageReuseIdentifier identifier: String) {
        self.registerPages[identifier] = pageClass
    }
    
    func dequeueRecycledPageWithIdentifier(identifier: String) -> PagingPage! {
        var recycleSet: AnyObject? = self.recycledPages[identifier]
        if recycleSet?.count > 0 {
            let page = recycleSet!.anyObject
            recycleSet?.removeObject(page!!)
            return page as? PagingPage
        }
        let pageType: PagingPage.Type = self.registerPages[identifier] as PagingPage.Type
        return pageType(reuseIdentifier: identifier)
    }
    
    func reloadData() {
        self.setupContentSize()
        for page in self.visiblePages! {
            let recycledSet: AnyObject? = self.recycledPages[page.reuseIdentifier!!]
            recycledSet?.addObject(page)
            page.removeFromSuperview()
        }
        self.visiblePages?.removeAllObjects()
        self.setPageAtIndex(self.selectedIndex!, animated: false)
    }

    // MARK: ScrollView Delegate
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.tilePages()
    }
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        self.delegate?.willChangePageInPagingView?(self)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let lastSelectedIndex = self.selectedIndex
        if self.scrollDirection == .Horizontal {
            let pageWidth = CGRectGetWidth(scrollView.bounds)
            self.selectedIndex = Int(floor((scrollView.contentOffset.x + pageWidth / 2) / pageWidth))
        } else {
            let pageHeight = CGRectGetHeight(scrollView.bounds)
            self.selectedIndex = Int(floor(scrollView.contentOffset.y + pageHeight / 2) / pageHeight)
        }
        
        self.selectedIndex = max(self.selectedIndex!, 0)
        self.selectedIndex = min(self.dataSource!.numberOfPagesInPagingView(self) - 1, self.selectedIndex!)
        
        self.visibleRange?.location = self.selectedIndex == 0 ? 0 : self.selectedIndex! - 1
        self.visibleRange?.length = self.selectedIndex == 0 || self.selectedIndex == self.dataSource!.numberOfPagesInPagingView(self) - 1 ? 2 : 3
        
        if lastSelectedIndex != self.selectedIndex {
            let arrayIndex = lastSelectedIndex! - self.visibleRange!.location
            if arrayIndex >= 0 && arrayIndex < self.visiblePages!.count {
                var lastPage: PagingPage?
                for page in self.visiblePages! {
                    if page.index == lastSelectedIndex {
                        lastPage = page as? PagingPage
                        break
                    }
                }
                lastPage?.pageDidDisappear()
            }
            self.selectedPage?.pageDidAppear()
        }
        
        self.pageControl?.currentPage == self.selectedIndex
        self.delegate?.didChangePageInPagingView?(self)
        
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
    }
    
    // MARK: Gesture Delegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return !touch.view.isKindOfClass(UIControl)
    }

}
