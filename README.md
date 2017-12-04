# Adding a Database to FoodTracker Server with Swift-Kuery

<p align="center">
<img src="https://www.ibm.com/cloud-computing/bluemix/sites/default/files/assets/page/catalog-swift.svg" width="120" alt="Kitura Bird">
</p>

<p align="center">
<a href= "http://swift-at-ibm-slack.mybluemix.net/">
<img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg"  alt="Slack">
</a>
</p>

This tutorial builds upon a server and application created by following the [FoodTrackerBackend](https://github.com/IBM/FoodTrackerBackend) tutorial. These instructions demonstrate how to add a PostgreSQL database to the FoodTracker server using [Swift-Kuery](https://github.com/IBM-Swift/Swift-Kuery) and [Swift-Kuery-PostgreSQL](https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL) so data persists between server restarts.


## Pre-Requisites:
This tutorial follows on from the FoodTracker Application and server created by following the [FoodTrackerBackend](https://github.com/IBM/FoodTrackerBackend) tutorial. If you have completed the FoodTracker Backend there are no further pre-requisites. 

If you have not completed the the [FoodTrackerBackend](https://github.com/IBM/FoodTrackerBackend) tutorial follow the steps below to get started:

1. Ensure you have Swift 4, Xcode 9.x and Kitura 2.x installed.

2. Ensure you have CocoaPods installed:

`sudo gem install cocoapods`

3. Open a terminal window and clone the FoodTracker application and Server:

`git clone https://github.com/Andrew-Lees11/SwiftPersistanceTutorial.git`

4. Switch to the "completedFoodBackend" branch:
```
cd SwiftPersistanceTutorial
git checkout completedFoodBackend
```
5. Use Cocoapods to install app dependencies:
```
cd FoodTrackerBackend/iOS/FoodTracker
pod install
```
6. Open the FoodTracker Application in Xcode
```
open FoodTracker.xcworkspace/
```
This Xcode workspace contains the food tracker mobile app, which can be run by clicking the play button.

## Connecting A PostgreSQL Database
### Creating a PostgreSQL Database
The Food Tracker application is taken from the Apple tutorial for building your first iOS application. In [FoodTrackerBackend Tutorial](https://github.com/IBM/FoodTrackerBackend), we created a server and connected it to the iOS application. This means created meals are posted to the server and a user can then view these meals on [localhost:8080/meals](http://localhost:8080/meals). Since the meals are stored on the Server, if the server is restarted the meal data is lost. To solve this problem, we will start by creating a PostgreSQL database where the meals will be stored.

1. Install PostgreSQL:
```
brew install postgresql
brew services start postgresql
```
You should receive a message that either PostgreSQL has been started or the service is already running. This installation should have installed two applications we need, namely createdb and psql, which will be used as clients to your locally running PostgreSQL.

2. Create a database called FoodDatabase to store the data:
```
createdb FoodDatabase
```
3. Open the PostgreSQL command line for your database:
```
psql FoodDatabase
```
4. Create a table to contain your meals:
```
CREATE TABLE meals (
    name varchar(100) PRIMARY KEY,
    photo text NOT NULL,
    rating integer
);
```
**Note** Name has been designated the primary key, therefore every name must be unique.

5. View your table to ensure it has been created:
```
TABLE meals;
```
At this point it will be empty since we have not inserted anything.

6. Type `\q` and then press ENTER to quit psql.

### Adding Swift-Kuery dependencies to your server
[Swift-Kuery](https://github.com/IBM-Swift/Swift-Kuery) is a database abstraction layer, it works alongside a specific database library, such as [Swift-Kuery-PostgreSQL](https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL), to allow a user to easily query a SQL database in Swift. These two libraries are added to our Package.swift file, so the Server can access them.

1. Open a new terminal window and go into your server `Package.swift` file
```
cd SwiftPersistanceTutorial/FoodTrackerBackend/FoodServer
open Package.swift
```
2. Add Swift-Kuery and Swift-Kuery-PostgreSQL packages.
```swift
.package(url: "https://github.com/IBM-Swift/Swift-Kuery.git", .upToNextMinor(from: "1.0.0")),
.package(url: "https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL.git", .upToNextMinor(from: "1.0.1")),
```
3. Change targets to include Swift-Kuery and Swift-Kuery-PostgreSQL.
```swift
.target(name: "FoodServer", dependencies: [ .target(name: "Application"), "Kitura" , "HeliumLogger", "SwiftKuery", "SwiftKueryPostgreSQL"]),
.target(name: "Application", dependencies: [ "Kitura", "Configuration", "CloudEnvironment","SwiftMetrics","Health", "SwiftKuery", "SwiftKueryPostgreSQL"]),
```
### Generate your FoodServer Xcode project
Now we have added the dependencies to our `Package.swift` file we can generate our FoodServer Xcode project to make editing the code easier. The FoodServer is a pure Swift project and so the following steps could also be achieved by editing the .swift files.

1. Generate the server Xcode project:
```
cd SwiftPersistenceTutorial/FoodTrackerBackend//FoodServer/
swift package generate-xcodeproj
open FoodServer.xcodeproj/
```
2. Click on the "FoodServer-Package" text on the top-left of the toolbar and select "Edit scheme" from the dropdown menu.
3. In "Run" click on the "Executable" dropdown, select FoodServer and click Close.

Now when you press play, Xcode will start your FoodTracker server listening on port 8080. You can see this by going to [http://localhost:8080/](http://localhost:8080/ ) which will show the default Kitura landing page.

### Create a Meals Table class
To work with the meals table in the database Swift-Kuery requires a matching class. We will now create a `Meals` class to match the meals table we created earlier in PostgreSQL.

1. Open your `Sources > Application > Meal.swift` file
2. Add SwiftKuery and SwiftKueryPostgreSQL to the import statements:
```swift
import SwiftKuery
import SwiftKueryPostgreSQL
```
3. Create a class, which matches the meals table you created in the database:
```swift
public class Meals : Table {
    let tableName = "meals"
    let name = Column("name")
    let photo = Column("photo")
    let rating = Column("rating")
}
```
4. Open your `Sources > Application > Application.swift` file
5. Add SwiftKuery and SwiftKueryPostgreSQL to the import statements for `Application.swift`
```swift
import SwiftKuery
import SwiftKueryPostgreSQL
```
6. Inside the `App` class create a `Meals` table object by inserting the line:
```swift
let meals = Meals()
```
below the line `let cloudEnv = CloudEnv()`

### Connecting to the PostgreSQL database
We will now connect to our server to the PostgreSQL database. This will allow us to send and recieve information, by using queries.

1. Staying within your `Application.swift` file set up a connection by inserting:
```swift
let connection = PostgreSQLConnection(host: "localhost", port: 5432, options: [.databaseName("FoodDatabase")])
```
below the line `let meals = Meals()`

2. inside your `storeHandler` and `loadHandler` functions create a connection to the database:
```swift
connection.connect() { error in
    if error != nil {return}
    else {
        // Build and execute your query here.
    }
}
```
on the lines below `func loadHandler(...{`  and `func storeHandler(...{`

## Querying the PostgreSQL Database

Once you have connected to your database the code to perform queries is handled by the Swift-Kuery library. This means the following code would be the same for any supported SQL database.

### Create and execute an SQL INSERT query when recieving a HTTP POST request
We are going to add an insert query to our `storehandler`. This will mean that when our server recieves an HTTP `POST` request, it will take the recieved data and perform an SQL `INSERT` query to the database. This will store the data in the database's Meals table we created earlier.

1.  Inside the `storehandler` connection.connect() else block, create an insert query.
```swift
connection.connect() { error in
    if error != nil {return}
    else {
        // Build and execute your query here.
        let insertQuery = = Insert(into: self.meals, values: [meal.name, String(describing: meal.photo), meal.rating])
    }
}
```
2. Execute this insert query.
```swift
else {
    // Build and execute your query here.
    let insertQuery = Insert(into: self.meals, values: [meal.name, String(describing: meal.photo), meal.rating])
    connection.execute(query: insertQuery) { result in
        //respond to the result here
    }
}
```
**Note** After you execute the query you recieve a "result" back containing the response from the database. Since we are performing an insert query this will only include whether the query was sucessful. For this tutorial, we assume the insert query was succesful an ignore the returned value.

3. Have the server respond to the client with the inserted meal to indicate success:
```swift
else {
    // Build and execute your query here.
    let insertQuery = = Insert(into: self.meals, values: [meal.name, String(describing: meal.photo), meal.rating])
    connection.execute(query: insertQuery) { result in
        //respond to the result here
    }
    completion(meal, nil)
}
```
4. Your storehandler function should now look as follows:
```swift
func storeHandler(meal: Meal, completion: (Meal?, RequestError?) -> Void ) -> Void {
    connection.connect() { error in
        if error != nil {return}
        else {
            // Build and execute your query here.
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

You can verify this by
1. Starting the foodtracker app in Xcode.
2. Creating a meal in the app.
3. Access your database:
`psql FoodDatabase`
4. View your meals table:
`TABLE meals;`
This should poduce a table with the names, encoded photo strings and rating of your newly added meal in the table.

### Create and Execute an SQL SELECT query when the Server recieves a HTTP GET call
We are going to add a select query to our `loadHandler`. This will mean that when the server recieves an HTTP `GET` request, it will perform an SQL `SELECT` query to get the meals from the database. This means the data the Server returns to the client is taken from the database and will persist, even if the server is restarted.

1. Create a temporary mealstore inside your `loadHander` function:
```swift
func loadHandler(completion: ([Meal]?, RequestError?) -> Void ) -> Void {
    var tempMealStore: [String: Meal] = [:]
```
2. Inside the `loadhandler` connection.connect() else block create a select query:
```swift
connection.connect() { error in
    if error != nil {return}
    else {
        // Build and execute your query here.
        let query = Select(from :meals)
    }
}
```
This query will return everything from your created "meals" table.

3. Execute your Select query:
```swift
else {
    // Build and execute your query here.
    let query = Select(from :meals)
    connection.execute(query: query) { queryResult in
        //handle your result here
    }
}
```

4. Iterate through the rows returned by the database.
```swift
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
5. For each row, create a meal object from the table and add it to your temporary mealstore
```swift
if let resultSet = queryResult.asResultSet {
    for row in resultSet.rows {
        //process rows
        guard let name = row[0], let nameString = name as? String else{return}
        guard let photo = row[1], let photoString = photo as? String   else{return}
        guard let photoData = photoString.data(using: .utf8) else {return}
        guard let rating = row[2], let ratingInt = Int(String(describing: rating)) else{return}
        let currentMeal = Meal(name: nameString, photo: photoData, rating: ratingInt)
        tempMealStore[nameString] = currentMeal
    }
}
```
In this example we have parsed the cells from each row in the database to be the correct type to create a meal object.
**Note** For this tutorial we will not be storing the photo data in the database. instead we will store a string description of the photo and then encode that string to data when creating the "Meal" object..

6. At the end of loadHandler, replace your old mealstore with your newly created `tempMealStore` and return this as your response to the `GET` request.
```swift
        ...
    }
    self.mealStore = tempMealStore
    let returnMeals: [Meal] = self.mealStore.map({ $0.value })
    completion(returnMeals, nil)
}
```

7. Your completed `loadhander` function should now look as follows:
```swift
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
verify this by going to:[http://localhost:8080/meals](http://localhost:8080/meals), where you should see your meals.
You can restart your server but this data will now persist since it is stored within the database!

If you would like to view a complete ToDoList application, including database persistance, with more examples of HTTP and SQL calls please see [PersistentiOSKituraKit](https://github.com/Andrew-Lees11/PersistentiOSKituraKit).
