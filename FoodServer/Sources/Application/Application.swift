import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health
import SwiftKuery
import SwiftKueryPostgreSQL

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()
    let meals = Meals()
    let connection = PostgreSQLConnection(host: "localhost", port: 5432, options: [.databaseName("FoodDatabase")])
    private var mealStore: [String: Meal] = [:]
    
    public init() throws {

    }

    func postInit() throws {
        // Capabilities
        initializeMetrics(app: self)
        
        // Endpoints
        initializeHealthRoutes(app: self)
        
        router.post("/meals", handler: storeHandler)
        router.get("/meals", handler: loadHandler)
    }
    
    func storeHandler(meal: Meal, completion: (Meal?, RequestError?) -> Void ) -> Void {
        let photoHex = meal.photo.map{ String(format: "%02hhx", $0) }.joined()
        connection.connect() { error in
            if error != nil {return}
            else {
                let insertQuery = Insert(into: meals, values: [meal.name, photoHex, meal.rating])
                connection.execute(query: insertQuery) { result in
                    print("insert result: \(result.success)")
                    //respond to the result here
                    }
                completion(meal, nil)
                }
        }
    }
    
    func loadHandler(completion: ([Meal]?, RequestError?) -> Void ) -> Void {
        var tempMealStore: [String: Meal] = [:]
        connection.connect() { error in
            if error != nil {return}
            else {
                let query = Select(from :meals)
                connection.execute(query: query) { queryResult in
                    if let resultSet = queryResult.asResultSet {
                        for row in resultSet.rows {
                            guard let name = row[0], let nameString = name as? String else{return}
                            guard let photo = row[1], let photoData = photo as? Data else {return}
                            guard let rating = row[2], let ratingInt = Int(String(describing: rating)) else{return}
                            let currentMeal = Meal(name: nameString, photo: photoData, rating: ratingInt)
                            tempMealStore[nameString] = currentMeal
                        }
                    }
                }
            }
        }
        self.mealStore = tempMealStore
        let returnMeals: [Meal] = self.mealStore.map({ $0.value })
        completion(returnMeals, nil)
    }
    
    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
