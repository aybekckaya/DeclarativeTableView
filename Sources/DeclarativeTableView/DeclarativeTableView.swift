//
//  TableView.swift
//  DeclarativeTableView
//
//  Created by Aybek Can Kaya on 24.07.2021.
//

import Foundation
import UIKit


/**
  ScrollView Delegates ++
  Editing styles ++
  Drag drop capability
 */

// MARK: - Item Identifiable
public protocol ItemIdentifiable {
    var identifier: String { get }
}

// MARK: - TableView { Skeleton }
public class TableView: UITableView {
    private var items: [ItemIdentifiable] = []
    private var automaticallyAdjustHeight: Bool = false
    private var cellHeight: CGFloat = 0
    private var cellSelectionStyle: UITableViewCell.SelectionStyle = .default
    
    private var cellAtIndexClosure: ((TableView, IndexPath, ItemIdentifiable)->(UITableViewCell))?
    private var cellHeightAtIndexClosure: ((TableView, IndexPath, ItemIdentifiable)->(CGFloat))?
    private var cellDidSelectedAtIndexClosure: ((TableView, IndexPath, ItemIdentifiable)->())?
    private var tableDidScrollClosure: ((TableView, CGPoint)->())?
    private var tableVisibleCellsClosure: ((TableView, [UITableViewCell])->())?
    private var tableWillEndDraggingClosure: ((TableView, CGPoint, UnsafeMutablePointer<CGPoint>)->())?
    private var cellCanEditClosure: ((TableView, IndexPath, ItemIdentifiable)->(Bool))?
    private var tableLeadingSwipeActionClosure: ((TableView, IndexPath, ItemIdentifiable)->(UISwipeActionsConfiguration?))?
    private var tableTrailingSwipeActionClosure: ((TableView, IndexPath, ItemIdentifiable)->(UISwipeActionsConfiguration?))?
    
    public init() {
        super.init(frame: .zero, style: .plain)
        setUpUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Set Up UI
extension TableView {
    private func setUpUI() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.delegate = self
        self.dataSource = self
    }
}

// MARK: - Public
extension TableView {

    public func reloadTableView(with items: [ItemIdentifiable]) {
        DispatchQueue.main.async {
            self.items = items
            self.reloadData()
            self.callVisibleCellsClosureIfNeeded()
        }
    }
    
    @discardableResult
    public func cellAtIndex(_ closure: @escaping (TableView, IndexPath, ItemIdentifiable)->(UITableViewCell)) -> TableView {
        cellAtIndexClosure = closure
        return self
    }
    
    @discardableResult
    public func cellHeightAtIndex(_ closure: @escaping (TableView, IndexPath, ItemIdentifiable)->(CGFloat)) -> TableView {
        cellHeightAtIndexClosure = closure
        return self
    }
    
    @discardableResult
    public func cellDidSelectedAtIndex(_ closure: @escaping (TableView, IndexPath, ItemIdentifiable)->()) -> TableView {
        cellDidSelectedAtIndexClosure = closure
        return self
    }
    
    @discardableResult
    public func didScroll(_ closure: @escaping ((TableView, CGPoint) -> ()) ) -> TableView {
        self.tableDidScrollClosure = closure
        return self
    }
    
    @discardableResult
    public func visibleCells(_ closure: @escaping ((TableView, [UITableViewCell])->()) ) -> TableView {
        self.tableVisibleCellsClosure = closure
        return self
    }
    
    @discardableResult
    public func willEndDragging(_ closure: @escaping ((TableView, CGPoint, UnsafeMutablePointer<CGPoint>)->()) ) -> TableView {
        self.tableWillEndDraggingClosure = closure
        return self
    }
    
    @discardableResult
    public func canEditCell(_ closure: @escaping ((TableView, IndexPath, ItemIdentifiable)->(Bool)) ) -> TableView {
        self.cellCanEditClosure = closure
        return self
    }
    
    @discardableResult
    public func leadingSwipeAction(_ closure: @escaping ((TableView, IndexPath, ItemIdentifiable)->(UISwipeActionsConfiguration?)) ) -> TableView {
        self.tableLeadingSwipeActionClosure = closure
        return self
    }
    
    @discardableResult
    public func trailingSwipeAction(_ closure: @escaping ((TableView, IndexPath, ItemIdentifiable)->(UISwipeActionsConfiguration?)) ) -> TableView {
        self.tableTrailingSwipeActionClosure = closure
        return self
    }
}

// MARK: - DataSource / Delegate
extension TableView: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let closure = self.cellAtIndexClosure else { return UITableViewCell() }
        let cell = closure(self, indexPath, items[indexPath.row])
        cell.selectionStyle = cellSelectionStyle
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.automaticallyAdjustHeight == true { return UITableView.automaticDimension }
        guard let closure = self.cellHeightAtIndexClosure else { return cellHeight }
        return closure(self, indexPath, items[indexPath.row])
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let closure = cellDidSelectedAtIndexClosure else { return }
        closure(self, indexPath, items[indexPath.row])
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        callDidScrollClosureIfNeeded()
        callVisibleCellsClosureIfNeeded()
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let closure = self.tableWillEndDraggingClosure else { return }
        closure(self, velocity, targetContentOffset)
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let closure = self.cellCanEditClosure else { return false }
        return closure(self, indexPath, items[indexPath.row])
    }
    
    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let closure = self.tableLeadingSwipeActionClosure else { return nil }
        return closure(self, indexPath, items[indexPath.row])
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let closure = self.tableTrailingSwipeActionClosure else { return nil }
        return closure(self, indexPath, items[indexPath.row])
    }
   
}

// MARK: - Helpers
extension TableView {
    private func callDidScrollClosureIfNeeded() {
        guard let closure = tableDidScrollClosure else { return }
        closure(self, self.contentOffset)
    }
    
    private func callVisibleCellsClosureIfNeeded() {
        guard let closure = tableVisibleCellsClosure else { return }
        closure(self, self.visibleCells)
    }
}

// MARK: - Declarative UI
extension TableView {
    public static func declarativeTableView() -> TableView {
        let table = TableView()
        return table
    }
    
    @discardableResult
    public func automaticallyAdjustHeight(_ automaticHeightEnabled: Bool) -> TableView {
        self.automaticallyAdjustHeight = automaticHeightEnabled
        return self
    }
    
    @discardableResult
    public func cellHeight(_ height: CGFloat) -> TableView {
        self.cellHeight = height
        return self
    }
    
    @discardableResult
    public func cellSelectionStyle(_ style: UITableViewCell.SelectionStyle) -> TableView {
        self.cellSelectionStyle = style
        return self
    }
}

extension UIView {
    public func asDeclarativeTableView() -> TableView {
        return self as! TableView
    }
}

