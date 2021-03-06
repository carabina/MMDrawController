//
//  MMDrawerViewController.swift
//  Pods
//
//  Created by Millman YANG on 2017/3/30.
//
//

import UIKit

// only check segue are (main/segue) ,
public class DrawerSegue: UIStoryboardSegue {
    override public func perform() {}
}

public enum SliderMode {
    case frontWidth(w:CGFloat)
    case frontWidthRate(r:CGFloat)

    case rearWidth(w:CGFloat)
    case rearWidthRate(r:CGFloat)
    case none
}

public enum ShowMode {
    case left
    case right
    case main
}

struct SegueParams {
    var type:String
    var params:Any?
}

open class MMDrawerViewController: UIViewController  {
    var containerView = UIView()
    var sliderMap = [SliderLocation:SliderManager]()
    var currentManager:SliderManager?
    
    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let s = segue as? DrawerSegue ,
           let p = sender as? SegueParams {
            switch p.type {
            case "main":
                self.set(main: s.destination)
            case "left":
                if let slideMode = p.params as? SliderMode {
                    self.set(left: s.destination, mode: slideMode)
                }
            case "right":
                if let slideMode = p.params as? SliderMode {
                    self.set(right: s.destination, mode: slideMode)
                }
            default:
              break
            }
        }
    }
    
    public var main:UIViewController? {
        willSet {
            main?.removeFromParentViewController()
            main?.view.removeFromSuperview()
        } didSet {
            if let new = main {                
                new.view.shadow(opacity: 0.4, radius: 5.0)
                new.view.addGestureRecognizer(mainPan)
                new.view.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(new.view)
                containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": new.view]))
                containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": new.view]))

                self.view.layoutIfNeeded()
                self.addChildViewController(new)
            }
        }
    }
    
    lazy var mainPan:UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(MMDrawerViewController.panAction(pan:)))
        return pan
    }()
    
    public var draggable:Bool = true {
        didSet{
            mainPan.isEnabled = draggable
            sliderMap.forEach { $0.1.sliderPan.isEnabled = draggable }
        }
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        containerView.frame = self.view.bounds

        var isRearShow = false
        sliderMap.forEach { (_ , value) in
            if !isRearShow {
                DispatchQueue.main.async {
                    value.resetFrame()
                }
            }
            
            if value.isShow && !value.isSliderFront() {
                isRearShow = true
            }
        }

        if !isRearShow {
            containerView.frame = self.view.bounds
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(containerView)
    }
    
    public func set(left:UIViewController, mode:SliderMode) {
        sliderMap[.left] = SliderManager(drawer:self)
        sliderMap[.left]?.addSlider(slider: left, location: .left, mode: mode)
        self.view.layoutIfNeeded()
        
    }
    
    public func set(right:UIViewController , mode:SliderMode) {
        sliderMap[.right] = SliderManager(drawer: self)
        sliderMap[.right]?.addSlider(slider: right, location: .right, mode: mode)
        self.view.layoutIfNeeded()
    }
    
    public func setLeft(mode:SliderMode) {
        sliderMap[.left]?.mode = mode
        self.view.layoutIfNeeded()
    }
    
    public func setRight(mode:SliderMode) {
        sliderMap[.right]?.mode = mode
        self.view.layoutIfNeeded()
    }
    
    public func set(main:UIViewController) {
        self.main = main
        self.view.layoutIfNeeded()
    }
    
    public func showLeftSlider(isShow:Bool) {
        sliderMap[.left]?.show(isShow: isShow)
    }
    
    public func showRightSlider(isShow:Bool) {
        sliderMap[.right]?.show(isShow: isShow)
    }
    
    public func getManager(direction:SliderLocation) -> SliderManager? {
        return sliderMap[direction]
    }
    
    public func setMainWith(identifier:String) {
        self.performSegue(withIdentifier: identifier, sender: SegueParams(type: "main", params: nil))
    }
    
    public func setLeftWith(identifier:String , mode:SliderMode) {
        self.performSegue(withIdentifier: identifier, sender: SegueParams(type: "left", params: mode))
    }
    
    public func setRightWith(identifier:String , mode:SliderMode) {
        self.performSegue(withIdentifier: identifier, sender: SegueParams(type: "right", params: mode))
    }
}

extension MMDrawerViewController {
    func panAction(pan:UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            currentManager = self.searchCurrentManagerWith(pan: pan)
            currentManager?.panAction(pan: pan)
        case .changed:
            currentManager?.panAction(pan: pan)
        case .cancelled , .ended :
            currentManager?.panAction(pan: pan)
            currentManager = nil
        default:
            break
        }
    }
    
    fileprivate func searchCurrentManagerWith(pan:UIPanGestureRecognizer) -> SliderManager? {
        var manager:SliderManager?
        let rect = self.view.bounds.insetBy(dx: 40, dy: 40)
        let first = pan.location(in: pan.view)
        //Edge
        if !rect.contains(first) {
            sliderMap.forEach({ (_ , value) in
                
                if let s = manager?.slider?.view {
                    
                    let pre = first.distance(point: s.center)
                    let current = first.distance(point: value.slider?.view.center)
                    
                    if current < pre {
                        manager = value
                    }
                } else {
                    manager = value
                }
            })
            
        } else {
            manager = nil
        }
        return manager
    }
}
