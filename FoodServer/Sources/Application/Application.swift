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

public class Meals : Table {
    let tableName = "meals"
    let key = Column("key")
    let name = Column("name")
    let photo = Column("photo")
    let rating = Column("rating")
}

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
    
    func storeHandler(meal: Meal, completion: @escaping (Meal?, RequestError?) -> Void ) -> Void {
        connection.connect() { error in
            if let error = error {
                print("Error is \(error)")
                return
            }
            else {
                let key = String(arc4random())
                let updateQuery = Update(meals, set: [(meals.key, key), (meals.name, meal.name), (meals.photo, "test"),(meals.rating, meal.rating)]).where(meals.name == meal.name)
                print("meals: \(meals.name) + \(meal.name)")
                    connection.execute(query: updateQuery) { result in
                        print("update result: \(String(describing: result))")
                            let insertQuery = Insert(into: self.meals, values: [key, meal.name, "test", meal.rating])
                            self.connection.execute(query: insertQuery) { result in
                                print("insert result: \(result.success)")
                                if(!result.success){
                                    completion(nil, .unprocessableEntity)
                                    return
                                }
                                print("inserted to table")
                            }
                        
            }
        completion(meal, nil)
            }
        }
    }
    
    func loadHandler(completion: @escaping ([Meal]?, RequestError?) -> Void ) -> Void {
        print("entered loadhandler")
        var tempMealStore: [String: Meal] = [:]
        connection.connect() { error in
            if let error = error {
                print("Error is \(error)")
                return
            }
            else {
                let query = Select(from :meals)
                connection.execute(query: query) { queryResult in
                    print(queryResult)
                    if let resultSet = queryResult.asResultSet {
                        print("result set")
                        for row in resultSet.rows {
                            print("inside rows")
                            guard let name = row[1], let nameString = name as? String else{
                                return
                            }
                            guard let photo = row[2], let photoString = photo as? String   else{return}
                            var photoArray = [String]()
                            photoArray.append(photoString)
                            guard let photoData = try? JSONSerialization.data(withJSONObject: photoArray, options: []) else {return}
                            guard let rating = row[3], let ratingInt = Int(String(describing: rating)) else{return}
                            let currentMeal = Meal(name: nameString, photo: photoData, rating: ratingInt)
                            tempMealStore[nameString] = currentMeal
                        }
                    }
                    else{
                        print("queryResult error: " )
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
