//
//  MasterViewController.swift
//  HKTutorial
//
//  Created by ernesto on 18/10/14.
//  Copyright (c) 2014 rayaaawenderlich. All rights reserved.
//

import Foundation

import UIKit


class MasterViewController: UITableViewController {
  
  let kAuthorizeHealthKitSection = 2
  let kProfileSegueIdentifier = "profileSegue"
  let kWorkoutSegueIdentifier = "workoutsSeque"
  
  let healthManager:HealthManager = HealthManager()
  
  
  func authorizeHealthKit()
  {
    healthManager.authorizeHealthKit {
      (authorized,  error) -> Void in
        if authorized {
          println("HealthKit authorization received.")
        }
        else
        {
          println("HealthKit authorization denied!")
          if error != nil {
            println("\(error)")
          }
        }
    }
  }
  
  
  // MARK: - Segues
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier ==  kProfileSegueIdentifier {
      
      if let profileViewController = segue.destinationViewController as? ProfileViewController {
        profileViewController.healthManager = healthManager
      }
    }
    else if segue.identifier == kWorkoutSegueIdentifier {
      if let workoutViewController = segue.destinationViewController.topViewController as? WorkoutsTableViewController {
        workoutViewController.healthManager = healthManager;
      }
    }
  }
  
  // MARK: - TableView Delegate
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    switch (indexPath.section, indexPath.row)
    {
    case (kAuthorizeHealthKitSection,0):
      authorizeHealthKit()
    default:
      break
    }
    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  
  
}
