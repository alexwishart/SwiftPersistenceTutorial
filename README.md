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
cd ../../FoodServer
swift package generate-xcodeproj
open ./FoodServer.xcodeproj/
```
To run the Server:
1. Edit the scheme by clicking on the "FoodServer-Package" section on the top-left the toolbar and selecting "Edit scheme"
2. In "Run" click on the "Executable" dropdown, select FoodServer and click Close
3. Press the Run button or use the ⌘+R key shortcut.

## Creating postgreSQL Database
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
note that since name has been designated the primary key that each name must be unique.

5. view your table to ensure it has been created:
```
TABLE meals;
```

## Building a Kitura Backend
The Food Tracker application stores the meal data to the local device, which means its not possible to share the data with other users, or to build an additional web interface for the application. The following steps show you have to create a Kitura Backend to allow you to store and share the data.

### 1. Initialize a Kitura Server Project
1. Create a directory for the server project
```
mkdir ~/FoodTrackerBackend/FoodServer
cd ~/FoodTrackerBackend/FoodServer
```

2. Create a Kitura starter project
```
kitura init
```
The Kitura CLI will now create and build an starter Kitura application for you. This includes adding best-practice implementations of capabilities such as configuration, health checking and monitoring to the application for you.

More information about the [project structure](http://kitura.io/en/starter/generator/project_layout_reference.html) is available on kitura.io.

### 2. Create an in-memory data store for Meals
The `init` command has created a fully running Kitura application, but one which has no application logic. In order to use it to store the data from the FoodTracker application, you need to create a datastore in the Kitura application for the Meal data from the FoodTracker iOS application. This tutorial uses a simple in-memory dictionary to store exactly the same Meal types that are used in the FoodTracker application.

1. Copy the Meal.swift file from the FoodTracker app to the Server
```
cd ~/FoodTrackerBackend
cp ./iOS/FoodTracker/FoodTracker/Meal.swift ./FoodServer/Sources/Application
```
2. Open the FoodServer project in Xcode
```
cd ~/FoodTrackerBackend/FoodServer
open FoodServer.xcodeproj
```
3. Add the Meal.swift file into the FoodServer project
1. Select the yellow Sources > Application folder in the left hand explorer menu
2. Click right mouse and select Add Files to "FoodServer"...
3. Single left click the Meal.swift file found in FoodTrackerBackend > iOS > FoodTracker > FoodTracker
4. Select the Options button, Scroll down about halfway through the "Add to targets" and tick the "Application"
5. Untick any other options in "add to targets" and click Add
4. Add a dictionary to the Application.swift file to store the Meal types
1. Open the Sources > Application > Application.swift file
2. Add a "mealstore" inside the app class,  by inserting the following code:
```
private var mealStore: [String: Meal] = [:]
```
On the line below `let cloudEnv = CloudEnv()`

This now provides a simple dictionary to store Meal data passed to the FoodServer from the FoodTracker app.

### 3. Create a REST API to allow FoodTracker to store Meals
REST APIs typically consist of a HTTP request using a verb such as POST, PUT, GET or DELETE along with a URL and an optional data payload. The server then handles the request and responds with an optional data payload.

A request to store data typically consists of a POST request with the data to be stored, which the server then handles and responds with a copy of the data that has just been stored.

1. Register a handler for a `POST` request on `/meals` that stores the data
Add the following into the `postInit()` function in the App class:
```swift
router.post("/meals", handler: storeHandler)
```
2. Implement the storeHandler that receives a Meal, and returns the stored Meal
Add the following code as a function in the App class, beneath the postInit() function:
```swift
func storeHandler(meal: Meal, completion: (Meal?, RequestError?) -> Void ) -> Void {
mealStore[meal.name] = meal
completion(mealStore[meal.name], nil)
}
```

As well as being able to store Meals on the FoodServer, the FoodTracker app will also need to be able to access the stored meals. A request to load all of the stored data typically consists of a GET request with no data, which the server then handles and responds with an array of the data that has just been stored.

3. Register a handler for a `GET` request on `/meals` that loads the data
Add the following into the `postInit()` function:
```swift
router.get("/meals", handler: loadHandler)
```
4. Implement the loadHandler that returns the stored Meals as an array.
Add the following as another function in the App class:
```swift
func loadHandler(completion: ([Meal]?, RequestError?) -> Void ) -> Void {
let meals: [Meal] = self.mealStore.map({ $0.value })
completion(meals, nil)
}
```

### 4. Test the newly created REST API


1. Run the server project in Xcode
1. Edit the scheme by clicking on the "FoodServer-Package" section on the top-left the toolbar and selecting "Edit scheme"
2. In "Run" click on the "Executable" dropdown, select FoodServer and click Close
3. Press the Run button or use the ⌘+R key shortcut.
4. Select "Allow incoming network connections" if you are prompted.

2. Check that some of the standard Kitura URLs are running:
* Kitura Monitoring: http://localhost:8080/swiftmetrics-dash/
* Kitura Health check: http://localhost:8080/health

3. Test the GET REST API is running correctly
There are many utilities for testing REST APIs, such as [Postman](https://www.getpostman.com). Here we'll use "curl", which is a simple command line utility:
```
curl -X GET \
http://localhost:8080/meals \
-H 'content-type: application/json'
```
If the GET endpoint is working correctly, this should return an array of JSON data representing the stored Meals. As no data is yet stored, this should return an empty array, ie:
```
[]
```
4.  Test the POST REST API is running correctly
In order to test the POST API, we make a similar call, but also sending in a JSON object that matches the Meal data:
```
curl -X POST \
http://localhost:8080/meals \
-H 'content-type: application/json' \
-d '{
"name": "test",
"photo": "0e430e3a",
"rating": 1
}'
```
If the POST endpoint is working correctly, this should return the same JSON that was passed in, eg:
```
{"name":"test","photo":"0e430e3a","rating":1}
```

5. Test the GET REST API is returning the stored data correctly
In order to check that the data is being stored correctly, re-run the GET check:
```
curl -X GET \
http://localhost:8080/meals \
-H 'content-type: application/json'
```
This should now return a single entry array containing the Meal that was stored by the POST request, eg:
```
[{"name":"test","photo":"0e430e3a","rating":1}]
```

## Connect FoodTracker to the Kitura FoodServer

Any package that can make REST calls from an iOS app is sufficient to make the connection to the Kitura FoodServer to store and retrieve the Meals. Kitura itself provides a client connector called [KituraKit](https://github.com/ibm-swift/kiturakit) which makes it easy to connect to Kitura using shared data types, in our case Meals, using an API that is almost identical on the client and the server. In this example we'll use KituraKit to make the connection.

### Install KituraKit into the FoodTracker app
KituraKit is designed to be used both in iOS apps and in server projects. Currently the easiest way to install KituraKit into an iOS app it to download a bundling containing KituraKit and its dependencies, and to install it into the app as a CocoaPod.

1. If the "FoodTracker" Xcode project it is open, close it.
Installing the KituraKit bundle as a CocoaPod will edit the project and create a workspace, so it is best if the project is closed.
2. Download the KituraKit for iOS bundle
KituraKit for iOS can be downloaded from the [KituraKit Releases](https://github.com/IBM-Swift/KituraKit/releases) page by choosing the latest "KituraKit.zip" file, but the easiest way it to use the Kitura command line.
```
cd ~/FoodTrackerBackend
kitura kit
```
3. Copy the KituraKit into the FoodTracker app
```
unzip ~/FoodTrackerBackend/KituraKit.zip -d ~/FoodTrackerBackend
```
4. Create a Podfile in the FoodTracker iOS application directory:
```
cd ~/FoodTrackerBackend/iOS/FoodTracker/
pod init
```
5. Edit the Podfile to use install KituraKit:
1. Open the Podfile for editing
```
open Podfile
```
2. Set a global platform of iOS 11 for your project
Uncomment `# platform :ios, '9.0'` and set the value to `11.0`
3. Under the "# Pods for FoodTracker" line add:
```
# Pods for FoodTracker
pod 'KituraKit', :path => ‘~/FoodTrackerBackend/KituraKit’
```
4. Save and close the file
6. Install KituraKit:
```
pod install
```
7. Open the Xcode workspace (not project!)
```
cd ~/FoodTrackerBackend/iOS/FoodTracker/
open FoodTracker.xcworkspace
```

