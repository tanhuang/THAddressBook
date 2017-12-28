//
//  ViewController.swift
//  THAddressBook
//
//  Created by 希达 on 2017/12/27.
//  Copyright © 2017年 Tan.huang. All rights reserved.
//

import UIKit

import RxCocoa
import RxSwift
import RxDataSources


enum TableViewEditingCommand {
    case setUsers(users: [User])
    case setFavoriteUsers(favoriteUsers: [User])
    case deleteUser(indexPath: IndexPath)
    case moveUser(from: IndexPath, to: IndexPath)
    case addUser(user: [User])
}





class ViewController: UIViewController, UITableViewDelegate {

    let dataSource = ViewController.configureDataSource

    lazy var tableView: UITableView = {
        let tableview = UITableView.init(frame: view.bounds)
        tableview.backgroundColor = UIColor.lightText
        tableview.rowHeight = 44
        tableview.estimatedRowHeight = 0
        tableview.estimatedSectionFooterHeight = 0
        tableview.estimatedSectionHeaderHeight = 0
        view.addSubview(tableview)
        return tableview
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "通讯录"

        let superMan = User.init(name: "东方不败", iphone: "1888888888", image: "东")
        let watMan = User.init(name: "西方不败", iphone: "1888888888", image: "西")

        let loadFavoriteUsers = rando



    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    static func configureDataSource() -> RxTableViewSectionedReloadDataSource<SectionModel<String, User>> {
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, User>>(
            configureCell: { (_, tableview, indexPath, user: User)  in
                let cell = tableview.dequeueReusableCell(withIdentifier: "THAddressBookCell")
                cell?.textLabel?.text = user.name
                cell?.detailTextLabel?.text = user.iphone
                cell?.imageView?.image = UIImage.init(named: user.image)
                return cell!
            },
            canEditRowAtIndexPath: { (ds, idnexPath) in
                return true
            },
            canMoveRowAtIndexPath: {_,_ in
                return true
            }
        )
        return dataSource
    }
}








