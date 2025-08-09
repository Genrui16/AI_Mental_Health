import Foundation
import CoreData

/// 管理 Core Data 持久化容器，包含两种事件实体：ActualEvent 与 SuggestedEvent。
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // 定义模型
        let model = NSManagedObjectModel()

        // 实际事件实体
        let actualEntity = NSEntityDescription()
        actualEntity.name = "ActualEvent"
        actualEntity.managedObjectClassName = NSStringFromClass(ActualEvent.self)
        var actualProperties: [NSPropertyDescription] = []

        let actualId = NSAttributeDescription()
        actualId.name = "id"
        actualId.attributeType = .UUIDAttributeType
        actualId.isOptional = false
        actualProperties.append(actualId)

        let actualTime = NSAttributeDescription()
        actualTime.name = "time"
        actualTime.attributeType = .dateAttributeType
        actualTime.isOptional = false
        actualProperties.append(actualTime)

        let actualTitle = NSAttributeDescription()
        actualTitle.name = "title"
        actualTitle.attributeType = .stringAttributeType
        actualTitle.isOptional = false
        actualProperties.append(actualTitle)

        let actualNotes = NSAttributeDescription()
        actualNotes.name = "notes"
        actualNotes.attributeType = .stringAttributeType
        actualNotes.isOptional = true
        actualProperties.append(actualNotes)

        actualEntity.properties = actualProperties

        // 建议事件实体
        let suggestedEntity = NSEntityDescription()
        suggestedEntity.name = "SuggestedEvent"
        suggestedEntity.managedObjectClassName = NSStringFromClass(SuggestedEvent.self)
        var suggestedProperties: [NSPropertyDescription] = []

        let suggestedId = NSAttributeDescription()
        suggestedId.name = "id"
        suggestedId.attributeType = .UUIDAttributeType
        suggestedId.isOptional = false
        suggestedProperties.append(suggestedId)

        let suggestedTime = NSAttributeDescription()
        suggestedTime.name = "time"
        suggestedTime.attributeType = .dateAttributeType
        suggestedTime.isOptional = false
        suggestedProperties.append(suggestedTime)

        let suggestedTitle = NSAttributeDescription()
        suggestedTitle.name = "title"
        suggestedTitle.attributeType = .stringAttributeType
        suggestedTitle.isOptional = false
        suggestedProperties.append(suggestedTitle)

        let suggestedNotes = NSAttributeDescription()
        suggestedNotes.name = "notes"
        suggestedNotes.attributeType = .stringAttributeType
        suggestedNotes.isOptional = true
        suggestedProperties.append(suggestedNotes)

        suggestedEntity.properties = suggestedProperties

        model.entities = [actualEntity, suggestedEntity]

        container = NSPersistentContainer(name: "ScheduleModel", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// MARK: - Managed Object Subclasses

@objc(ActualEvent)
public class ActualEvent: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var time: Date
    @NSManaged public var title: String
    @NSManaged public var notes: String?
}

@objc(SuggestedEvent)
public class SuggestedEvent: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var time: Date
    @NSManaged public var title: String
    @NSManaged public var notes: String?
}

