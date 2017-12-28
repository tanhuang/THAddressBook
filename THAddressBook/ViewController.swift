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
/*
 Another way to do "MVVM". There are different ideas what does MVVM mean depending on your background.
 It's kind of similar like FRP.

 In the end, it doesn't really matter what jargon are you using.

 This would be the ideal case, but it's really hard to model complex views this way
 because it's not possible to observe partial model changes.
 另一种方法来做“MVVM”。 有不同的想法什么MVVM根据您的背景意思。
 这有点像FRP。

 最后，你使用什么术语并不重要。

 这将是理想的情况，但以这种方式建模复杂的视图是非常困难的
 因为不可能观察到部分模型变化。
 */

struct TableViewEditingCommandsViewModel {
    let favoriteUsers: [User]
    let users: [User]

    static func executeCommand(state: TableViewEditingCommandsViewModel, command: TableViewEditingCommand) -> TableViewEditingCommandsViewModel {
        switch command {
        case let .setUsers(users: users):
            return TableViewEditingCommandsViewModel(favoriteUsers: state.favoriteUsers, users: users)
        case let .setFavoriteUsers(favoriteUsers: favoriteUsers):
            return TableViewEditingCommandsViewModel(favoriteUsers: favoriteUsers, users: state.users)
        case let .deleteUser(indexPath: indexpath):
            var all = [state.favoriteUsers, state.users]
            all[indexpath.section].remove(at: indexpath.row)
            return TableViewEditingCommandsViewModel(favoriteUsers: all[0], users: all[1])
        case let .moveUser(from: from, to: to):
            var all = [state.favoriteUsers, state.users]
            let user = all[from.section][from.row]
            all[from.section].remove(at: from.row)
            all[to.section].insert(user, at: to.row)

            return TableViewEditingCommandsViewModel(favoriteUsers: all[0], users: all[1])
        }
    }
}


enum TableViewEditingCommand {
    case setUsers(users: [User])
    case setFavoriteUsers(favoriteUsers: [User])
    case deleteUser(indexPath: IndexPath)
    case moveUser(from: IndexPath, to: IndexPath)
//    case addUser(user: [User])
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

        typealias Feedback = (ObservableSchedulerContext<TableViewEditingCommandsViewModel>) -> Observable<TableViewEditingCommand>

        navigationItem.rightBarButtonItem = self.editButtonItem

        let superMan = User.init(name: "东方不败", iphone: "1888888888", image: "东")
        let watMan = User.init(name: "西方不败", iphone: "1888888888", image: "西")

        let initialLoadCommand = Observable.just(TableViewEditingCommand.setFavoriteUsers(favoriteUsers: [superMan, watMan]))
            .observeOn(MainScheduler.instance)

//        let uiFeedback: Feedback = bind(self) {
//            
//
//
//        }


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








