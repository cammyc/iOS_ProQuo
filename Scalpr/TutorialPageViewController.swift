//
//  TutorialPageViewController.swift
//  Scalpr
//
//  Created by Cameron Connor on 3/27/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import UIKit

class TutorialPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var index = 0
    var identifiers: NSArray = ["FirstTutorialViewController", "SecondTutorialViewController", "ThirdTutorialViewController"]
    private var pages: [UIViewController]!

       override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.dataSource = self
        self.delegate = self
        
        pages = [self.storyboard!.instantiateViewController(withIdentifier: "FirstTutorialViewController") as! HomeTutorialViewController,
                     self.storyboard!.instantiateViewController(withIdentifier: "SecondTutorialViewController") as! SecondTutorialViewController,
                     self.storyboard!.instantiateViewController(withIdentifier: "ThirdTutorialViewController") as! ThirdTutorialViewController]
        

        
        let startingViewController = self.pages.first! as UIViewController
        let viewControllers: NSArray = [startingViewController]
        self.setViewControllers(viewControllers as! [UIViewController], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
        

    }
    
    func viewControllerAtIndex(index: Int) -> UIViewController! {

        //first view controller = firstViewControllers navigation controller
        return pages[index]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = (self.pages as NSArray).index(of: viewController)
        
        return (index == self.pages.count - 1 ? nil : self.pages[index + 1])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = (self.pages as NSArray).index(of: viewController)

        
        return (index == 0 ? nil : self.pages[index - 1])

    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor.white
        appearance.currentPageIndicatorTintColor = MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71)
        appearance.backgroundColor = MiscHelper.UIColorFromRGB(rgbValue: 0xecf0f1)
        return 3
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
}
