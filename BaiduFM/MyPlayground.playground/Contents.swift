//: Playground - noun: a place where people can play

import UIKit
var str:String = "Hello, playground"

//xcode6.3 & swift1.2

//1. 可选绑定if let的语法优化
//2. 类型转化as用法的变化
//3. 新增原生set(集合)类型
//4. 常量延迟初始化
//5. 与OC的互动和桥接
//6. 迁移助手  Edit=>Convert=>To Latest Swift Syntax

//1.可选绑定if let的语法优化
var wea:String? = "rain"
var sh:String? = "sun"
var tmp:Int? = 20

if let weather = wea where "rain".isEmpty, let shanghai = sh, let temp=tmp{
    //update ui
    println("update UI")
}

//2. 类型转化as用法的变化 NSObject=>UIView=>UITableView

// 向上转换 UITableView=> NSObject    直接as
// 向下转换 NSObject=>UITableView  确定 as!(强制转换)   不确定as?(安全转换)

//3. 新增原生set(集合)类型

var people:Set = ["头发","鼻子","耳朵","头发"]
var dog:Set = ["鼻子","耳朵","尾巴"]

//插入元素
people.insert("脚")

//删除元素
people.remove("脚")

people

//交集
people.intersect(dog)

//差集
people.subtract(dog)

//并集
people.union(dog)

//补集
people.exclusiveOr(dog)

//4. 常量延迟初始化 only for class or struct
struct Point{
    var x:Int
    var y:Int
}
//lazy var players:Point = Point(x: 10, y: 5)









