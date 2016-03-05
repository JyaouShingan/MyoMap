//
//  ViewController.swift
//  MyoMap
//
//  Created by Peter Chen on 2016-03-04.
//  Copyright © 2016 Peter Chen. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	@IBOutlet weak var myoSettings: UIButton!
	var myoManager: MyoManager!

	override func viewDidLoad() {
		super.viewDidLoad()

		self.myoManager = MyoManager()
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@IBAction func openMyoSettings(sender: UIButton) {
		self.myoManager.openMyoSettings(presentController: self)
	}
}

