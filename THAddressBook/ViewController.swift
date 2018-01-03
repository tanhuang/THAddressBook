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

    let users: [User]

    static func executeCommand(state: TableViewEditingCommandsViewModel, command: TableViewEditingCommand) -> TableViewEditingCommandsViewModel {
        switch command {
        case let .setUsers(users: users):
            return TableViewEditingCommandsViewModel(users: users)
        case let .deleteUser(indexPath: indexpath):
            var all = [state.users]
            all[indexpath.section].remove(at: indexpath.row)
            return TableViewEditingCommandsViewModel(users: all[0])
        case let .moveUser(from: from, to: to):
            var all = [state.users]
            let user = all[from.section][from.row]
            all[from.section].remove(at: from.row)
            all[to.section].insert(user, at: to.row)
            return TableViewEditingCommandsViewModel(users: all[0])
        case let .addUser(user: user):
            var all = [state.users]
            all[0].insert(user, at: 0)
            return TableViewEditingCommandsViewModel(users: all[0])
        }
    }
}


enum TableViewEditingCommand {
    case setUsers(users: [User])
    case deleteUser(indexPath: IndexPath)
    case moveUser(from: IndexPath, to: IndexPath)
    case addUser(user: User)
}


class ViewController: UIViewController, UITableViewDelegate {

    let dataSource = ViewController.configureDataSource()

    var disposeBag = DisposeBag()

    var tableView: UITableView!

    let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)

#if TRACE_RESOURCES
    private let startResourceCount = RxSwift.Resources.total
#endif

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "通讯录"

        #if TRACE_RESOURCES
            print("Number of start resources = \(Resources.total)")
        #endif



        configTableView()

        typealias Feedback = (ObservableSchedulerContext<TableViewEditingCommandsViewModel>) -> Observable<TableViewEditingCommand>

        navigationItem.rightBarButtonItem = self.editButtonItem
        navigationItem.leftBarButtonItem = self.addButtonItem

        let superMan = User(name: "东方不败", iphone: "1888888888")
        let watMan = User(name: "西方不败", iphone: "1888888888")


        let initialLoadCommand = Observable.just(
                TableViewEditingCommand.setUsers(users: [superMan, watMan])
            )
            .observeOn(MainScheduler.instance)

        let uiFeedback: Feedback = bind(self) { (this, state) -> (Bindings<TableViewEditingCommand>) in
            let subscriptions = [
                state.map { [SectionModel(model: "Users", items: $0.users)] }
                    .bind(to: this.tableView.rx.items(dataSource: this.dataSource)),
                this.tableView.rx.itemSelected
                    .withLatestFrom(state) { i, latestState in
                        this.tableView.deselectRow(at: i, animated: true)
                        let all = [latestState.users]
                        return all[i.section][i.row]
                    }
                    .subscribe(onNext: { (user) in
                        self.showDetailsForUser(user: user)
                    }),

            ]

            let events: [Observable<TableViewEditingCommand>] = [
                this.tableView.rx.itemDeleted.map(
                    TableViewEditingCommand.deleteUser
                ),
                this.tableView.rx.itemMoved.map({ val in
                    return TableViewEditingCommand.moveUser(from: val.0, to: val.1)
                }),

                this.addButtonItem.rx.tap.map({ _ in
                    return TableViewEditingCommand.addUser(user: User(name: "不败", iphone: "1888888888"))
                })
            ]

            return Bindings(subscriptions: subscriptions, events: events)
        }

        let initialLoadFeedback: Feedback = {_ in initialLoadCommand }

        Observable.system(
            initialState: TableViewEditingCommandsViewModel(users: []),
            reduce: TableViewEditingCommandsViewModel.executeCommand,
            scheduler: MainScheduler.instance,
            scheduledFeedback: [uiFeedback, initialLoadFeedback]
        )
            .subscribe()
            .disposed(by: disposeBag)

        tableView.rx.setDelegate(self).disposed(by: disposeBag)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.isEditing = editing
    }

    func showDetailsForUser(user: User) {
        debugPrint("\(user)")
    }

    func configTableView() {
        tableView = UITableView.init(frame: view.bounds)
        tableView.backgroundColor = UIColor.lightText
        tableView.rowHeight = 44
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        view.addSubview(tableView)
    }

    static func configureDataSource() -> RxTableViewSectionedReloadDataSource<SectionModel<String, User>> {

        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, User>>(
            configureCell: { (dataSource, tableview, indexPath, user: User) -> UITableViewCell in
                var cell = tableview.dequeueReusableCell(withIdentifier: "THAddressBookCell")
                if cell == nil {
                    cell = UITableViewCell.init(style: UITableViewCellStyle.value1, reuseIdentifier: "THAddressBookCell")
                }
                cell?.textLabel?.text = user.name
                cell?.detailTextLabel?.text = user.iphone
                return cell!
            },
            canEditRowAtIndexPath: { (dataSource, indexPath) -> Bool in
                return true
            },
            canMoveRowAtIndexPath: { (dataSource, indexPath) -> Bool in
                return true
            }
        )
        return dataSource
    }
}








