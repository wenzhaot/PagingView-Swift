//
//  DemoPage.swift
//  PagingView-Swift
//
//  Created by Emar on 11/12/14.
//  Copyright (c) 2014 谈文钊. All rights reserved.
//

import UIKit

class DemoPage: PagingPage {
    
    var label: UILabel?

    required init(reuseIdentifier: String) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        self.label = UILabel(frame: self.bounds)
        self.label!.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        self.label!.textAlignment = .Center
        self.label!.textColor = UIColor.whiteColor()
        self.label!.backgroundColor = UIColor.clearColor()
        self.label!.font = UIFont.boldSystemFontOfSize(30)
        self.label!.userInteractionEnabled = false
        self.addSubview(self.label!)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
