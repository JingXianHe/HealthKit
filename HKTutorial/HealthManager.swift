//
//  HealthManager.swift
//  HKTutorial
//
//  Created by ernesto on 18/10/14.
//  Copyright (c) 2014 raywenderlich. All rights reserved.
//

import Foundation
import HealthKit
class HealthManager {
  let healthKitStore:HKHealthStore = HKHealthStore()
  func authorizeHealthKit(completion: ((success:Bool, error:NSError!) -> Void)!)
  {

    // 1. Set the types you want to share from HK Store
    let shareTypes : Set = [HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
      HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
      HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!,
      HKSampleType.workoutType()!
    ]
    
    // 2. Set the types you want to read to HK Store
    let readTypes : Set = [HKCharacteristicType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!,
        HKCharacteristicType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType)!,
      HKCharacteristicType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!,
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass),
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight),
      HKObjectType.workoutType()
    ]
    
    // 3. If the store is not available (for instance, iPad) return an error and don't go on.
    if !HKHealthStore.isHealthDataAvailable()
    {
      let error = NSError(domain: "com.raywenderlich.tutorials.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available in this Device"])
      if( completion != nil )
      {
        completion(success:false, error:error)
      }
      return;
    }
    
    // 4.  Request HealthKit authorization

    healthKitStore.requestAuthorizationToShareTypes(shareTypes, readTypes:readTypes, completion: { (success, error) -> Void in
      if( completion != nil )
      {
        completion(success:success,error:error)
      }
    })
  }
  func readProfile() -> ( age:Int?,  biologicalsex:HKBiologicalSexObject?, bloodtype:HKBloodTypeObject?)
  {
    var error:NSError?
    var age:Int?
    
    // 1. Request birthday and calculate age
    if let birthDay = healthKitStore.dateOfBirthWithError(&error)
    {
      let today = NSDate()
      let calendar = NSCalendar.currentCalendar()
      let differenceComponents = NSCalendar.currentCalendar().components(.CalendarUnitYear, fromDate: birthDay, toDate: today, options: NSCalendarOptions(0) )
      age = differenceComponents.year
    }
    if error != nil {
      println("Error reading Birthday: \(error)")
    }
    
    // 2. Read biological sex
    var biologicalSex:HKBiologicalSexObject? = healthKitStore.biologicalSexWithError(&error);
    if error != nil {
      println("Error reading Biological Sex: \(error)")
    }
    // 3. Read blood type
    var bloodType:HKBloodTypeObject? = healthKitStore.bloodTypeWithError(&error);
    if error != nil {
      println("Error reading Blood Type: \(error)")
    }
    
    // 4. Return the information read in a tuple
    return (age, biologicalSex, bloodType)
  }
  func readMostRecentSample(sampleType:HKSampleType , completion: ((HKSample!, NSError!) -> Void)!)
  {
    
    // 1. Build the Predicate
    let past = NSDate.distantPast() as! NSDate
    let now   = NSDate()
    let mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate:now, options: .None)
    
    // 2. Build the sort descriptor to return the samples in descending order
    let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
    // 3. we want to limit the number of samples returned by the query to just 1 (the most recent)
    let limit = 1
    
    // 4. Build samples query
    let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
      { (sampleQuery, results, error ) -> Void in
        
        if let queryError = error {
          completion(nil,error)
          return;
        }
        
        // Get the first sample
        let mostRecentSample = results.first as? HKQuantitySample
        
        // Execute the completion closure
        if completion != nil {
          completion(mostRecentSample,nil)
        }
    }
    // 5. Execute the Query
    self.healthKitStore.executeQuery(sampleQuery)
  }
  func saveBMISample(bmi:Double, date:NSDate ) {
    
    // 1. Create a BMI Sample
    let bmiType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)
    let bmiQuantity = HKQuantity(unit: HKUnit.countUnit(), doubleValue: bmi)
    let bmiSample = HKQuantitySample(type: bmiType, quantity: bmiQuantity, startDate: date, endDate: date)
    
    // 2. Save the sample in the store
    healthKitStore.saveObject(bmiSample, withCompletion: { (success, error) -> Void in
      if( error != nil ) {
        println("Error saving BMI sample: \(error.localizedDescription)")
      } else {
        println("BMI sample saved successfully!")
      }
    })
  }
  func saveRunningWorkout(startDate:NSDate , endDate:NSDate , distance:Double, distanceUnit:HKUnit , kiloCalories:Double,
    completion: ( (Bool, NSError!) -> Void)!) {
      
      // 1. Create quantities for the distance and energy burned
      let distanceQuantity = HKQuantity(unit: distanceUnit, doubleValue: distance)
      let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: kiloCalories)
      
      // 2. Save Running Workout
      let workout = HKWorkout(activityType: HKWorkoutActivityType.Running, startDate: startDate, endDate: endDate, duration: abs(endDate.timeIntervalSinceDate(startDate)), totalEnergyBurned: caloriesQuantity, totalDistance: distanceQuantity, metadata: nil)
      healthKitStore.saveObject(workout, withCompletion: { (success, error) -> Void in
        if( error != nil  ) {
          // Error saving the workout
          completion(success,error)
        }
        else {
          // if success, then save the associated samples so that they appear in the Health Store
          let distanceSample = HKQuantitySample(type: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning), quantity: distanceQuantity, startDate: startDate, endDate: endDate)
          let caloriesSample = HKQuantitySample(type: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned), quantity: caloriesQuantity, startDate: startDate, endDate: endDate)
          
          self.healthKitStore.addSamples([distanceSample,caloriesSample], toWorkout: workout, completion: { (success, error ) -> Void in
            completion(success, error)
          })
          
        }
      })
  }
  func readRunningWorkOuts(completion: (([AnyObject]!, NSError!) -> Void)!) {
    
    // 1. Predicate to read only running workouts
    let predicate =  HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.Running)
    // 2. Order the workouts by date
    let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
    // 3. Create the query
    let sampleQuery = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor])
      { (sampleQuery, results, error ) -> Void in
        
        if let queryError = error {
          println( "There was an error while reading the samples: \(queryError.localizedDescription)")
        }
        completion(results,error)
    }
    // 4. Execute the query
    healthKitStore.executeQuery(sampleQuery)
    
  }
}