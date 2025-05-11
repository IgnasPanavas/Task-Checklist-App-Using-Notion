import Foundation
import WidgetKit
import SwiftUI
import SwiftUICore
import Combine

struct NotionBlockResponse: Codable {
    let results: [NotionBlock]
}

struct NotionBlock: Codable {
    let id: String
    let type: String

    let paragraph: ParagraphContent?
    let heading_1: HeadingContent?
    let heading_2: HeadingContent?
    let heading_3: HeadingContent?
    var to_do: ToDoContent?
    let bulleted_list_item: ListItemContent?

    struct ParagraphContent: Codable {
        let rich_text: [RichTextObject]
    }

    struct HeadingContent: Codable {
        let rich_text: [RichTextObject]
    }

    struct ListItemContent: Codable {
        let rich_text: [RichTextObject]
    }

    struct ToDoContent: Codable {
        let rich_text: [RichTextObject]
        var checked: Bool?
    }

    struct RichTextObject: Codable {
        let plain_text: String
    }
}

struct NotionDatabaseQueryResponse: Codable {
    let results: [NotionPage]
}

struct NotionPage: Codable {
    let id: String
    let properties: [String: NotionProperty]
}

struct NotionProperty: Codable {
    let id: String
    let type: String

    let title: [TextObject]?
    let date: DateObject?

    struct TextObject: Codable {
        let plain_text: String
    }

    struct DateObject: Codable {
        let start: String?
        let end: String?
    }
}


struct NotionSearchResponse: Codable {
    let results: [Database]
}

// Database object
struct Database: Codable {
    let id: String
    let object: String
    let title: [RichText]?
}

// Represents the entire database schema
struct DatabaseSchema: Codable {
    let properties: [String: DatabaseProperty]
}
// Title has no nested configuration, but Notion still returns an empty object
struct TitleConfiguration: Codable {}

struct DateConfiguration: Codable {
    // Notion date configuration is usually empty, but add this in case it changes
}

// Represents each property in the database schema
struct DatabaseProperty: Codable {
    let id: String
    let name: String
    let type: String
    let configuration: PropertyConfiguration

    // Custom decoding to handle dynamic keys based on the 'type' field
    private enum CodingKeys: String, CodingKey {
        case id, name, type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)

        // Decode the configuration based on the 'type' field
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKeys.self)
        if let configKey = DynamicCodingKeys(stringValue: type),
           let configValue = try? dynamicContainer.decode(PropertyConfiguration.self, forKey: configKey) {
            configuration = configValue
        } else {
            configuration = .unsupported
        }
    }
}

enum PropertyConfiguration: Codable {
    case title(TitleConfiguration)
    case date(DateConfiguration)
    case number(NumberConfiguration)
    case select(SelectConfiguration)
    case multiSelect(MultiSelectConfiguration)
    case unsupported

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try known types in order
        if let value = try? container.decode(TitleConfiguration.self) {
            self = .title(value)
        } else if let value = try? container.decode(DateConfiguration.self) {
            self = .date(value)
        } else if let value = try? container.decode(NumberConfiguration.self) {
            self = .number(value)
        } else if let value = try? container.decode(SelectConfiguration.self) {
            self = .select(value)
        } else if let value = try? container.decode(MultiSelectConfiguration.self) {
            self = .multiSelect(value)
        } else {
            self = .unsupported
        }
    }

    func encode(to encoder: Encoder) throws {
        // optional – implement if you plan to encode back
    }
}


// Represents the configuration for 'number' type properties
struct NumberConfiguration: Codable {
    let format: String
}

// Represents the configuration for 'select' type properties
struct SelectConfiguration: Codable {
    let options: [SelectOption]
}

// Represents the configuration for 'multi_select' type properties
struct MultiSelectConfiguration: Codable {
    let options: [SelectOption]
}

// Represents an option in 'select' or 'multi_select' properties
struct SelectOption: Codable {
    let id: String
    let name: String
    let color: String
}

// Helper struct to handle dynamic keys
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }
    init?(intValue: Int) { nil }
}


// RichText object for the title
struct RichText: Codable {
    let plain_text: String
}

struct ErrorResponse: Codable, Error {
    let error: String
    let status_code: Int
}

