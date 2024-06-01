## Example project showing Flutter Isolates usage

This project is a simple example of how to use Flutter Isolates to run and manage background/resource-intensive tasks.

#### \*\*\* Used hive for demo purposes to store data in local storage. Although the hive is not suited for multi-isolate usage(changes in 1 isolate do not reflect in others concurrently), it is still possible to use it with isolates(by keeping the hive instance open in only 1 particular isolate). You can use any other storage solution.

## Medium Article

I have written a medium article explaining the code in detail. You can read it [here](https://medium.com/@danger-ahead/working-with-isolates-and-hive-in-flutter-b5ef3d32fa2a).
