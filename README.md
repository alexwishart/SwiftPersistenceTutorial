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
    if error != nil {return}
    else {
    // Build and execute your query here.
    }
}
```
on the lines below "func loadHandler(...{"  and "func storeHandler(...{"

### create and execute insert query on post

1.  inside the storehandler connection.connect() else block create an insert query
```
else {
// Build and execute your query here.
let insertQuery = = Insert(into: self.meals, values: [meal.name, String(describing: meal.photo), meal.rating])
}
```
4. execute your query:
```
connection.execute(query: insertQuery) { result in
//respond to the result here
}
```
5. have server respond to the client with the inserted meal to indicate success
```
connection.execute(query: insertQuery) { result in
//respond to the result here
}
completion(meal, nil)
```
6. your storehandler function should now look as follows:
```
func storeHandler(meal: Meal, completion: (Meal?, RequestError?) -> Void ) -> Void {
    connection.connect() { error in
        if error != nil {return}
        else {
            let insertQuery = Insert(into: meals, values: [meal.name, String(describing: meal.photo), meal.rating])
            connection.execute(query: insertQuery) { result in
                //respond to the result here
                }
            completion(meal, nil)
            }
        }
    }
```
Now when you create a meal in the app the server will make an insert call to the postgreSQL database.
Verify this by adding a meal in your foodtracker app.
accessing your database through:
`psql FoodDatabase`
and calling
`TABLE meals;`
This should rpoduce a table with the names, encoded photo strings and rating in a table.

### create and execute select query on get call
1. create a temporary mealstore at the top of your loadHander function
```
func loadHandler(completion: ([Meal]?, RequestError?) -> Void ) -> Void {
var tempMealStore: [String: Meal] = [:]
```
2. inside the loadhandler connection.connect() else block create a query
```
else {
    // Build and execute your query here.
    let query = Select(from :meals)
    }
```
This will return everything from your created "meals" table.

3. execute your query
```
else {
    // Build and execute your query here.
    let query = Select(from :meals)
    connection.execute(query: query) { queryResult in
        //handle your result here
    }
}
```

4. iterate through the returned rows
```
else {
    // Build and execute your query here.
    let selectQuery = Select(from :meals)
    connection.execute(query: selectQuery) { queryResult in
        //handle your result here
        if let resultSet = queryResult.asResultSet {
            for row in resultSet.rows {
            //process rows
    }
}
```
5. create a meal object from the table and add it to your temporary mealstore
```
for row in resultSet.rows {
    //process rows
    guard let name = row[0], let nameString = name as? String else{return}
    guard let photo = row[1], let photoString = photo as? String   else{return}
    guard let photoData = photoString.data(using: .utf8) else {return}
    guard let rating = row[2], let ratingInt = Int(String(describing: rating)) else{return}
    let currentMeal = Meal(name: nameString, photo: photoData, rating: ratingInt)
    tempMealStore[nameString] = currentMeal
}
```
For this tutorial we will not be storing the photo data so instead we will just store a string description of the photo.

6. at the end of loadHandler Replace your old mealstore with your tempMealStore and return it
```
self.mealStore = tempMealStore
let returnMeals: [Meal] = self.mealStore.map({ $0.value })
completion(returnMeals, nil)
```

your loadhander function should now look as follows:
```
func loadHandler(completion: ([Meal]?, RequestError?) -> Void ) -> Void {
    var tempMealStore: [String: Meal] = [:]
    connection.connect() { error in
    if error != nil {return}
    else {
        let selectQuery = Select(from :meals)
        connection.execute(query: selectQuery) { queryResult in
        if let resultSet = queryResult.asResultSet {
            for row in resultSet.rows {
                guard let name = row[0], let nameString = name as? String else{return}
                guard let photo = row[1], let photoString = photo as? String   else{return}
                guard let photoData = photoString.data(using: .utf8) else {return}
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

Now when you preform a get call to your server it will lookup and return the values from your database.
verify this by going to:[http://localhost:8080/meals](http://localhost:8080/meals) Where you should see your meals.
You can stop your server running but this data will now persist since it is within the database!


