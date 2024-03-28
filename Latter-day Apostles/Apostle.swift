//
//  Apostle.swift
//  Latter-day Apostles
//
//  Created by Geoffrey Draper on 11/29/23.
//

import Foundation
import UIKit

class Apostle : Hashable {
    var name : String
    var bio : String
    var birth : String
    var death : String
    var photo : UIImage!
    var id : Int
    
    var hashValue: Int {
        return self.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    init(id:Int, name:String, birth:String, death:String, photo:UIImage, bioFile:String) {
        self.name = name
        self.bio = /*"assets/" + */bioFile //TODO
        self.birth = birth
        self.death = death
        self.photo = photo
        self.id = id
    }
    
    func printInfo() {
        print("name: " + self.name + ", birth: " + self.birth + ", death: " + self.death)
    }
    
}

func ==(lhs: Apostle, rhs: Apostle) -> Bool {
    return lhs.id == rhs.id
}
