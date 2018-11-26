//
//  MissionsTableViewController.swift
//  PostMishone
//
//  Created by Victor Liang on 2018-11-07.
//  Copyright © 2018 Victor Liang. All rights reserved.
//

import UIKit



class MissionsTableViewController: UITableViewController {
    
    let menuItems = ["My Missions", "Accepted Missions"]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = menuItems[indexPath.row]

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.row == 0) {
            performSegue(withIdentifier: "toMyMissions", sender: self)
        }
        if(indexPath.row == 1) {
            performSegue(withIdentifier: "toMyAcceptedMissions", sender: self)
        }
    }


}
