# Adding a Database to FoodTracker Server with Swift-Kuery

<p align="center">
<img src="https://www.ibm.com/cloud-computing/bluemix/sites/default/files/assets/page/catalog-swift.svg" width="120" alt="Kitura Bird">
</p>

<p align="center">
<a href= "http://swift-at-ibm-slack.mybluemix.net/">
<img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg"  alt="Slack">
</a>
</p>

This tutorial builds upon a server and application created by following the [FoodTrackerBackend](https://github.com/IBM/FoodTrackerBackend) tutorial. These instructions will demonstrate how to add a PostgreSQL database to the FoodTracker server using [Swift-Kuery](https://github.com/IBM-Swift/Swift-Kuery) and [Swift-Kuery-PostgreSQL](https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL) so stored data is persistable.


## Pre-Requisites:
1. This workshop has been developed for Swift 4, Xcode 9.x and Kitura 2.x. Ensure you have all of these installed.

2. Ensure you have CocoaPods installed.
To install CocoaPods:
`sudo gem install cocoapods`

3. This tutorial follows on from the FoodTracker **Application** and server created by following [FoodTrackerBackend](https://github.com/IBM/FoodTrackerBackend) tutorial. If you have completed the FoodTracker Backend, whenever a command tells you to cd SwiftPersistanceTutorial/FoodTrackerBackend/example you should remove the SwiftPersistanceTutorial/ part.
If you have not completed the FoodTracker Backend, follow the commands below to clone the FoodTracker application and Server.
```
git clone https://github.com/Andrew-Lees11/SwiftPersistanceTutorial.git
cd SwiftPersistanceTutorial
git checkout completedFoodBackend
cd FoodTrackerBackend/iOS/FoodTracker
pod install
open FoodTracker.xcworkspace/
```
This xcode project contains the food tracker mobile app which can be simulated using the play button.

## Connecting A PostgreSQL Database
### Creating a PostgreSQL Databsse
The Food Tracker application is taken from the Apple tutorial for building your first iOS application. In [FoodTrackerBackend Tutorial](https://github.com/IBM/FoodTrackerBackend) We created a server and connected it to the iOS application. This means created meals will be posted to the server and a user can then view these meals using localhost. Now we will create a PostgreSQL database where we will store the data.

1. Install PostgreSQL:
open your terminal and run:
#### Mac
```
brew install postgresql
brew services start postgresql
```
#### Ubuntu Linux
```
sudo apt-get install postgresql postgresql-contrib
service postgresql start
```
You should recieve a message that either postgresql has been started or the service is already running. This installation should have also installed two applications we need, namely (createdb and psql) which will be used as clients to your locally running PostgreSQL.

2. Create a database called FoodDatabase where data will be stored
```
createdb FoodDatabase
```
3. Open the postgre command line for your database
```
psql FoodDatabase
```
4. Define your meals table:
```
CREATE TABLE meals (
name varchar(100) PRIMARY KEY,
photo text NOT NULL,
rating integer
);
```
note that since name has been designated the primary key, every name must be unique.

5. View your table to ensure it has been created:
```
TABLE meals;
```
At this point it will be empty since we have not inserted anything.

6. Type `\q` and then press ENTER to quit psql.

### Adding Swift-kuery dependencies to your server
Swift-kuery is an abstraction layer which allows you to make SQL query calls in swift. It works along side a database specific library such as Swift-Kuery-PostgreSQL to allow a user to easily work with a SQL database from a swift file. We now import these two librarys to our server so we can use them.

1. Open a new terminal window and go into your server package.swift file
```
cd SwiftPersistanceTutorial/FoodTrackerBackend/FoodFoodServer
open Package.swift
```
2. Add swift-kuery and swift-kuery-postgreSQL packages.
```swift
.package(url: "https://github.com/IBM-Swift/Swift-Kuery.git", .upToNextMinor(from: "1.0.0")),
.package(url: "https://github.com/IBM-Swift/Swift-Kuery-PostgreSQL.git", .upToNextMinor(from: "1.0.1")),
```
3. Change targets to include swift-kuery and swift-kuery-postgreSQL.
```swift
.target(name: "FoodServer", dependencies: [ .target(name: "Application"), "Kitura" , "HeliumLogger", "SwiftKuery", "SwiftKueryPostgreSQL"]),
.target(name: "Application", dependencies: [ "Kitura", "Configuration", "CloudEnvironment","SwiftMetrics","Health", "SwiftKuery", "SwiftKueryPostgreSQL"]),
```
### Generate and open your FoodServer Xcode project
Now we have added the dependencies to our package.swift file we can generate our FoodServer xcode project to make editing the code easier. The FoodServer is a pure swift file and so the following steps could also be done just by editing the .swift files.

1. Using terminal, move to the FoodServer file, Generate the Server Xcode project and open the project
```
cd SwiftPersistenceTutorial/FoodTrackerBackend//FoodServer/
swift package generate-xcodeproj
open FoodServer.xcodeproj/
```
2. Click on the "FoodServer-Package" section on the top-left of the toolbar and select "Edit scheme"
3. In "Run" click on the "Executable" dropdown, select FoodServer and click close.

Now when you press play, Xcode will start your Food tracker Server listening on port 8080. You can see this by going to [http://localhost:8080/ ](http://localhost:8080/ ) which will show the default Kitura landing page.

### Create a Meals table class
To work with the table in the database Swift-kuery requires a class which matches the table in the database. We will now create a Meals class to match our meals table we created earlier in PostgreSQL.

1. Open your Sources > Application > Meal.swift file
2. Add SwiftKuery SwiftKueryPostgreSQL to the import statements
```swift
import SwiftKuery
import SwiftKueryPostgreSQL
```
3. Create a class matching your meals table you created in the database
```swift
public class Meals : Table {
    let tableName = "meals"
    let name = Column("name")
    let photo = Column("photo")
    let rating = Column("rating")
}
```
4. Open your Sources > Application > Application.swift file
5. Add SwiftKuery SwiftKueryPostgreSQL to the import statements for application.swift
```swift
import SwiftKuery
import SwiftKueryPostgreSQL
```
6. Inside the app class create a Meals table object by inserting the line:
```swift
let meals = Meals()
```
below the line `let cloudEnv = CloudEnv().`

### Connecting to the PostgreSQL database
We will now connect to our server to the PostgreSQL database. This will allow us to send a recieve information though queries.

1. Staying within your Application.swift file set up a connection by inserting:
```swift
let connection = PostgreSQLConnection(host: "localhost", port: 5432, options: [.databaseName("FoodDatabase")])
```
below the line `let meals = Meals()`

2. inside your storeHandler and loadHandler functions create a connection to the database:
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

### Create and execute an SQL INSERT query when recieving a HTTP POST request
We are going to add an insert query to our storehandler. This will mean that when our server recieves a HTTP POST request it will take the data it recieved and perform an SQL INSERT of the data into the database, so that the data is stored in the PostgreSQL database inside our Meals table we created earlier.

1.  Inside the **storehandler** connection.connect() else block create an insert query.
```swift
connection.connect() { error in
    if error != nil {return}
    else {
        // Build and execute your query here.
        let insertQuery = = Insert(into: self.meals, values: [meal.name, String(describing: meal.photo), meal.rating])
    }
}
```
2. Execute the insert query you just created.
```swift
else {
    // Build and execute your query here.
    let insertQuery = Insert(into: self.meals, values: [meal.name, String(describing: meal.photo), meal.rating])
    self.connection.execute(query: insertQuery) { result in
        //respond to the result here
    }
}
```
**Note** After you execute the query you recieve a "result" back from the database. This contains the response from the database. Since we are performing an insert query this will just include whether the query was sucessful. For this tutorial we will assume the insert query was succesful an ignore the returned value.
3. Have the server respond to the client with the inserted meal to indicate success:
```swift
else {
    // Build and execute your query here.
    let insertQuery = = Insert(into: self.meals, values: [meal.name, String(describing: meal.photo), meal.rating])
    self.connection.execute(query: insertQuery) { result in
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

You can verify this by adding a meal in your foodtracker app, Then access your database by typing:
`psql FoodDatabase`
into a terminal window.

Now view your meals table by entering:
`TABLE meals;`
To your terminal window. This should poduce a table with the names, encoded photo strings and rating of your newly added meal in the table.

### Create and Execute an SQL SELECT query when the Server recieves a HTTP GET call
We are going to add a SELECT query to our loadHandler. This will mean that when our server recieves a HTTP GET request it will perform an SQL SELECT call to get the data from the PostgreSQL database. This means that the data the Server returns is taken from the database and will persist even if the server gets restarted.

1. Create a temporary mealstore inside your loadHander function.
```swift
func loadHandler(completion: ([Meal]?, RequestError?) -> Void ) -> Void {
    var tempMealStore: [String: Meal] = [:]
```
2. Inside the loadhandler connection.connect() else block create a select query:
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
In this example we have parsed the cells from each row returned from the database to be the correct type to create a meal object.
**Note** For this tutorial we will not be storing the photo data in the database. instead we will store a string description of the photo and then encode that string to data when creating the "Meal" object..

6. At the end of loadHandler, replace your old mealstore with your newly created "tempMealStore" and return this as your response to the GET request.
```swift
    ...
    }
    self.mealStore = tempMealStore
    let returnMeals: [Meal] = self.mealStore.map({ $0.value })
    completion(returnMeals, nil)
}
```

7. Your completed loadhander function should now look as follows:
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
verify this by going to:[http://localhost:8080/meals](http://localhost:8080/meals) Where you should see your meals.
You can stop your server running but this data will now persist since it is stored within the database!

If you would like to view a complete ToDoList application including Database persistance for more examples of HTTP and SQL calls please see [PersistentiOSKituraKit](https://github.com/Andrew-Lees11/PersistentiOSKituraKit).