KituraKit should now be installed, and you should be able to build and run the FoodTracker project as before. Note that from now on you should open the Xcode workspace ('FoodTracker.xcworkspace') not project.

### Update FoodTracker to call the Kitura FoodServer
Now that KituraKit is installed into the FoodTracker application, it needs to be updated to use it to call the Kitura FoodServer. The code to do that is already provided. As a result, you only need to uncomment the code that invokes those APIs. The code to uncomment is marked with `UNCOMMENT`.

1. Edit the `FoodTracker > MealTableViewController.swift` file:
1. Uncomment the import of KituraKit at the top of the file.
```swift
import KituraKit
```
2. Uncomment the following at the start of the saveMeals() function:
```swift
for meal in meals {
saveToServer(meal: meal)
}
```
3. Uncomment the following `saveToServer(meal:)` function towards the end of the file:
```swift
private func saveToServer(meal: Meal) {
guard let client = KituraKit(baseURL: "http://localhost:8080") else {
print("Error creating KituraKit client")
return
}
client.post("/meals", data: meal) { (meal: Meal?, error: Error?) in
guard error == nil else {
print("Error saving meal to Kitura: \(error!)")
return
}
print("Saving meal to Kitura succeeded")
}
}
```

### Update the FoodTracker app to allow interaction with a Server
The final step is to update the FoodTracker application to allow loads from a server `FoodTracker > Info.plist` file to allow loads from a server.

