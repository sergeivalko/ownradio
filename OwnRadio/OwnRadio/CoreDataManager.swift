//
//  CoreDataManager.swift
//  OwnRadio
//
//  Created by Roman Litoshko on 12/1/16.
//  Copyright © 2016 Roll'n'Code. All rights reserved.
//

import CoreData
import Foundation

class CoreDataManager {
	
	// Singleton
	static let instance = CoreDataManager()
	
	private init() {}
	
	// Entity for Name
	func entityForName(entityName: String) -> NSEntityDescription {
		return NSEntityDescription.entity(forEntityName: entityName, in: self.managedObjectContext)!
	}
	
//	 Fetched Results Controller for Entity Name
//	func fetchedResultsControllerForHistory( keyForSort: String) -> NSFetchedResultsController<HIstoryEntity> {
//		
//		let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName:"HIstoryEntity")
//		let sortDescriptor = NSSortDescriptor(key: keyForSort, ascending: true)
//		fetchRequest.sortDescriptors = [sortDescriptor]
//		
//		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.instance.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
//		
//		return fetchedResultsController as! NSFetchedResultsController<HIstoryEntity>
//	}
	
	func getAllEntitiesFor(entityName:String) -> [Any] {
		let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName:entityName)
		var fetchRequest = [Any]()
		do {
			fetchRequest = try self.managedObjectContext.fetch(request)
		} catch {
			fatalError("Failed to fetch : \(error)")
		}
		return fetchRequest
	}
	
	// MARK: - Core Data stack
	
	lazy var applicationDocumentsDirectory: NSURL = {
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return urls[urls.count-1] as NSURL
	}()
	
	lazy var managedObjectModel: NSManagedObjectModel = {
		let modelURL = Bundle.main.url(forResource: "DataModel", withExtension: "momd")!
		return NSManagedObjectModel(contentsOf: modelURL)!
	}()
	
	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
		var failureReason = "There was an error creating or loading the application's saved data."
		do {
			try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
		} catch {
			var dict = [String: AnyObject]()
			dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
			dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
			dict[NSUnderlyingErrorKey] = error as NSError
			let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
			NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
			abort()
		}
		
		return coordinator
	}()
	
	lazy var managedObjectContext: NSManagedObjectContext = {
		let coordinator = self.persistentStoreCoordinator
		var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = coordinator
		return managedObjectContext
	}()
	
	
	func chekCountOfEntitiesFor(entityName:String) -> Int {
		let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName:entityName)
		var count = 0
		do{
			 count = try self.managedObjectContext.count(for: request)
	
		}catch {
			print("Error with get count of entities")
		}
		
		return count
	}
	
	func deleteHistoryFor(trackID:String) {
		let fetchRequest: NSFetchRequest<HIstoryEntity> = HIstoryEntity.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "trackId = %@", trackID)
		if let result = try? self.managedObjectContext.fetch(fetchRequest) {
			for object in result {
				self.managedObjectContext.delete(object)
			}
		}
	}
	
	func sentHistory (){
		//create a fetch request, telling it about the entity
		let fetchRequest: NSFetchRequest<HIstoryEntity> = HIstoryEntity.fetchRequest()
		
		do {
			//go get the results
			
			let searchResults = try self.managedObjectContext.fetch(fetchRequest)
			
			for track in searchResults {
				
				ApiService.shared.saveHistory(trackId: track.trackId!, isListen: Int(track.isListen))
				
//				print("\(track.value(forKey: "trackId"))")
			}
					} catch {
			print("Error with request: \(error)")
		}
	}
	
	
	// MARK: - Core Data Saving support
	
	func saveContext () {
		if managedObjectContext.hasChanges {
			do {
				try managedObjectContext.save()
			} catch {
				let nserror = error as NSError
				NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
				abort()
			}
		}
	}
	
}
