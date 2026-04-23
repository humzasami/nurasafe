// Hand-maintained to match ObjectBox Swift generator output (see objectbox-swift Example/generated).
// Stores knowledge chunk text in ObjectBox; E5 vectors remain in VectorStore. For HNSW on-device,
// run the ObjectBox plugin on Tools/ObjectBoxModel and merge the generated embedding property.
//
// swiftlint:disable all
import Foundation
import ObjectBox

// MARK: - Entity metadata

extension KnowledgeVectorEntity: ObjectBox.Entity {}

extension KnowledgeVectorEntity: ObjectBox.__EntityRelatable {
    internal typealias EntityType = KnowledgeVectorEntity

    internal var _id: EntityId<KnowledgeVectorEntity> {
        EntityId<KnowledgeVectorEntity>(self.id.value)
    }
}

extension KnowledgeVectorEntity: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = KnowledgeVectorEntityBinding

    internal static let entityInfo = ObjectBox.EntityInfo(name: "KnowledgeVectorEntity", id: 1)

    internal static let entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(
            for: KnowledgeVectorEntity.self,
            id: 1,
            uid: 7_733_445_566_778_899_001
        )
        try entityBuilder.addProperty(
            name: "id",
            type: PropertyType.long,
            flags: [.id],
            id: 1,
            uid: 7_733_445_566_778_899_011
        )
        try entityBuilder.addProperty(
            name: "chunkId",
            type: PropertyType.string,
            id: 2,
            uid: 7_733_445_566_778_899_012
        )
        try entityBuilder.addProperty(
            name: "scenario",
            type: PropertyType.string,
            id: 3,
            uid: 7_733_445_566_778_899_013
        )
        try entityBuilder.addProperty(
            name: "title",
            type: PropertyType.string,
            id: 4,
            uid: 7_733_445_566_778_899_014
        )
        try entityBuilder.addProperty(
            name: "content",
            type: PropertyType.string,
            id: 5,
            uid: 7_733_445_566_778_899_015
        )

        try entityBuilder.lastProperty(id: 5, uid: 7_733_445_566_778_899_015)
    }
}

extension KnowledgeVectorEntity {
    internal static var id: ObjectBox.Property<KnowledgeVectorEntity, Id, Void> {
        ObjectBox.Property(propertyId: 1, isPrimaryKey: true)
    }

    internal static var chunkId: ObjectBox.Property<KnowledgeVectorEntity, String, Void> {
        ObjectBox.Property(propertyId: 2, isPrimaryKey: false)
    }

    internal static var scenario: ObjectBox.Property<KnowledgeVectorEntity, String, Void> {
        ObjectBox.Property(propertyId: 3, isPrimaryKey: false)
    }

    internal static var title: ObjectBox.Property<KnowledgeVectorEntity, String, Void> {
        ObjectBox.Property(propertyId: 4, isPrimaryKey: false)
    }

    internal static var content: ObjectBox.Property<KnowledgeVectorEntity, String, Void> {
        ObjectBox.Property(propertyId: 5, isPrimaryKey: false)
    }

    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == KnowledgeVectorEntity {
    internal static var id: ObjectBox.Property<KnowledgeVectorEntity, Id, Void> {
        ObjectBox.Property(propertyId: 1, isPrimaryKey: true)
    }

    internal static var chunkId: ObjectBox.Property<KnowledgeVectorEntity, String, Void> {
        ObjectBox.Property(propertyId: 2, isPrimaryKey: false)
    }

    internal static var scenario: ObjectBox.Property<KnowledgeVectorEntity, String, Void> {
        ObjectBox.Property(propertyId: 3, isPrimaryKey: false)
    }

    internal static var title: ObjectBox.Property<KnowledgeVectorEntity, String, Void> {
        ObjectBox.Property(propertyId: 4, isPrimaryKey: false)
    }

    internal static var content: ObjectBox.Property<KnowledgeVectorEntity, String, Void> {
        ObjectBox.Property(propertyId: 5, isPrimaryKey: false)
    }
}

internal final class KnowledgeVectorEntityBinding: ObjectBox.EntityBinding, Sendable {
    internal typealias EntityType = KnowledgeVectorEntity
    internal typealias IdType = Id

    internal required init() {}

    internal func generatorBindingVersion() -> Int { 1 }

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        entity.id.value
    }

    internal func collect(
        fromEntity entity: EntityType,
        id: ObjectBox.Id,
        propertyCollector: ObjectBox.FlatBufferBuilder,
        store: ObjectBox.Store
    ) throws {
        let offsetChunkId = propertyCollector.prepare(string: entity.chunkId)
        let offsetScenario = propertyCollector.prepare(string: entity.scenario)
        let offsetTitle = propertyCollector.prepare(string: entity.title)
        let offsetContent = propertyCollector.prepare(string: entity.content)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(dataOffset: offsetChunkId, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: offsetScenario, at: 2 + 2 * 3)
        propertyCollector.collect(dataOffset: offsetTitle, at: 2 + 2 * 4)
        propertyCollector.collect(dataOffset: offsetContent, at: 2 + 2 * 5)
    }

    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = KnowledgeVectorEntity()
        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.chunkId = entityReader.read(at: 2 + 2 * 2)
        entity.scenario = entityReader.read(at: 2 + 2 * 3)
        entity.title = entityReader.read(at: 2 + 2 * 4)
        entity.content = entityReader.read(at: 2 + 2 * 5)
        return entity
    }
}

// MARK: - Store setup

fileprivate func cModel() throws -> OpaquePointer {
    let modelBuilder = try ObjectBox.ModelBuilder()
    try KnowledgeVectorEntity.buildEntity(modelBuilder: modelBuilder)
    modelBuilder.lastEntity(id: 1, uid: 7_733_445_566_778_899_001)
    return modelBuilder.finish()
}

extension ObjectBox.Store {
    internal convenience init(
        directoryPath: String,
        maxDbSizeInKByte: UInt64 = 1024 * 1024,
        fileMode: UInt32 = 0o644,
        maxReaders: UInt32 = 0,
        readOnly: Bool = false
    ) throws {
        try self.init(
            model: try cModel(),
            directory: directoryPath,
            maxDbSizeInKByte: maxDbSizeInKByte,
            fileMode: fileMode,
            maxReaders: maxReaders,
            readOnly: readOnly
        )
    }
}

// swiftlint:enable all
