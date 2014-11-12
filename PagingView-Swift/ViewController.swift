//
//  ViewController.swift
//  PagingView-Swift
//
//  Created by Emar on 11/10/14.
//  Copyright (c) 2014 谈文钊. All rights reserved.
//

import UIKit

class ViewController: UIViewController, PagingViewDataSource, PagingViewDelegate {
    
    var pagingView: PagingView?
    
    struct PagingPageIdentifiers {
        static let demoPage = "demoPage"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.pagingView = PagingView(frame: self.view.bounds)
        
        self.view.addSubview(self.pagingView!)
        
        self.pagingView!.registerClass(DemoPage.self, forPageReuseIdentifier: PagingPageIdentifiers.demoPage)
        self.pagingView!.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        self.pagingView!.dataSource = self
        self.pagingView!.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func randomColors() -> NSArray! {
        return [UIColor.redColor(), UIColor.yellowColor(), UIColor.blueColor(), UIColor.blackColor()]
    }
    
    // MARK: PagingViewDataSource & PagingViewDelegate

    func numberOfPagesInPagingView(pagingView: PagingView) -> Int {
        return 10
    }
    
    func pagingView(pagingView: PagingView, pageAtIndex index: Int) -> PagingPage {
        let page: DemoPage = pagingView.dequeueRecycledPageWithIdentifier(PagingPageIdentifiers.demoPage) as DemoPage
        page.backgroundColor = self.randomColors()[random() % 4] as? UIColor
        page.label?.text = "\(index)"
        return page
    }
    
    func pagingView(pagingView: PagingView, singleTapSelectedPage page: PagingPage) {
        println("single tap: \(page.index)")
    }
}