@MainActor
public class NotionManager: ObservableObject {
    let base_endpoint: String = Bundle.main.infoDictionary?["API_BASE_ENDPOINT"] as! String
    let token: String = Bundle.main.infoDictionary?["NOTION_SECRET"] as! String
    @AppStorage("notion_db_name") var db_name: String = ""
    
    @Published var database_id: String = ""
    @Published var isInitialized = false
    
    @Published var habits: [NotionBlock] = []
    
    // MARK: - Combined Flow
    init() {
            Task {
                do {
                    let id = try await get_database_id()
                    self.database_id = id
                    self.isInitialized = true  // ✅ trigger dependent views
                    print("✅ Notion initialized with DB ID: \(id)")
                } catch {
                    print("❌ Failed to initialize NotionManager: \(error)")
                }
            }
        }

    // MARK: - Individual Steps

    func get_database_id() async throws -> String {
        let endpoint = "\(base_endpoint)search"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.setValue("close", forHTTPHeaderField: "Connection")
        
        let json: [String: Any] = [
            "query": db_name,
            "filter": ["value": "database", "property": "object"],
            "sort": ["direction": "ascending", "timestamp": "last_edited_time"]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: json, options: [])

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        let result = try decoder.decode(NotionSearchResponse.self, from: data)
        
        guard let dbID = result.results.first?.id else {
            throw NSError(domain: "No database found", code: 404)
        }
        
        return dbID
    }

    func get_db_schema() async throws -> DatabaseSchema {
        let endpoint = "\(base_endpoint)databases/\(database_id)"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.setValue("close", forHTTPHeaderField: "Connection")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        return try decoder.decode(DatabaseSchema.self, from: data)
    }
    
    func getPagesInDatabase() async throws -> [NotionPage] {
        let endpoint = "https://api.notion.com/v1/databases/\(database_id)/query"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(NotionDatabaseQueryResponse.self, from: data)
        return decoded.results
    }
    
    func getPage(by id: String) async throws -> NotionPage {
        let endpoint = "https://api.notion.com/v1/pages/\(id)"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        return try decoder.decode(NotionPage.self, from: data)
    }
    
    func getFirstPageID() async throws -> String {
        let pages = try await getPagesInDatabase()
        
        guard let first = pages.first else {
            throw NSError(domain: "No pages found", code: 0)
        }

        return first.id
    }
    
    func getPageBlocks(pageID: String) async throws -> [NotionBlock] {
        let url = URL(string: "https://api.notion.com/v1/blocks/\(pageID)/children")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(NotionBlockResponse.self, from: data)
        return decoded.results
    }

    func getBlocksFromFirstPage() async throws -> [NotionBlock] {
        // Step 1: Fetch pages in the database
        let pages = try await getPagesInDatabase()
        
        // Step 2: Use the first page (if exists)
        guard let firstPage = pages.first else {
            throw NSError(domain: "No pages found in database", code: 0)
        }

        // Step 3: Fetch blocks from that page
        return try await getPageBlocks(pageID: firstPage.id)
    }
    
    func toggleHabit(block: NotionBlock) async throws {
        guard block.type == "to_do", let todo = block.to_do else { return }

        let blockID = block.id
        let endpoint = "https://api.notion.com/v1/blocks/\(blockID)"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")

        // ✅ Use the actual checked value from the updated block
        let body: [String: Any] = [
            "to_do": [
                "checked": todo.checked ?? false
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Failed to update block", code: 1)
        }
    }
    
    func refreshHabits() async throws {

        let blocks = try await getBlocksFromFirstPage()
        let todos = blocks.filter { $0.type == "to_do" }

        await MainActor.run {
            self.habits = todos
            saveHabitsToWidgetStorage(todos)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    private func saveHabitsToWidgetStorage(_ habits: [NotionBlock]) {
        let defaults = UserDefaults(suiteName: "group.com.yourname.habittracker")

        let habitsToSave = habits.compactMap { block in
            if let title = block.to_do?.rich_text.map(\.plain_text).joined() {
                return ["id": block.id, "title": title, "checked": block.to_do?.checked ?? false]
            }
            return nil
        }

        defaults?.set(habitsToSave, forKey: "widgetHabits")
        print("✅ Saved habits to widget storage")
    }





}

