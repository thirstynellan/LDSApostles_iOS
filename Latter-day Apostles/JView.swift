//
//  JView.swift
//  Latter-day Apostles
//
//  Created by Geoffrey Draper on 11/29/23.
//

import Foundation

import UIKit
import UIKit.UIGestureRecognizerSubclass
import UIKit.UIGestureRecognizer

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class JView: UIView {


    enum Rotation {
        case cw        //clockwise
        case ccw        //counter-clockwise
    }
    
    class ApostlePosition {
        var angle : Float
        var radius : Float
        var bounds : CGRect
        var grounded : Bool;
        
        init() {
            bounds = CGRect()
            grounded = true
            angle = 0
            radius = 0
        }
    }
    
    struct ApostleLayout {
        var tweNumber : Int?
        var preNumber : Int?
        var positions = [Apostle : ApostlePosition]()
        
        func contains(_ a: Apostle) -> Bool {
            return (positions[a] == nil)
        }
        /*func getApostles() {
            return positions.keys
        }*/
    }
    
    class Delta {
        var dAngle : Float?
        var dPos : CGPoint?
        
        func isNull() -> Bool {
            //print(dAngle)
            //print(dPos)
            return ((dPos == nil && abs(dAngle!) <= 0.0001) || (dPos != nil && (dPos!.x == 0 && dPos!.y == 0)));
        }
        
    }
    
    var apostleList = [String : Apostle?]()
    var presidencyList = [Date : [Apostle]]()
    var twelveList = [Date : [Apostle]]()
    var texts = [Date? : String?]()
    var sortKeys = [Date]()
    var currentLayout : ApostleLayout?
    var newLayout : ApostleLayout?
    var sWidth : Int?
    var minorRadius, majorRadius : Int?
    var cx, cy : CGFloat?
    var bWidth, bHeight : Int?
    var year, month, day : Int?
    var firstTime : Bool = true
    var animating : Bool = false
    var outerCircleRadius, innerCircleRadius, whiteCircleRadius : CGFloat?
    let TWO_PI = CGFloat(Double.pi * 2)
    let PI_HALVES = Float(Double.pi * 0.5)
    let PI = Float(Double.pi)
    let FRAMES : Float = 30
    var deltas = [Apostle : Delta]()
    var currentFrame : Int?
    var touchDown : CGPoint?
    var oldDegrees : Float?
    var rot : Rotation?
    var downRadius : Float?
    var boingDegrees : Float?
    var bounceBack : Bool?
    var quLines, fpLines : CGMutablePath?
    var outerCircle, innerCircle, whiteCircle : CGMutablePath?
    var date : Date?
    //var todaysDate : DateComponents?
    let months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    //var nameLabelFont : UIFont?
    var nameLabelFontAttributes: NSDictionary?
    var toastFontAttributes: NSDictionary?
    var toastText : String?
    var parent : ViewController?
    
    func loadEvents() {
        let filename  = "eventdesc"
        let myFileURL = Bundle.main.url(forResource: filename, withExtension: "txt")!
        let myText = try! String(contentsOf: myFileURL, encoding: String.Encoding.isoLatin1)
        //print(String(myText))
        let lines = myText.components(separatedBy: "\n")
        for foo in lines {
            if foo.count < 1 {   //sanity check
                break
            }
            let fields = foo.components(separatedBy: "|")
            let dateString = fields[0]
            let zero = dateString.startIndex
            let yearIndex = dateString.index(zero, offsetBy: 4)
//            let yearString = dateString.substring(to:yearIndex)
            let yearString = dateString[..<yearIndex]
            let dayIndex = dateString.index(zero, offsetBy: 6)
            //let dayString = dateString.substring(from:dayIndex)
            let dayString = dateString[dayIndex...]
            let monthIndex1 = dateString.index(zero, offsetBy: 4)
            let monthIndex2 = dateString.index(zero, offsetBy: 6)
            let monthRange = monthIndex1..<monthIndex2
            //let monthString = dateString.substring(with: monthRange)
            let monthString = dateString[monthRange]
            //print("day=" + dayString + ", month=" + monthString + ", year=" + yearString)
            var c = DateComponents()
            c.year = Int(yearString)!
            c.month = Int(monthString)!
            c.day = Int(dayString)!
            c.hour=0;c.minute=0;c.second=0;c.nanosecond=0
            
            let gregorian = Calendar(identifier:Calendar.Identifier.gregorian)
            let dates = gregorian.date(from: c)
            
            texts[dates!] = fields[1]
            
        }

    }
    
    func loadApostles() {
        let correctPortraitSize = CGSize(width: bWidth!, height: bHeight!)
        var filename  = "apostles"
        var myFileURL = Bundle.main.url(forResource: filename, withExtension: "txt")!
        var myText = try! String(contentsOf: myFileURL, encoding: String.Encoding.isoLatin1)
        //print(String(myText))
        var lines = myText.components(separatedBy: "\n")
        for foo in lines {
            let fields = foo.components(separatedBy: "|")
            if (fields.count > 1) {//stupid bandaid fix. Not sure what root cause is.
                //print("attempting to load " + fields[4])
                let portraitOrig = UIImage(named:fields[4])
                let portraitScaled = resizeImage(portraitOrig!, newSize:correctPortraitSize)
                apostleList[fields[1]] = Apostle(id: Int(fields[0])!, name: fields[1], birth: fields[2], death: fields[3], photo: portraitScaled, bioFile: fields[5])
            }
        }
        
        //load the fp/12 list.
        filename = "list"
        myFileURL = Bundle.main.url(forResource: filename, withExtension: "txt")!
        myText = try! String(contentsOf: myFileURL, encoding: String.Encoding.isoLatin1)
        lines = myText.components(separatedBy: "\n")
        for foo in lines {
            if foo.count < 1 {   //sanity check
                break
            }
            let fields = foo.components(separatedBy: "%")
            let fpFields = fields[0].components(separatedBy: "|")
            let twFields = fields[1].components(separatedBy: "|")
            let dateString = fpFields[0]
            let zero = dateString.startIndex
            let yearIndex = dateString.index(zero, offsetBy: 4)
            //let yearString = dateString.substring(to:yearIndex)
            let yearString = dateString[..<yearIndex]
            let dayIndex = dateString.index(zero, offsetBy: 6)
            //let dayString = dateString.substring(from:dayIndex)
            let dayString = dateString[dayIndex...]
            let monthIndex1 = dateString.index(zero, offsetBy: 4)
            let monthIndex2 = dateString.index(zero, offsetBy: 6)
            let monthRange = monthIndex1..<monthIndex2
            //let monthString = dateString.substring(with: monthRange)
            let monthString = dateString[monthRange]
            //print("day=" + dayString + ", month=" + monthString + ", year=" + yearString)
            var c = DateComponents()
            c.year = Int(yearString)!
            c.month = Int(monthString)!
            c.day = Int(dayString)!
            c.hour=0;c.minute=0;c.second=0;c.nanosecond=0
            
            let gregorian = Calendar(identifier:Calendar.Identifier.gregorian)
            let dates = gregorian.date(from: c)
            
            //parse First Presidency
            //print("current date: " + fpFields[0])
            
            var prez1 = [Apostle]()
            for apostleName in fpFields {
                //print ("reading FP: " + apostleName)
                let apost = apostleList[apostleName]
                if apost != nil {
                    //presidencyList[dates!]?.append(apost!!) //UGLY syntax. Shame on you, Swift!!
                    //print(presidencyList[dates!]?.count)
                    prez1.append(apost!!)
                    //print(prez1.count)
                }
            }
            presidencyList[dates!] = prez1
            

            
            //parse the twelve
            //print("There are " + String(twFields.count) + " values in twFields")
            var array12 = [Apostle]()
            for apostleName in twFields {
                //print ("reading 12: " + apostleName)
                let apost = apostleList[apostleName]
                if apost != nil {
                    //twelveList[dates!]?.append(apost!!) //UGLY syntax. Shame on you, Swift!!
                    array12.append(apost!!)
                }
            }
            twelveList[dates!] = array12
            
            
        }

        sortKeys = Array(twelveList.keys)
        let reverseSorter: (Date, Date) -> Bool = { $0.compare($1) == .orderedDescending }
        sortKeys = sortKeys.sorted(by: reverseSorter)

    }
    
    //thanks, stack overflow!
    //http://stackoverflow.com/questions/6141298/how-to-scale-down-a-uiimage-and-make-it-crispy-sharp-at-the-same-time-instead
    func resizeImage(_ image: UIImage, newSize: CGSize) -> (UIImage) {
        let newRect = CGRect(x: 0,y: 0, width: newSize.width, height: newSize.height).integral
        let imageRef = image.cgImage
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        // Set the quality level to use when rescaling
        context!.interpolationQuality = CGInterpolationQuality.high
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        
        context?.concatenate(flipVertical)
        // Draw into the context; this scales the image
        context?.draw(imageRef!, in: newRect)
        
        let newImageRef = (context?.makeImage()!)! as CGImage
        let newImage = UIImage(cgImage: newImageRef)
        
        // Get the resized image from the context and a UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func setVC(_ vc : ViewController) {
        self.parent = vc
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.init(red: 62.0/255.0, green: 82.0/255.0, blue: 121.0/255.0, alpha: 1.0)
        self.firstTime = true
        self.animating = false
        self.currentFrame = 0
        self.boingDegrees = 0
        self.rot = .ccw
        self.bounceBack = false
        
        //instead, we calculate today's date in UIViewController, as pass it in.
        /*let dateHelper1 = Date()
        let dateHelper2 = Calendar.current
        todaysDate = (dateHelper2 as NSCalendar).components([.day , .month , .year], from: dateHelper1)
        self.year =  todaysDate!.year
        self.month = todaysDate!.month
        self.day = todaysDate!.day*/
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //I don't think we ever call this initializer, but the compiler makes me put it here
    }

    func setDefaultImageSize() {
        bHeight = minorRadius! / 8;
        bWidth = bHeight! * 4 / 5;
    }
    
    func calculatePositions() -> ApostleLayout {
        var pp = ApostleLayout()
        if (year != 0) {
            var c = DateComponents()
            c.year = self.year!
            c.month = self.month!
            c.day = self.day!
            c.hour=0;c.minute=0;c.second=0;c.nanosecond=0
            
            let gregorian = Calendar(identifier:Calendar.Identifier.gregorian)
            date = gregorian.date(from: c)
            
            //log("New date is " + day + " " + month + " " + year);
            
            if twelveList[date!] == nil {
                for k in sortKeys {
                    if k.compare(date!) == .orderedAscending {
                        date = k
                        break
                    }
                }
            }
            pp.tweNumber = twelveList[date!]?.count//list.twelveList.get(date).size();
            pp.preNumber = presidencyList[date!]?.count//list.presidencyList.get(date).size();
        } else {
            pp.tweNumber = 12;
            pp.preNumber = 3;
        }
        
        // Find the width and height of the bitmap image, use RectF to scale it
        if (pp.preNumber > 6 && pp.preNumber <= 8) {
            bHeight = minorRadius! / 10;
            bWidth = bHeight! * 4 / 5;
        } else if (pp.preNumber == 9) {
            bHeight = minorRadius! / 11;
            bWidth = bHeight! * 5 / 6;
        } else {
            setDefaultImageSize();
        }
        
        //compute positions of quorum of twelve
        var radians = -PI_HALVES; //top of circle
        var increment : Float = 1
        if pp.tweNumber != nil {
            increment = Float(TWO_PI) / Float(pp.tweNumber!)
        }
        
        var fudge : Float = 0;    //for "spring back" when user tries to advance past current year
        let fudgeFactor = boingDegrees! / Float(pp.tweNumber!)
        
        quLines = CGMutablePath();
        for a in twelveList[date!]! {
            var pos = pp.positions[a];
            if (pos == nil) {
                pos = ApostlePosition();
                pp.positions[a] = pos
            }
            if (bouncing()) {
                pos!.grounded = true;
                //log("fudging " + a.getName() + " by " + fudge + " radians. Original=" + radians + " Fudged=" + (radians + fudge));
            }
            pos!.angle = radians + fudge;
            fudge += fudgeFactor;
            pos!.radius = Float(outerCircleRadius! + whiteCircleRadius!) / 2;
            let pictureCenterX = Float(cx!) + pos!.radius * cos(pos!.angle);
            let pictureCenterY = (Float(cy!) + pos!.radius * sin(pos!.angle));
            let spokeX = CGFloat(Float(cx!) + Float(outerCircleRadius!) * cos(pos!.angle + increment/2));
            let spokeY = CGFloat(Float(cy!) + Float(outerCircleRadius!) * sin(pos!.angle + increment/2));
            let posBoundsOriginX = pictureCenterX-Float(bWidth!)/2
            let posBoundsOriginY = pictureCenterY-Float(bHeight!)/2-Float(bHeight!)*0.1
            
            pos!.bounds.origin.x = CGFloat(posBoundsOriginX)
            pos!.bounds.origin.y = CGFloat(posBoundsOriginY)
            pos!.bounds.size.width = CGFloat(bWidth!)
            pos!.bounds.size.height = CGFloat(bHeight!)
            //Swift REALLY takes type safety overboard. Give me back my Java anyday!
 
            quLines!.move(to : CGPoint(x : cx!, y : cy!))
            quLines!.addLine(to : CGPoint(x : spokeX, y : spokeY))
            radians -= increment;
        }
        
        //compute positions of first presidency members
        fpLines = CGMutablePath();
        radians = -PI_HALVES; //top of circle
        increment = Float(TWO_PI) / Float(pp.preNumber!)
        for a in presidencyList[date!]! {
            var pos = pp.positions[a]
            if (pos == nil) {
                pos = ApostlePosition()
                pp.positions[a] = pos
            }
            pos!.angle = radians;
            //this is the swankiest ternary I've ever written!!
            pos!.radius = Float(innerCircleRadius!) * (pp.preNumber == 1 ? 0 : pp.preNumber == 2 ? 0.5 : pp.preNumber == 3 ? 0.55 : pp.preNumber == 4 ? 0.6 :       pp.preNumber! == 5 ? 0.65 : 0.7);
            let pictureCenterX = Float(cx!) + pos!.radius * cos(pos!.angle);
            let pictureCenterY = (Float(cy!) + pos!.radius * sin(pos!.angle));
            let spokeX = CGFloat(Float(cx!) + Float(innerCircleRadius!) * cos(pos!.angle + increment/2));
            let spokeY = CGFloat(Float(cy!) + Float(innerCircleRadius!) * sin(pos!.angle + increment/2));
            let posBoundsOriginX = pictureCenterX-Float(bWidth!)/2
            let posBoundsOriginY = pictureCenterY-Float(bHeight!)/2-Float(bHeight!)*0.1
            
            pos!.bounds.origin.x = CGFloat(posBoundsOriginX)
            pos!.bounds.origin.y = CGFloat(posBoundsOriginY)
            pos!.bounds.size.width = CGFloat(bWidth!)
            pos!.bounds.size.height = CGFloat(bHeight!)

            fpLines!.move(to : CGPoint(x : cx!, y : cy!))
            fpLines!.addLine(to : CGPoint(x : spokeX, y : spokeY))
            radians -= increment;
        }
        
        //TODO hack for 1833, where Joseph Smith had no counselors.
        /*if (list.presidencyList.get(date).size() == 1) {
            fpLines.reset();
        }*/
        
        return pp;
    }

    func goForward() -> Bool {
        //Log.d("CS203","This is a test for forward button");
        var i = sortKeys.firstIndex(of: date!);
        if (i == -1) {
            for k in sortKeys {
                if k.compare(date!) == .orderedAscending {
                    date = k
                    i = sortKeys.firstIndex(of: date!);
                    break;
                }
            }
        }
        if (i == 0) {
            return false;
        } else {
            if (i <= sortKeys.count) {
                date = sortKeys[i! - 1];
                let requestedComponents: Set<Calendar.Component> = [.year, .month, .day]
                let dateTimeComponents = Calendar.current.dateComponents(requestedComponents, from: date!)
                //print(date.debugDescription)
                year = dateTimeComponents.year;
                month = dateTimeComponents.month
                day = dateTimeComponents.day
                respondToDateChange();
            }
        }
        return true;
    }
    
    func goBack() {
        var i = sortKeys.firstIndex(of: date!);
        if (i == -1) {
            for k in sortKeys {
                if k.compare(date!) == .orderedAscending {
                    date = k
                    i = sortKeys.firstIndex(of: date!);
                    break;
                }
            }
        }
        if (i! >= 0) {
            date = sortKeys[i! + 1];
            let requestedComponents: Set<Calendar.Component> = [.year, .month, .day]
            let dateTimeComponents = Calendar.current.dateComponents(requestedComponents, from: date!)
            print(date.debugDescription)
            year = dateTimeComponents.year;
            month = dateTimeComponents.month
            day = dateTimeComponents.day
            respondToDateChange();
        }
    
    }
    
    func getCurrentEventDesc() -> String {
        return texts[date]!!
    }


    func bouncing() -> Bool {
        return boingDegrees != 0
    }
    
    func respondToDateChange() {
        //print("date change: ",year!)
        newLayout = calculatePositions();
        animating = diff();
        setNeedsDisplay()
    }
    
    func getDateString() -> String {
        let foo1 = String(day!) + " "
        let foo2 = months[month!] + " "
        let foo3 = String(year!)
        return foo1 + foo2 + foo3
    }

    override func draw(_ rect: CGRect) {
        if self.firstTime {
            sWidth = Int(bounds.width)
            let sHeight = Int(bounds.height)
            minorRadius = min(sWidth!,sHeight)//sWidth
            majorRadius = max(sWidth!,sHeight)//sHeight
            cx = CGFloat(sWidth!) / 2;
            cy = CGFloat(sHeight) / 2;
            let circleCenter = CGPoint(x:cx!, y:cy!)
            outerCircleRadius = CGFloat(minorRadius!) / 2.0
            whiteCircleRadius = CGFloat(minorRadius!)*0.21
            innerCircleRadius = CGFloat(minorRadius!)*0.19
            outerCircle = CGMutablePath()
            outerCircle!.addArc(center: circleCenter, radius: outerCircleRadius!, startAngle:0.0, endAngle: TWO_PI, clockwise: true)
            whiteCircle = CGMutablePath()
            whiteCircle!.addArc(center: circleCenter, radius: whiteCircleRadius!, startAngle:0.0, endAngle: TWO_PI, clockwise: true)
            innerCircle = CGMutablePath()
            innerCircle!.addArc(center: circleCenter, radius: innerCircleRadius!, startAngle:0.0, endAngle: TWO_PI, clockwise: true)
            setDefaultImageSize()
            self.loadApostles()
            self.loadEvents()
            currentLayout = calculatePositions();
            let fontSize = findThePerfectFontSize(rect.height * 0.015)
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = 0.0
            paraStyle.alignment = .center
            let skew = 0.1
            nameLabelFontAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.black,
                NSAttributedString.Key.paragraphStyle: paraStyle,
                NSAttributedString.Key.obliqueness: skew,
                NSAttributedString.Key.font: UIFont(name: "Helvetica Neue", size: fontSize)!
            ]
            toastFontAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.paragraphStyle: paraStyle,
                NSAttributedString.Key.obliqueness: 0,
                NSAttributedString.Key.font: UIFont(name: "Helvetica Neue", size: fontSize*1.5)!
            ]

            self.firstTime = false
        }
        
        let context = UIGraphicsGetCurrentContext()
        
        //draw outer circle
        let LTGRAY : CGFloat = 204.0/255.0
        context?.setFillColor(red: LTGRAY, green: LTGRAY, blue: LTGRAY, alpha: 1)
        context?.addPath(outerCircle!)
        context?.fillPath();
        if !(animating || bouncing()) {
            context?.addPath(quLines!);
            context?.setStrokeColor(red: 1,green: 1,blue: 1,alpha: 1);
            context?.strokePath();
        }
    
        
        //draw white circle
        context?.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context?.addPath(whiteCircle!)
        context?.fillPath();

        //draw inner circle
        context?.setFillColor(red: 189.0/255.0, green: 183.0/255.0, blue: 107.0/255.0, alpha: 1)
        context?.addPath(innerCircle!)
        context?.fillPath();
        if !(animating || bouncing()) {
            context?.addPath(fpLines!);
            context?.setStrokeColor(red: 1,green: 1,blue: 1,alpha: 1);
            context?.strokePath();
        }
        
        //print("Rendering " + String(currentLayout!.positions.keys.count) + " apostles")
        for ap in currentLayout!.positions.keys {
            
            //if we're animating, don't instantiate anything.
            let imgPos = currentLayout!.positions[ap]!.bounds;
            if (animating) {
                ap.photo.draw(in: imgPos)
            } else {
                let z = resizeImage(ap.photo, newSize: imgPos.size);
                z.draw(in: imgPos);
                
                //only draw names if we're not animating.
                if (!animating || bounceBack!) {
                    let textBounds = CGRect(x: imgPos.minX-imgPos.width/2, y: imgPos.maxY, width:imgPos.width*2, height: .greatestFiniteMagnitude)//imgPos.height/2)
                    ap.name.draw(in: textBounds, withAttributes:convertToOptionalNSAttributedStringKeyDictionary(nameLabelFontAttributes as? [String : Any]))
                }
            }
        }
        
        //display the "fake toast" message, if any
        //thank you to https://successfulcoder.com/2016/12/17/how-to-calculate-height-of-a-multiline-string-in-swift/
        //thank you to https://www.hackingwithswift.com/example-code/core-graphics/how-to-draw-a-text-string-using-core-graphics
        if (toastText != nil) {
            let padding = rect.width*0.025;
            let constraintRect = CGSize(width: rect.width-2*padding, height: .greatestFiniteMagnitude)
            let boundingBox = toastText!.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: toastFontAttributes as? [NSAttributedString.Key : Any], context: nil)
            context?.setFillColor(red: 68.0/255.0, green: 68.0/255.0, blue: 68.0/255.0, alpha: 155.0/255.0)
            let toastRect = CGMutablePath();
            toastRect.move(to: CGPoint(x: padding,y: padding*4))
            toastRect.addLine(to: CGPoint(x: rect.width-padding,y: padding*4))
            toastRect.addLine(to: CGPoint(x: rect.width-padding,y: padding*4+boundingBox.height))
            toastRect.addLine(to: CGPoint(x: padding,y: padding*4+boundingBox.height))
            context?.addPath(toastRect)
            context?.fillPath();
            toastText!.draw(with: CGRect(x: padding*2,y: padding*4, width: rect.width-padding*4, height: boundingBox.height), options: .usesLineFragmentOrigin, attributes: toastFontAttributes as? [NSAttributedString.Key : Any], context: nil)
        }
    }
    
    func findThePerfectFontSize(_ dim : CGFloat) -> CGFloat {
        var fontSize : CGFloat = 1;
        var p = UIFont(name: "Helvetica Neue", size: fontSize)
        while (true) {
            let asc = p?.ascender;
            if (asc > dim) {
                break;
            }
            fontSize += 1;
            p = UIFont(name: "Helvetica Neue", size: fontSize)
        }
        return fontSize;
    }
    
    func diff() -> Bool {
        //sanity check. Get out if we don't have anything to draw.
        if (currentLayout == nil) {
            return false
        }

        currentFrame = 0;
        deltas = [Apostle : Delta]()
        /*
         * for each apostle:
         * either in old chart
         * or new chart
         * or in both
         * if in old but not new:
         *     fly off the screen
         * if in new but not old
         *  fly onto screen
         * if in both
         *  if moving from FP to FP
         *    rotate radially
         *  if moving from 12 to 12
         *    rotate radially
         *  if moving from 12 to FP
         *    move linearly from old to new
         *  if moving from 12 to 12
         *    move linearly from old to new
         *  If a picture is currently "flying" around the screen, it should
         *  either be moving towards the circles or away from them. If it's part of
         *  newlayout then move towards circle; if not, then fly away.
         */
        //print ("diff 2")
        for a in currentLayout!.positions.keys {
            //print ("diff 3: " + a.name)
            let oldPos = currentLayout?.positions[a];
            let d = Delta();
            if (newLayout?.positions[a] != nil) {
                //print("diff 4 " + a.name)
                //this apostle is staying on-screen, just move him
                let newPos = newLayout?.positions[a];
                //this apostle is in both old and new layouts
                if (oldPos?.grounded)! && (oldPos?.radius == newPos?.radius) {
                    //the apostle has not changed quorums, rotate
                    //print(newPos?.angle)
                    //print(oldPos?.angle)
                    d.dAngle = ((newPos?.angle)! - (oldPos?.angle)!) / FRAMES;
                    //let degreeString = String((newPos?.angle)! - (oldPos?.angle)!)
                    //print("need to move " + a.name + " by " + degreeString + " degrees.")
                } else {
                    //the apostle is moving from one quorum to another, move linearly.
                    d.dPos = CGPoint(x:((newPos?.bounds.minX)! - (oldPos?.bounds.minX)!)/CGFloat(FRAMES),y:((newPos?.bounds.minY)! - (oldPos?.bounds.minY)!)/CGFloat(FRAMES));
                    oldPos?.grounded = false;
                    //print("move him linearly")
                }
            } else {
                //this apostle is in the old but not the new,
                //so move radially outward like an explosion.
                //print("move him explosion-style")
                var theta = -atan2((oldPos?.bounds.midX)!-cx!, (oldPos?.bounds.midY)!-cy!);
                if (rot == .cw) {
                    theta += CGFloat.pi;
                }
                let radius = Double(majorRadius!)*0.75;
                let pictureCenterX = (cx! + CGFloat(radius) * cos(theta))
                let pictureCenterY = (cy! + CGFloat(radius) * sin(theta));
                let newPos = CGRect(x:pictureCenterX-CGFloat(bWidth!)/2, y:pictureCenterY-CGFloat(bHeight!)/2-CGFloat(bHeight!)*0.1, width:CGFloat(bWidth!), height:CGFloat(bHeight!));
                d.dPos = CGPoint(x:(newPos.minX - (oldPos?.bounds.minX)!)/CGFloat(FRAMES), y:(newPos.minY - (oldPos?.bounds.minY)!)/CGFloat(FRAMES));
                oldPos?.grounded = false;

            }
            deltas[a] = d
        }
        for a in (newLayout?.positions.keys)! {
            //print("diff 5: " + a.name)
            if currentLayout?.positions[a] == nil {
                //this is a new apostle, fly on-screen
                //print ("Diff 6: fly on screen")
                let oldPos = ApostlePosition();
                let newPos = newLayout?.positions[a]
                //if the new position is on the right-hand side of the screen, fly from right to left.
                //if the new position is on the left-hand side of the screen, fly from left to right.
                if (newPos?.bounds.midX < CGFloat(sWidth!/2)) {
                    oldPos.bounds = CGRect(x:-bWidth!, y:Int(newPos!.bounds.minY), width:bWidth!, height:bHeight!)
                } else {
                    oldPos.bounds = CGRect(x:sWidth!, y:Int(newPos!.bounds.minY), width:bWidth!, height:bHeight!)
                }

                currentLayout?.positions[a] = oldPos
                let d = Delta()
                d.dPos = CGPoint(x:((newPos?.bounds.minX)! - oldPos.bounds.minX)/CGFloat(FRAMES),y:((newPos?.bounds.minY)! - oldPos.bounds.minY)/CGFloat(FRAMES));
                deltas[a] = d
            }
        }

        //sanity check: was there actually any change?
        var changed = false;
        //print("checking deltas...")
        for d in deltas.values {
            if d.isNull() == false {
                changed = true;
                //print ("changed true")
                break
            }
        }
        return changed;
    }

    
    func onTick() {
        if (animating) {
            for ap in (currentLayout?.positions.keys)! {
                let d = deltas[ap]
                if (d?.dPos == nil) {
                    //move it angularly, not linearly
                    let radius = currentLayout?.positions[ap]?.radius;
                    //kludgy workaround for Swift's not allowing me to += the angle directly
                    let tmpAngle = currentLayout?.positions[ap]
                    tmpAngle?.angle = (tmpAngle?.angle)! + (d?.dAngle!)!
                    let angle = tmpAngle?.angle
                    //let angle = (currentLayout?.positions[ap]?.angle)! += (d?.dAngle!)!
                    let pictureCenterX = cx! + CGFloat(radius! * cos(angle!))
                    let pictureCenterY = cy! + CGFloat(radius! * sin(angle!))
                    //FIXME can I set these fields without instantiating a new CGRect object?
                    //print(currentLayout?.positions[ap]?.bounds)
                    currentLayout?.positions[ap]?.bounds = CGRect(x:pictureCenterX-CGFloat(bWidth!/2),y:pictureCenterY-CGFloat(bHeight!/2)-CGFloat(Double(bHeight!)*0.1),width:CGFloat(bWidth!),height:CGFloat(bHeight!))
                    //print(currentLayout?.positions[ap]?.bounds)
                } else {
                    currentLayout?.positions[ap]?.bounds = (currentLayout?.positions[ap]?.bounds.offsetBy(dx: (d?.dPos?.x)!, dy: (d?.dPos?.y)!))!
                    //print(currentLayout?.positions[ap]?.bounds)
                }
            }
            currentFrame = currentFrame!+1;
            if (currentFrame > Int(FRAMES)) {
                animating = false;
                bounceBack = false;
                currentLayout = newLayout;
                //every apostle is "grounded" at this point.
                for ap in (currentLayout?.positions.values)! {
                    ap.grounded = true;
                }
            }
            setNeedsDisplay()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //print("touchdown!")
        let touch: UITouch! = touches.first as UITouch?
        touchDown = touch.location(in: self)
        if (toastText != nil) {
            toastText = nil
            setNeedsDisplay()
        }
        //print(touchDown)
        downRadius = Float(hypot((touchDown?.x)!-cx!, (touchDown?.y)!-cy!));
        oldDegrees = Float(atan2((touchDown?.y)!-cy!, (touchDown?.x)!-cx!));
        
    }
    
    func signum(_ foo : Float) -> Int {
        if (foo < 0) {
            return -1;
        } else if (foo > 0) {
            return 1;
        } else {
            return 0;
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch: UITouch! = touches.first as UITouch?
        let p = touch.location(in: self)
        if (touchDown != nil) {
            if (downRadius! >= Float(innerCircleRadius!)/2 && downRadius <= Float(outerCircleRadius!)) {
                var degreeDelta : Float = 0;
                let curRadius = hypot(p.x-cx!, p.y-cy!);
                let degree = Float(atan2(p.y-cy!, p.x-cx!));
                if (curRadius >= innerCircleRadius!/2 && curRadius <= outerCircleRadius) {
                    //hack - check for pi to -pi switchover,
                    //keep velocity and direction constant
                    if (signum(oldDegrees!) == signum(degree)) {
                        degreeDelta = degree - oldDegrees!;
                        if (degree < oldDegrees) {
                            //clockwise, move forward in time
                            if (year <= parent!.currentYear) {
                                rot = Rotation.ccw;
                            }
                        } else {
                            if (year! >= Int(parent!.STARTING_YEAR)) {
                                rot = Rotation.cw;
                            }
                        }
                    } else {
                        if (rot == Rotation.cw) {
                            //crossing from positive PI to negative PI
                            if (oldDegrees > degree) {
                                degreeDelta = ((PI-oldDegrees!) + (PI + degree));
                            } else {
                                degreeDelta = abs(oldDegrees!) + degree;
                            }
                        } else {
                            //crossing from negative PI to positive PI
                            if (oldDegrees < degree) {
                                degreeDelta = ((-PI-oldDegrees!) - (PI - degree));
                            } else {
                                degreeDelta = -(abs(degree) + oldDegrees!);
                            }
                        }
                        //log("crossing the border! old="+oldDegrees + "; new=" + degree + "; delta=" + Math.toDegrees(degreeDelta));
                    }
                    let yearDelta = Int(degreeDelta * (50 / PI))//50 years = half circle
                    var newYear = year! + yearDelta
                    if (newYear > parent!.currentYear) {
                        boingDegrees = boingDegrees! + degreeDelta
                        currentLayout = calculatePositions()
                        setNeedsDisplay()
                        //log("peering into the future! " + Math.toDegrees(boingDegrees));
                    }
                    newYear = max(newYear, Int(parent!.STARTING_YEAR))
                    newYear = min(newYear, parent!.currentYear)
                    //print("new year: ",newYear)
                    if (!bouncing()) {
                        parent!.setYear(newYear)
                    }
                    oldDegrees = degree;
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //print("touch up!")
        let touch: UITouch! = touches.first as UITouch?
        let p = touch.location(in: self)
        
        if (boingDegrees != 0) {
            boingDegrees = 0;
            bounceBack = true;
            //log("ready to bounce back!");
            respondToDateChange();
        }
        
        //was this a simple single tap? check by calculating distance
        //between down and up event.
        let dx = p.x-(touchDown?.x)!
        let dy = p.y-(touchDown?.y)!
        let dist = sqrt(dx*dx+dy*dy)
        if (dist < (CGFloat(minorRadius!) / 50.0)) {
            //finger did not move much, consider it a tap.
            for ap in (currentLayout?.positions.keys)! {
                let image = currentLayout?.positions[ap]?.bounds
                if (image?.contains(p))! {
                    //popup a dialog box
                    let bioURL = Bundle.main.url(forResource: ap.bio, withExtension: "")!
                    let bioText = try! String(contentsOf: bioURL, encoding: String.Encoding.isoLatin1)
                    //print(bioText)
                    let alert = UIAlertController(
                        title: ap.name, message: bioText, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                    break;
                }
            }
        }
        touchDown = nil;
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
