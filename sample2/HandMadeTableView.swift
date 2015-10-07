//
//  HandMadeTableView.swift
//  PerfectMVC
//
//  Created by 山崎友弘 on 2015/09/03.
//  Copyright (c) 2015年 yamasaki. All rights reserved.
//

import UIKit

@objc protocol HMTableViewDelegate:NSObjectProtocol,UIScrollViewDelegate{
    optional func tableView(tableView: HMTableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
}

@objc protocol HMTableViewDataSource:NSObjectProtocol{
    func tableView(tableView: HMTableView, numberOfRowsInSection section: Int) -> Int
    func tableView(tableView: HMTableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
}

class HMTableView: UIScrollView ,UIScrollViewDelegate{
    weak var hmDelegate: HMTableViewDelegate?
    weak var hmDataSource:HMTableViewDataSource?
    
    private var _cellHeight:CGFloat = 50
    private var _cellNum = 0
    private var _cellList:[AnyObject] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
        backgroundColor = UIColor.lightGrayColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // セルをタッチ
    func didTouch(button:UIButton){
        for (var a = 0;a < _cellList.count; a++ ){
            var cellDic = _cellList[a] as! [String:AnyObject]
            let saveButton = cellDic["button"] as! UIButton
            if(saveButton == button){
                let index = cellDic["index"] as! Int
                
                if (hmDelegate?.respondsToSelector("tableView:didSelectRowAtIndexPath:") == true){
                    hmDelegate!.tableView!(self, didSelectRowAtIndexPath: NSIndexPath(forRow: index, inSection: 0))
                }
            }
        }
        
    }

    // こいつでテーブル更新
    func reloadData(){
        if (hmDataSource?.respondsToSelector("tableView:numberOfRowsInSection:") == true){
            _cellNum = hmDataSource!.tableView(self, numberOfRowsInSection: 0)
        }
        self.contentSize = CGSizeMake(self.contentSize.width, CGFloat(_cellNum) * _cellHeight)
        
        
        var startCellIndex = 0
        var endCellIndex = 0
        setTableCellRange(&startCellIndex, endIndex: &endCellIndex)
        
        if (endCellIndex >= 0){
            for (var i = startCellIndex; i <= endCellIndex; i++) {
                var cell:UITableViewCell = hmDataSource!.tableView(self, cellForRowAtIndexPath: NSIndexPath(forRow: i, inSection: 0))
                cell.center = CGPointMake(self.frame.width / 2,CGFloat(i) * _cellHeight + _cellHeight / 2)
                self.addSubview(cell)
            }
        }
    }
    
    //再利用できるセルを返す、ない場合は、新たに作って返す
    func dequeueReusableCell() -> UITableViewCell{
        for (var i = 0;i < _cellList.count; i++ ){
            let cellDic = _cellList[i] as! [String:AnyObject]
            let isEnabled = cellDic["isEnabled"] as! Bool
            if(isEnabled == true){
                return cellDic["cell"] as! UITableViewCell
            }
        }
        let cell = UITableViewCell()
        cell.backgroundColor = UIColor.whiteColor()
        return cell
    }
    
    // MARK: - scrillViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        updateCellList()
    }
    
    // MARK: - privateMethod
    private func setTableCellRange(inout startIndex:Int,inout endIndex:Int){
        var startCellIndex = Int(self.contentOffset.y / _cellHeight)
        var endCellIndex = Int((self.contentOffset.y + self.frame.height) / _cellHeight)
        if (endCellIndex > _cellNum - 1){
            endCellIndex = _cellNum - 1
        }
        
        if (endCellIndex < 0){
            startCellIndex = _cellNum - 1
        }else{
            startCellIndex = 0
        }
        startIndex = startCellIndex
        endIndex = endCellIndex
    }
    
    private func updateCellList(){
        var startCellIndex = 0
        var endCellIndex = 0
        setTableCellRange(&startCellIndex, endIndex: &endCellIndex)
        
        
        if (hmDataSource?.respondsToSelector("tableView:cellForRowAtIndexPath:") == true){
            
            //画面外に出たセルを検出し、Viewからリムーブする
            for (var a = 0;a < _cellList.count; a++ ){
                var cellDic = _cellList[a] as! [String:AnyObject]
                let isEnabled = cellDic["isEnabled"] as! Bool
                let cellIndex = cellDic["index"] as! Int
                //再利用できる状態であれば、
                if(isEnabled == true){
                    continue
                }
                if((cellIndex < startCellIndex || cellIndex > endCellIndex) || ( startCellIndex < 0 && endCellIndex < 0) ){
                    //画面の範囲外に出ているのでリムーブ
                    let cell = cellDic["cell"] as! UITableViewCell
                    cell.removeFromSuperview()
                    cellDic["isEnabled"] = true
                    _cellList[a] = cellDic
                }
            }

            if(endCellIndex >= 0){
                for(var i = startCellIndex; i <= endCellIndex; i++){
                    var isExist:Bool = false
                    for (var a = 0;a < _cellList.count; a++ ){
                        var cellDic = _cellList[a] as! [String:AnyObject]
                        let cellIndex = cellDic["index"] as! Int
                        let isEnabled = cellDic["isEnabled"] as! Bool
                        if(cellIndex == i && isEnabled == false){
                            isExist = true
                            break
                        }
                    }
                    
                    if (isExist == true){
                        continue
                    }
                    var cell:UITableViewCell = hmDataSource!.tableView(self, cellForRowAtIndexPath: NSIndexPath(forRow: i, inSection: 0))
                    cell.center = CGPointMake(self.frame.width / 2,CGFloat(i) * _cellHeight + _cellHeight / 2)
                    
                    self.addSubview(cell)
                    
                    var a:Int = 0
                    for (a = 0;a < _cellList.count; a++ ){
                        var cellDic = _cellList[a] as! [String:AnyObject]
                        let saveCell = cellDic["cell"] as! UITableViewCell
                        if(saveCell == cell){
                            break
                        }
                    }
                    
                    var listCount:Int = _cellList.count
                    if (listCount == a){
                        //保存されていない
                        var cellDic:[String:AnyObject] = [:]
                        cellDic["isEnabled"] = false
                        cellDic["cell"] = cell
                        cellDic["index"] = i
                        let button = UIButton(frame: CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height))
                        cell.addSubview(button)
                        button.addTarget(self, action: "didTouch:", forControlEvents: UIControlEvents.TouchUpInside)
                        cellDic["button"] = button
                        _cellList.append(cellDic)
                    }else{
                        //保存している
                        var cellDic = _cellList[a] as! [String:AnyObject]
                        
                        cellDic["isEnabled"] = false
                        cellDic["cell"] = cell
                        cellDic["index"] = i
                        _cellList[a] = cellDic
                    }
                }
            }
        }
    }
}







