//
//  RecomendationViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/9/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

class RecomendationViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView?
    
    var users: [UserData]?
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}

extension RecomendationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.identifier, for: indexPath) as! UserCell
        if let item = users?[indexPath.row] {
            cell.configure(imagePath: item.profile_pic_url, name: item.full_name, username: item.username)
        }
        return cell
        
//        return UITableViewCell()
    }
    
}
