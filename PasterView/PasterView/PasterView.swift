//
//  PasterView.swift
//  MoeChat
//
//  Created by mengdong on 16/5/4.
//  Copyright © 2016年 wowoim. All rights reserved.
//

import UIKit

@objc protocol PasterViewDelegate {
    optional func didClickButtonInPaster(btn: UIButton);
    optional func pasterViewHasRotation(rotation: CGFloat);
    optional func pasterBecomeFirst();
}

class PasterView: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    weak var delegate:PasterViewDelegate!
    
    var isFirst:Bool! = true {
        didSet {
            if (oldValue == true) {
                self.border.removeFromSuperlayer();
            } else {
                self.layer.insertSublayer(border, atIndex: 0);
            }
            self.deleteBtn.hidden = oldValue;
            self.transformBtn.hidden = oldValue;
            self.scaleBtn.hidden = oldValue;
            self.changeBtn.hidden = oldValue;
        }
    }
    
    var border:CAShapeLayer!
    var transformBtn:UIButton!
    var deleteBtn:UIButton!
    var scaleBtn:UIImageView!
    var changeBtn:UIButton!
    
    /// 角度
    var deltaAngle:CGFloat!
    var prevPoint:CGPoint!
    var minWidth:CGFloat!
    var minHeight:CGFloat!
    /// 累计翻转角度
    var angleTotal:CGFloat!
    /// 原始大小
    private var normalRect:CGRect!
    /// 开始拖动的点
    private var touchStart:CGPoint!
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        
       
        angleTotal = 0;
        normalRect = frame;
        minWidth = frame.size.width * 0.5;
        minHeight = frame.size.height * 0.5;
        deltaAngle = atan2(self.frame.origin.y+self.frame.size.height - self.center.y,
            self.frame.origin.x+self.frame.size.width - self.center.x) ;
        
        border = CAShapeLayer();
        border.strokeColor = UIColor.redColor().CGColor;
        border.fillColor = UIColor.clearColor().CGColor;
        border.path = UIBezierPath(rect: self.bounds).CGPath;
        border.frame = self.bounds;
        border.lineWidth = 1;
        border.lineCap = "square";
        border.lineDashPattern = [NSNumber(float: 4), NSNumber(float: 4)];
        
        self.layer.addSublayer(border);
        
        deleteBtn = UIButton(type: UIButtonType.Custom);
        deleteBtn.tag = 100;
        deleteBtn.setBackgroundImage(UIImage(named: "camera_reset"), forState: UIControlState.Normal);
        deleteBtn.addTarget(self, action: #selector(PasterView.roleChangeFrame(_:)), forControlEvents: UIControlEvents.TouchUpInside);
        deleteBtn.frame = CGRectMake(-30*scale, -30*scale, 60*scale, 60*scale);
        self.addSubview(deleteBtn);
        
        transformBtn = UIButton(type: UIButtonType.Custom);
        transformBtn.tag = 101;
        transformBtn.setBackgroundImage(UIImage(named: "camera_translate"), forState: UIControlState.Normal);
        transformBtn.frame = CGRectMake(self.bounds.size.width - 30*scale, -30*scale, 60*scale, 60*scale);
        transformBtn.addTarget(self, action: #selector(PasterView.roleChangeFrame(_:)), forControlEvents: UIControlEvents.TouchUpInside);
        self.addSubview(transformBtn);
        
        scaleBtn = UIImageView();
        scaleBtn.frame = CGRectMake(self.bounds.size.width - 30*scale, self.bounds.size.height-30*scale, 60*scale, 60*scale);
        scaleBtn.image = UIImage(named: "camera_scale");
        self.addSubview(scaleBtn);
        
        changeBtn = UIButton(type: UIButtonType.Custom);
        changeBtn.tag = 102;
        changeBtn.frame = CGRectMake(-30*scale, self.bounds.size.height-30*scale, 60*scale, 60*scale);
        changeBtn.setBackgroundImage(UIImage(named: "camera_changeAction"), forState: UIControlState.Normal);
        changeBtn.addTarget(self, action: #selector(PasterView.roleChangeFrame(_:)), forControlEvents: UIControlEvents.TouchUpInside);
        self.addSubview(changeBtn);
        
        self.backgroundColor = UIColor.lightGrayColor();
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(PasterView.resizeAndRotation(_:)));
        scaleBtn.addGestureRecognizer(pan);
        
//        let tap = UITapGestureRecognizer(target: self, action: #selector(PasterView.becomeFirst(_:)));
//        self.addGestureRecognizer(tap);
        
        let pinch  = UIPinchGestureRecognizer(target: self, action: #selector(PasterView.scalePaster(_:)));
        self.addGestureRecognizer(pinch);
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(PasterView.rotationPaster(_:)));
        self.addGestureRecognizer(rotation);
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 三个按钮的点击事件
    func roleChangeFrame(sender: UIButton) {
        
        if (self.isFirst == false) {
            return
        }
        
        switch sender.tag {
        case 100:
            self.transform = CGAffineTransformMakeRotation(0);
            self.frame = normalRect;
            border.path = UIBezierPath(rect: CGRectMake(0, 0, normalRect.size.width, normalRect.height)).CGPath;
            border.frame = CGRectMake(0, 0, normalRect.size.width, normalRect.height);
            scaleBtn.frame = CGRectMake(self.bounds.size.width - 30*scale, self.bounds.size.height-30*scale, 60*scale, 60*scale);
            deleteBtn.frame = CGRectMake(-30*scale, -30*scale, 60*scale, 60*scale);
            transformBtn.frame = CGRectMake(self.bounds.size.width - 30*scale, -30*scale, 60*scale, 60*scale);
            changeBtn.frame = CGRectMake(-30*scale, self.bounds.size.height-30*scale, 60*scale, 60*scale);
            self.delegate?.pasterViewHasRotation!(0);
        case 101:
            print("translate");
        case 102:
            print("change");
        default:
            print("哪个？？");
        }
        
        self.delegate.didClickButtonInPaster!(sender);
    }
    
    // MARK: - 按钮超出父视图不响应点击的解决办法
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, withEvent: event);
        let deleteBtnPoint = self.deleteBtn.convertPoint(point, fromView: self);
        
        if (self.deleteBtn.pointInside(deleteBtnPoint, withEvent: event)) {
            return deleteBtn;
        }
        
        let translateBtnPoint = self.transformBtn.convertPoint(point, fromView: self);
        if (self.transformBtn.pointInside(translateBtnPoint, withEvent: event)) {
            return transformBtn;
        }
        
        let scaleBtnPoint = self.scaleBtn.convertPoint(point, fromView: self);
        if (self.scaleBtn.pointInside(scaleBtnPoint, withEvent: event)) {
            return scaleBtn;
        }
        
        let changeBtnPoint = self.changeBtn.convertPoint(point, fromView: self);
        if (self.changeBtn.pointInside(changeBtnPoint, withEvent: event)) {
            return changeBtn;
        }
        
        return result;
    }
    
    //MARK: - pan 手势
    func resizeAndRotation(gesture: UIPanGestureRecognizer) {
        
        if (self.isFirst == false) {
            return
        }
        
        if (gesture.state == UIGestureRecognizerState.Began) {
            prevPoint = gesture.locationInView(self);
            
            self.setNeedsDisplay();
        } else if (gesture.state == UIGestureRecognizerState.Changed) {
            // preventing
            if (self.bounds.size.width < minWidth || self.bounds.size.height < minHeight) {
                self.bounds = CGRectMake(self.frame.origin.x, self.frame.origin.y, minWidth + 1, minHeight + 1);
                
                scaleBtn.frame = CGRectMake(self.bounds.size.width - 30*scale, self.bounds.size.height-30*scale, 60*scale, 60*scale);
                deleteBtn.frame = CGRectMake(-30*scale, -30*scale, 60*scale, 60*scale);
                transformBtn.frame = CGRectMake(self.bounds.size.width - 30*scale, -30*scale, 60*scale, 60*scale);
                changeBtn.frame = CGRectMake(-30*scale, self.bounds.size.height-30*scale, 60*scale, 60*scale);
                
                prevPoint = gesture.locationInView(self);
            } else {
                let point = gesture.locationInView(self);
                var wChange:CGFloat = 0, hChange:CGFloat = 0;
                wChange = point.x - prevPoint.x;
                let wRationChange:CGFloat = (wChange/self.bounds.size.width);
                
                hChange = wRationChange * self.bounds.size.height;
                
//                if (wChange > 50 || wChange < -50 || hChange > 50 || hChange < -50) {
//                    prevPoint = gesture.locationOfTouch(0, inView: self);
//                    return;
//                }
                
                var finalWidth = self.bounds.size.width + wChange;
                var finalHeight = self.bounds.size.height + hChange;
                
                if (finalWidth > 420*scale*(1+0.5)) {
                    finalWidth = 420*scale*(1+0.5);
                }
                if (finalWidth < 420*scale*(1-0.5)) {
                    finalWidth = 420*scale*(1-0.5);
                }
                if (finalHeight > 605*scale*(1+0.5)) {
                    finalHeight = 605*scale*(1+0.5);
                }
                if (finalHeight < 605*scale*(1-0.5)) {
                    finalHeight = 605*scale*(1-0.5);
                }
                
                self.bounds = CGRectMake(self.bounds.origin.x,self.bounds.origin.y, finalWidth, finalHeight);
                
                scaleBtn.frame = CGRectMake(self.bounds.size.width - 30*scale, self.bounds.size.height-30*scale, 60*scale, 60*scale);
                deleteBtn.frame = CGRectMake(-30*scale, -30*scale, 60*scale, 60*scale);
                transformBtn.frame = CGRectMake(self.bounds.size.width - 30*scale, -30*scale, 60*scale, 60*scale);
                changeBtn.frame = CGRectMake(-30*scale, self.bounds.size.height-30*scale, 60*scale, 60*scale);
                prevPoint = gesture.locationOfTouch(0, inView: self);
                
            }
            
            
            let ang:CGFloat = atan2(gesture.locationInView(self.superview).y - self.center.y, gesture.locationInView(self.superview).x - self.center.x);
            let angleDiff:CGFloat = deltaAngle - ang;
            self.transform = CGAffineTransformMakeRotation(-angleDiff);
            
            self.delegate.pasterViewHasRotation!(-angleDiff);
            self.setNeedsDisplay();
        } else if (gesture.state == UIGestureRecognizerState.Ended) {
            prevPoint = gesture.locationInView(self);
            
            self.setNeedsDisplay();
        }
        border.path = UIBezierPath(rect: self.bounds).CGPath;
        border.frame = self.bounds;
    }
    
