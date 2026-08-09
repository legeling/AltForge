//
//  UpdatePatronsOperation.swift
//  AltStore
//
//  Created by Riley Testut on 4/11/22.
//  Copyright © 2022 Riley Testut. All rights reserved.
//

import CoreData

import AltStoreCore

class UpdatePatronsOperation: ResultOperation<Void>, @unchecked Sendable
{
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = DatabaseManager.shared.persistentContainer.newBackgroundContext())
    {
        self.context = context
    }
    
    override func main()
    {
        super.main()
        self.finish(.success(()))
    }
}
