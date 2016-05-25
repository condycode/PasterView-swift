//
//  ViewController.swift
//  PasterView
//
//  Created by mengdong on 16/5/25.
//  Copyright © 2016年 mengdong. All rights reserved.
//

import UIKit

let kScreenWidth:CGFloat = UIScreen.mainScreen().bounds.width;
let kScreenHeight:CGFloat = UIScreen.mainScreen().bounds.height;
let scale = kScreenWidth/640;

class ViewController: UIViewController, PasterViewDelegate {
    
    /// 贴纸
    var pasterView: PasterView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        pasterView = PasterView(frame: CGRectMake((kScreenWidth - 420*scale) / 2 , kScreenHeight - 105 - 605*scale, 420*scale, 605*scale));
        pasterView.delegate = self;
        self.view.addSubview(pasterView);
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.changeFirstResponder(_:)));
        self.view.addGestureRecognizer(tap);
        
        let movePan = UIPanGestureRecognizer(target: self, action: #selector(ViewController.movePaster(_:)));
        self.view.addGestureRecognizer(movePan);
        
        
        self.view.backgroundColor = UIColor.whiteColor();
    }
    
    // MARK: - 拖动
    func movePaster(gesture: UIPanGestureRecognizer) {
        if (self.pasterView.isFirst == false) {
            return
        }
        let translation = gesture.translationInView(gesture.view);
        self.pasterView.center = CGPointMake(self.pasterView.center.x + translation.x, self.pasterView.center.y + translation.y);
        gesture.setTranslation(CGPointMake(0, 0), inView: gesture.view);
    }
    
    // MARK: - PasterViewDelegate
    func didClickButtonInPaster(btn: UIButton) {
        switch btn.tag {
        case 100:
            pasterViewHasRotation(0);
            print("role 移动");
        case 101:
            print("translate");
        case 102:
            print("change");
        default:
            print("scale");
        }
    }
    
    func pasterViewHasRotation(rotation: CGFloat) {
        
    }
    
    // MARK: - 点击其它区域，让贴纸失去第一响应
    func changeFirstResponder(gester: UITapGestureRecognizer) {
        let location = gester.locationInView(gester.view);
        if (pasterView.frame.contains(location) == false && pasterView.isFirst == true) {
            pasterView.isFirst = false;
        } else if (pasterView.frame.contains(location) == true && pasterView.isFirst == false) {
            pasterView.isFirst = true;
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

