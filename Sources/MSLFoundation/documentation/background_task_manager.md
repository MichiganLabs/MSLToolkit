#  Background Task Manager

The `BackgroundTaskManager` is a utility designed to manage and execute background tasks efficiently. It ensures that tasks are executed based on specific conditions such as network availability and battery level, and it prioritizes tasks according to their importance.

## Features

- **Condition-based Execution**: Tasks can be scheduled to run only when certain conditions are met, such as having an active network connection or a minimum battery level.
- **Priority Management**: Tasks are prioritized and executed based on their importance and urgency.
- **Efficient Resource Management**: Ensures that tasks are executed within the available background time and resources.

## Usage

### Initialization

To use the `BackgroundTaskManager`, you need to initialize it and register your task providers.

```swift
let backgroundTaskManager = BackgroundTaskManager(taskId: "com.example")
```

### Starting the Manager
When you are ready, you can start the `BackgroundTaskManager` to begin executing tasks. You can `register` / `unregister` providers at any time.

```swift
backgroundTaskManager.start()
```

### Registering Task Providers
Task providers are responsible for defining the tasks and their conditions. You can register a task provider with the `BackgroundTaskManager` as follows:

```swift
let taskProvider = MyTaskProvider()
backgroundTaskManager.register(provider: taskProvider)
```

### Stopping the Manager
```swift
backgroundTaskManager.stop()
```

### Example
Here is an example of how to use the `BackgroundTaskManager` with a custom task provider:

```swift
import Foundation

class MyTaskProvider: OperationWorkProvider {
    var conditions: [Condition] {
        return [.hasActiveNetwork, .batteryLevel(20)]
    }

    var estimatedWorkTime: TimeInterval {
        return 60 // 1 minute
    }

    func buildWork() -> [Operation] {
        return [MyCustomOperation()]
    }
}

let backgroundTaskManager = BackgroundTaskManager(taskId: "com.example")
let taskProvider = MyTaskProvider()

backgroundTaskManager.register(provider: taskProvider)
backgroundTaskManager.start()
```

In this example:

* `MyTaskProvider` is a custom task provider that specifies the conditions for execution (`hasActiveNetwork` and `batteryLevel(20)`).
* The `buildWork` method returns an array of operations to be executed.
* The `BackgroundTaskManager` is initialized, the task provider is registered, and the manager is started.
