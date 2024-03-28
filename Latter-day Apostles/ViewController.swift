//
//  ViewController.swift
//  Latter-day Apostles
//
//  Created by Geoffrey Draper on 11/16/23.
//

import UIKit

class ViewController: UIViewController {

    var canvas : JView?
    var dateLabel : UILabel!
    var slider : UISlider!
    var bacButton : UIButton!
    var fowButton : UIButton!
    var year : Int!
    var currentDay, currentMonth, currentYear : Int!
    let STARTING_YEAR : Float = 1832
    let buttonPressedColor = UIColor.init(red: 189.0/255, green: 183/255.0, blue: 107.0/255, alpha: 1)
        let buttonReleasedColor = UIColor.init(red: 153.0/255, green: 146.0/255.0, blue: 44.0/255, alpha: 1)
    
    override func viewWillTransition(to: CGSize, with: UIViewControllerTransitionCoordinator) {
        //print("rotate! width, height, year", to.width, to.height, year)
        buildGUI(to.width, to.height)
    }
    
    func buildGUI(_ newWidth : CGFloat, _ newHeight : CGFloat) {
        print("inside buildGUI")
        let window = self.view
        let w = newWidth//window?.bounds.width
        let h = newHeight//window?.bounds.height
        //print(window?.bounds.width)
        //print ("Inside BuildGUI, year=",year)
        
        let sliderTop = h*0.9
        let sliderHeight = h-sliderTop
        let labelHeight = sliderHeight
        let labelTop = sliderTop-labelHeight
        
        canvas?.removeFromSuperview()
        slider?.removeFromSuperview()
        dateLabel?.removeFromSuperview()
        fowButton?.removeFromSuperview()
        bacButton?.removeFromSuperview()
        
        canvas = JView(frame: CGRect(x: 0, y: 0, width: w, height: h-(labelHeight+sliderHeight)))
        canvas!.setVC(self)
        canvas!.year = year
        canvas!.day = currentDay
        canvas!.month = currentMonth
        //canvas!.respondToDateChange()
        window?.addSubview(canvas!)
        
        //Create Slider
        slider = UISlider(frame: CGRect (x: 0, y: sliderTop, width: w, height: sliderHeight))
        slider.minimumValue = STARTING_YEAR
        slider.maximumValue = Float(currentYear!)
        slider.isContinuous = true
        slider.tintColor = UIColor.blue
        slider.value = Float(year!)
        slider.backgroundColor = UIColor.init(red: 189.0/255, green: 183/255.0, blue: 107.0/255, alpha: 1)
        slider.addTarget(self, action: #selector(ViewController.paybackSliderValueDidChange(_:)),for: .valueChanged)
        window?.addSubview(slider)
        
        
        //Create forward/backward buttons
        bacButton = UIButton(frame: CGRect(x: 0, y: labelTop, width: labelHeight, height: labelHeight))
        fowButton = UIButton(frame: CGRect(x: w-labelHeight, y: labelTop, width: labelHeight, height: labelHeight))
        bacButton.backgroundColor = buttonReleasedColor
        fowButton.backgroundColor = buttonReleasedColor
        bacButton.setImage(UIImage(named:"navigation_back"), for: .normal)
        fowButton.setImage(UIImage(named:"navigation_forward"), for: .normal)
        bacButton.addTarget(self, action: #selector(ViewController.goBack(_:)),for: .touchUpInside)
        fowButton.addTarget(self, action: #selector(ViewController.goForward(_:)),for: .touchUpInside)
        bacButton.addTarget(self, action: #selector(ViewController.buttonDown(_:)),for: .touchDown)
        fowButton.addTarget(self, action: #selector(ViewController.buttonDown(_:)),for: .touchDown)

        window?.addSubview(bacButton)
        window?.addSubview(fowButton)

        //Create Label
        dateLabel = UILabel(frame: CGRect(x: labelHeight, y: labelTop, width: w-2*labelHeight, height: labelHeight))
        dateLabel.center = CGPoint(x: w/2, y: labelTop + labelHeight/2)
        dateLabel.textAlignment = NSTextAlignment.center
        dateLabel.font = UIFont(name: dateLabel.font.fontName, size: 30)
        dateLabel.textColor = UIColor.black
        dateLabel.text = canvas!.getDateString()
        dateLabel.backgroundColor = UIColor.init(red: 189.0/255, green: 183/255.0, blue: 107.0/255, alpha: 1)
        window?.addSubview(dateLabel)


    }


    override func viewDidLoad() {
        super.viewDidLoad()
        print("inside viewDidLoad")

        //get the current year
        let currentDateTime = Date()
        let userCalendar = Calendar.current
        let requestedComponents: Set<Calendar.Component> = [.year, .month, .day]
        let dateTimeComponents = userCalendar.dateComponents(requestedComponents, from: currentDateTime)
        currentYear = dateTimeComponents.year
        currentMonth = dateTimeComponents.month
        currentDay = dateTimeComponents.day
        year = currentYear
        
        buildGUI(self.view.bounds.width, self.view.bounds.height)
        
        Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(ViewController.doStuff(_:)), userInfo: nil, repeats: true)
        
    }

    @objc func doStuff(_ timer : Timer) {
        canvas?.onTick()
    }

    
    @objc func paybackSliderValueDidChange(_ sender: UISlider!)
    {
        //print("Inside paybackSliderValueDidChange")
        setYear_helper(Int(sender.value))
        cancelToast()
    }
    
    func showToast(_ text: String) {
        //print(text)
        canvas!.toastText = text;
    }
    
    func cancelToast() {
        canvas!.toastText = nil;
    }
    
    @objc func buttonDown(_ sender: UIButton!) {
        sender.backgroundColor = buttonPressedColor
    }
    
    @objc func goBack(_ sender: UIButton!)
    {
        sender.backgroundColor = buttonReleasedColor
//      fowButton.setEnabled(true);
        cancelToast();
        if (canvas!.year! <= 1832 && canvas!.month! <= 3 && canvas!.day! <= 8) {
            //bacButton.setEnabled(false);
            showToast("You have reached the beginning of the timeline.");
        } else {
            canvas?.goBack();
            updateTextView();
            slider.value = Float(canvas!.year!)
            let text = canvas?.getCurrentEventDesc()
            showToast(text!)
        }
    }

    @objc func goForward(_ sender: UIButton!)
    {
        sender.backgroundColor = buttonReleasedColor
        cancelToast();
        //bacButton.setEnabled(true);
        if(canvas?.goForward()==false){
            setYear(currentYear);
            showToast("You have reached the current date.");
            //fowButton.setEnabled(false);
        } else{
            let text = canvas?.getCurrentEventDesc()
            slider.value = Float(canvas!.year!)
            showToast(text!);
        }
        updateTextView();
    }
    
    func updateTextView(){
        dateLabel.text = canvas!.getDateString()
    }

    
    func setYear_helper(_ yeer : Int) {
        //print("Inside setYear_helper")
        year = yeer
        canvas!.year = year
        //print("slider minimum=",slider.minimumValue,"sender.value=",sender.value)
        if year == Int(slider.minimumValue) {
            canvas!.day = 8
            canvas!.month = 3
        } else if year == Int(slider.maximumValue) {
            canvas!.day = currentDay
            canvas!.month = currentMonth
        } else {
            canvas!.day = 1
            canvas!.month = 1
        }
        canvas!.respondToDateChange()
        dateLabel.text = canvas!.getDateString()//String(Int(sender.value))

        
    }
    
    func setYear(_ yeer: Int) {
        //print("Inside setYear")
        setYear_helper(yeer)
        slider.setValue(Float(year), animated: false)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