1. Update the `FoodTracker > Info.plist` file to allow loads from a server:
**Note:** This step has been completed already:
```
<key>NSAppTransportSecurity</key>
<dict>
<key>NSAllowsArbitraryLoads</key>
<true/>
</dict>
```

## Run the FoodTracker app, storing data to the Kitura server
1. Make sure the Kitura server is still running and you have the Kitura monitoring dashboard open in your browser (http://localhost:8080/swiftmetrics-dash)
2. Build and run the FoodTracker app in the iOS simulator and add or remove a Meal entry
You should see the following messages in the Xcode console:
```
Saving meal to Kitura succeeded
Saving meal to Kitura succeeded
```
3. View the monitoring panel to see the responsiveness of the API call
4. Check the data has been persisted by the Kitura server
```
curl -X GET \
http://localhost:8080/meals \
-H 'content-type: application/json'
```
This should now return an array containing the Meals that was stored by the POST request. As this contains the full images stored in the Meal objects, this will involve several screens of data!

### Congratulations, you have successfully build a Kitura Backend for an iOS app!

## Next Steps
If you have sufficient time, the following tasks can be completed to update your application.

### Add Support for Retrieving and Deleting Meals from the FoodServer
The current implementation of the Kitura FoodServer has support for retrieving all of the stored Meals using a `GET` request on `/meals`, but the FoodTracker app is currently only saving the Meals to the FoodServer. The following contains the steps to add [Retrieving and Deleting Meals from the FoodServer](RetrievingAndDeleting.md)

### Add a Web Application to the Kitura server
Now that the Meals from the FoodTracker app are being stored on a server, it becomes possible to start building a web application that also provides users with access to the stored Meal data.
The following steps describe how to start to [Build a FoodTracker Web Application](AddWebApplication.md)

### Deploy and host the Kitura FoodServer in the Cloud
In order for a real iOS app to connect to a Kitura Server, it needs to be hosted at a public URL that the iOS app can reach.

Kitura is deployable to any cloud, but the project created with `kitura init` provides additonal files so that it is pre-configured for clouds that support any of Cloud Foundry, Docker or Kubernetes. The follow contains the steps to take the Kitura FoodServer and [Deploy to the IBM Cloud using Cloud Foundry](DeployToCloud.md)

