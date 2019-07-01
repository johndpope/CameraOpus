//
//  ModelTableViewCell.swift
//  CameraOpus
//
//  Created by Abheek Basu on 6/15/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//

import UIKit

class ModelTableViewCell: UITableViewCell {

    
    @IBOutlet weak var cellLabel: UILabel!
    
    @IBOutlet weak var showButton: UIButton!
    
    @IBAction func showModel(_ sender: UIButton) {
        //open up the model with the lable name
    }
    
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//
//    }
    
//    init(name: String){
//        cellLabel.text = name
//    }
    
//    required init?(coder decoder: NSCoder) {
//        super.init(coder: decoder)
//    }
    

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
