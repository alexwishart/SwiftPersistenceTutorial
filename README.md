# Adding a Database to FoodTracker Server with Swift-Kuery

<p align="center">
<img src="https://www.ibm.com/cloud-computing/bluemix/sites/default/files/assets/page/catalog-swift.svg" width="120" alt="Kitura Bird">
</p>

<p align="center">
<a href= "http://swift-at-ibm-slack.mybluemix.net/">
<img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg"  alt="Slack">
</a>
</p>

This tutorial builds upon a server and application created by following the [FoodTrackerBackend](https://github.com/IBM/FoodTrackerBackend) tutorial. These instructions will demonstrate how to add a postgreSQL database to the FoodTracker server using [Swift-Kuery](https://github.com/IBM-Swift/Swift-Kuery) and [Swift-Kuery-PostgreSQL](https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL) so stored data is persistable.


## Pre-Requisites:
**Note:** This workshop has been developed for Swift 4, Xcode 9.x and Kitura 2.x.

A FoodTracker Application and server created by following [FoodTrackerBackend](https://github.com/IBM/FoodTrackerBackend) tutorial.

If you have not completed the FoodTracker Backend:
```
git clone https://github.com/Andrew-Lees11/SwiftPersistanceTutorial.git
cd SwiftPersistanceTutorial
git branch completeFoodBackend
cd iOS/FoodTracker
pod install
open FoodTracker.xcworkspace/
```
To run the Server:
1. Edit the scheme by clicking on the "FoodServer-Package" section on the top-left the toolbar and selecting "Edit scheme"
2. In "Run" click on the "Executable" dropdown, select FoodServer and click Close

### Creating postgreSQL Database
1. Install postgreSQL:
open your terminal and run:
```
brew install postgresql
```
This should start your database automatically

2. create a database called FoodDatabase where data will be stored
```
createdb FoodDatabase
```
3. open the postgre command line for your database
```
psql FoodDatabase
```
4. define your meals table:
```
CREATE TABLE meals (
name varchar(100) PRIMARY KEY,
photo text NOT NULL,
rating integer
);
```
note that since name has been designated the primary key, every name must be unique.

5. view your table to ensure it has been created:
```
TABLE meals;
```

### Adding Swift-kuery dependencies

1. Open a new terminal window and go into your server package.swift file
```
cd SwiftPersistanceTutorial/FoodServer
open Package.swift
```
2. add swift-kuery and swift-kuery-postgreSQL packages.
```
.package(url: "https://github.com/IBM-Swift/Swift-Kuery.git", .upToNextMinor(from: "1.0.0")),
.package(url: "https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL.git", .upToNextMinor(from: "1.0.1")),
```
3. Change targets to include swift-kuery and swift-kuery-postgreSQL.
```
.target(name: "FoodServer", dependencies: [ .target(name: "Application"), "Kitura" , "HeliumLogger", "SwiftKuery", "SwiftKueryPostgreSQL"]),
.target(name: "Application", dependencies: [ "Kitura", "Configuration", "CloudEnvironment","SwiftMetrics","Health", "SwiftKuery", "SwiftKueryPostgreSQL"]),
```
4. Rebuild the xcode project with the newly added dependencies
```
swift package generate-xcodeproj
```
5. open your xcode project
```
open FoodServer.xcodeproj/
```

### Create a Meals table class

1. open your Sources > Application > Meal.swift file
2. add SwiftKuery SwiftKueryPostgreSQL to the import statements
```
import SwiftKuery
import SwiftKueryPostgreSQL
```
3. Create a class matching your meals table you created in the database
```
public class Meals : Table {
let tableName = "meals"
let name = Column("name")
let photo = Column("photo")
let rating = Column("rating")
}
```
4. open your Sources > Application > Application.swift file
5. add SwiftKuery SwiftKueryPostgreSQL to the import statements for application.swift
```
import SwiftKuery
import SwiftKueryPostgreSQL
```
6. inside the app class create a Meals table object by inserting the line:
```
let meals = Meals()
```
below the line `let cloudEnv = CloudEnv().`

### Connecting to the postgreSQL database

1. Staying within your Application.swift file set up a connection by inserting:
```
let connection = PostgreSQLConnection(host: "localhost", port: 5432, options: [.databaseName("FoodDatabase")])
```
below the line `let meals = Meals()`

2. inside your storeHandler and loadHandler functions create a connection to the database:
```
connection.connect() { error in
if let error = error {
return
}
else {
// Build and execute your query here.
}
}
```
above `mealStore[meal.name] = meal`

3. make function escape since they can return early

### create and execute select query on get

```
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
if let resultSet = queryResult.asResultSet {
for row in resultSet.rows {
guard let name = row[0], let nameString = name as? String else{return}
guard let photo = row[1], let photoString = photo as? String   else{return}
var photoArray = [String]()
photoArray.append(photoString)
guard let photoData = try? JSONSerialization.data(withJSONObject: photoArray, options: []) else {return}
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
```

### create and execute update query on post

3. add a query to update existing meals inside the else statement made above:
```
let photoString = String(describing: meal.photo)
let updateQuery = Update(meals, set: [(meals.name, meal.name), (meals.photo, photoString),(meals.rating, meal.rating)]).where(meals.name == meal.name)
```
4. execute your query:
```
connection.execute(query: updateQuery) { result in
//respond to the result here
}
```
5. if not in database insert the query:
```
connection.execute(query: updateQuery) { result in
let insertQuery = Insert(into: self.meals, values: [meal.name, photoString, meal.rating])
self.connection.execute(query: insertQuery) { result in
if(!result.success){
completion(nil, .unprocessableEntity)
return
}
}
}
completion(meal, nil)

```
now your server will post new meals to your database and when you go a get to your server it will return the table from your database

