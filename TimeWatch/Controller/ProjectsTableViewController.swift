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
    var timerOn = false
    var currentTimer = 0
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView(frame: CGRect.zero)
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
        cell?.detailTextLabel?.text = "\(currentTimer)"
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.textLabel?.text = ""
//        if !timerOn {
//            timerOn = true
//            //let cell = tableView.cellForRow(at: indexPath)
//            scheduledTimerWithTimeInterval()
//        }
//        else{
//            timerOn = false
//            timer.invalidate()
//        }
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
        currentTimer += 1
        tableView.reloadData()
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
        appDelegate.saveContext()
        projectsArray.append(newProject)
        let index = IndexPath(row: projectsArray.count - 1, section: 0)
        tableView.beginUpdates()
        tableView.insertRows(at: [index], with: .left)
        tableView.endUpdates()
    }
}