//    // MARK: - tap 手势
//    func becomeFirst(gesture: UITapGestureRecognizer) {
//        if (self.isFirst == true) {
//            return
//        }
//        self.isFirst = true;
//        self.delegate.pasterBecomeFirst!();
//    }
    
    // MARK: - pinch 手势
    func scalePaster(gesture: UIPinchGestureRecognizer) {
        if (self.isFirst == false) {
            return
        }
        if (self.bounds.size.width * gesture.scale > normalRect.size.width * 1.5 || self.bounds.size.width * gesture.scale < normalRect.size.width * 0.5) {
            return;
        }
        self.bounds = CGRectMake(0, 0, self.bounds.size.width*gesture.scale, self.bounds.size.height*gesture.scale);
        scaleBtn.frame = CGRectMake(self.bounds.size.width - 30*scale, self.bounds.size.height-30*scale, 60*scale, 60*scale);
        deleteBtn.frame = CGRectMake(-30*scale, -30*scale, 60*scale, 60*scale);
        transformBtn.frame = CGRectMake(self.bounds.size.width - 30*scale, -30*scale, 60*scale, 60*scale);
        changeBtn.frame = CGRectMake(-30*scale, self.bounds.size.height-30*scale, 60*scale, 60*scale);
        border.path = UIBezierPath(rect: self.bounds).CGPath;
        border.frame = self.bounds;
        // 这个方法不能计算大小
//        self.transform = CGAffineTransformScale(self.transform,gesture.scale,gesture.scale);
        gesture.scale = 1.0;
        self.delegate?.pasterViewHasRotation!(0);
    }
    
    // MARK: - rotation 手势
    func rotationPaster(gesture: UIRotationGestureRecognizer) {
        if (self.isFirst == false) {
            return
        }
        self.transform = CGAffineTransformRotate(self.transform, gesture.rotation);
        gesture.rotation = 0;
    }
    
    
    /*
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first;
        touchStart = touch!.locationInView(self.superview);
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (self.isFirst == false) {
            return
        }
        let touchLocation = touches.first!.locationInView(self);
        if (CGRectContainsPoint(scaleBtn.frame, touchLocation)) {
            return;
        }
        let touchPoint = touches.first!.locationInView(self.superview);
        self.translateUsingTouchLocation(touchPoint);
        
        touchStart = touchPoint;
    }
    
    
    func translateUsingTouchLocation(touchPoint: CGPoint) {
        let newCenter = CGPointMake(self.center.x + touchPoint.x - touchStart.x,self.center.y + touchPoint.y - touchStart.y);
        
        self.center = newCenter;
    }
    */
}
