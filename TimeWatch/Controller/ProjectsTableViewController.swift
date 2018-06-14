//
//  ProjectsTableViewController.swift
//  TimeWatch
//
//  Created by Peter Pascual on 5/28/18.
//  Copyright © 2018 Peter Pascual. All rights reserved.
//

import UIKit

class ProjectsTableViewController: UITableViewController {
    
    var projectsArray = [Project]()
    var timer = Timer()
    var trackingTime = false
    var currentTimer = 0
    var selectedProject: Project?
    var currentDateData: DateData?
    var wentToBackground: Date?
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        //Much love to Paul Hudson https://www.hackingwithswift.com/example-code/system/how-to-detect-when-your-app-moves-to-the-background
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)

        loadProjects()
    }
    
    @IBAction func addNewProjectBtn(_ sender: Any) {
        addNewProject()
    }
    
    func addNewProject(){
        var textField = UITextField()
        let alert = UIAlertController(title: "Add new Project", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add Project", style: .default){ (action) in
            self.newProject(named: textField.text!)
            self.tableView.reloadData()
        }
        
        alert.addTextField { (alertTextFrield) in
            alertTextFrield.placeholder = "New Project"
            textField = alertTextFrield
        }
        
        alert.addAction(action)
        present(alert,animated: true, completion: nil)
        
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return projectsArray.count
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell")
        let project = projectsArray[indexPath.row]
        cell?.textLabel?.text = project.name
        cell?.detailTextLabel?.text = "\(secondsToStringtime(seconds: project.getTotalTimeSpent()))"
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.textLabel?.text = ""
        selectedProject = projectsArray[indexPath.row]
        if let today = selectedProject?.getToday(with: getDate()){
            currentDateData = today
        }
        else{
            newDay(for: selectedProject!)
        }
        timerToggle()
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let projectToDel = projectsArray[indexPath.row]
            context.delete(projectToDel)
            projectsArray.remove(at: indexPath.row)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            appDelegate.saveContext()
        }
    }
    
    //MARK: - Time management
    
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCounting), userInfo: nil, repeats: true)
    }
    
    @objc func updateCounting(){
        if let currentDateData = currentDateData{
            currentDateData.seconds += 1
        }
        tableView.reloadData()
    }
    

    
    func timerToggle() {
        if !trackingTime {
            trackingTime = true
            scheduledTimerWithTimeInterval()
        }
        else{
            trackingTime = false
            timer.invalidate()
        }
    }
    

    func secondsToTime (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    func secondsToStringtime(seconds: Int) -> String {
        let (h,m,s) = secondsToTime(seconds: seconds)
        return String(format:"%02i:%02i:%02i", h,m,s)
        
    }
    //MARK: - Data management.
    
    func loadProjects(){
        do {
            projectsArray = try context.fetch(Project.fetchRequest())
        } catch let error  as NSError{
            print("Failed to feth any projects. \(error), \(error.userInfo)")
        }
    }
    
    func newProject(named name : String = "Project") {
        let newProject = Project(entity: Project.entity(), insertInto: context)
        newProject.name = name
        projectsArray.append(newProject)
        newDay(for: newProject)
        appDelegate.saveContext()
        let index = IndexPath(row: projectsArray.count - 1, section: 0)
        tableView.beginUpdates()
        tableView.insertRows(at: [index], with: .left)
        tableView.endUpdates()
    }
    func newDay(for project: Project){
        let newDateData = DateData(entity: DateData.entity(), insertInto: context)
        newDateData.name = getDate()
        newDateData.parentProject = project
    }
    
    func getDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: Date())
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = "MMM-dd-yyyy"
        let myStringafd = formatter.string(from: yourDate!)
        return myStringafd
    }
}
protocol backgroundDelegate {
    func gotoBackground()
    func comeFromBackground()
    
}
extension ProjectsTableViewController{

    @objc func appMovedToBackground() {
        wentToBackground = Date()
    }
    @objc func appMovedToForeground() {
        if let wentToBackground = wentToBackground{
            let elapsedTime = wentToBackground.timeIntervalSince(Date())
            if let dateTime = currentDateData{
                dateTime.seconds += Int32(abs(elapsedTime))
            }
            print(elapsedTime)
        }
    }
    
}

extension Project{
    func getTotalTimeSpent() -> Int {
        var seconds = 0
        for days in day?.allObjects as! [DateData]{
            //print("\(days.parentProject?.name)\(days.name) with seconds \(days.seconds)")
            seconds += Int(days.seconds)
        }
        return seconds
    }
    func getToday(with today: String) -> DateData? {
        for day in day?.allObjects as! [DateData]{
            if day.name == today{
                return day
            }
        }
        return nil
    }
}

