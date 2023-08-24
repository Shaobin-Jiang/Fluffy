# Fluffy

Creates psychology experiments on mobile devices, and potentially on desktop and web.

## Usage

Add `fluffy` as [a dependency in your `pubspec.yaml` file](https://pub.dev/packages/fluffy/install).

Now, you can start creating your experiment.

### The basic 'hello world'

```dart
void main() {
  final trial = Trial(
    content: (Fluffy fluffy) {
      return (BuildContext context) {
        return const Text('Hello world');
      };
    },
  );

  final mainLoop = MainLoop(children: [trial]);

  final fluffy = Fluffy(mainLoop: mainLoop);
  fluffy.run();
}
```

We start by creating a trial using the `Trial` class. The simplest trial requires only a `content` parameter, which is a function. The `content` function receives one argument, which is a `Fluffy` instance (which we will later learn is what manages the running of an experiment), and returns a function. This returned function receives one argument, which is a `BuildContext` object, and returns a widget, which is displayed when the experiment proceeds to this trial.

Then, we have to add the trial to the experiment's **main loop**: creating a trial does not mean that it is going to be run; a trial only runs when it is in a main loop. We create a main loop using the `MainLoop` class, which requires but one parameter: `children`, which is a list containing all the trials, and which we will also learn later, loops, that an experiment contains.

Finally, we need to run the main loop. The running of an experiment must be managed by a `Fluffy` class, as must be other activities such as data collection. The creation of a `Fluffy` instance requires a `MainLoop` object. After its creation, we need only call `.run()` on the `Fluffy` instance to get the experiment running.

### Finishing a trial and collecting data

In the example above, we simply display some text and obviously that does not make what we have created a real trial. In a real trial, either some response from the participant is required, or the trial ends when certain conditions are met, and in either case the trial finishes somehow, whereas our previously created trial goes on and on.

Say now, that we wish the trial to finish in 3 seconds. How do we do that? The answer is easy: call the `finishTrial()` method on the `Fluffy` instance, pass some custom data of yours, and it is done.

```dart
final trial = Trial(
  content: (Fluffy fluffy) {
    return (BuildContext context) {
      Timer(const Duration(seconds: 5), () {
        fluffy.finishTrial({});
      });
      return const Text('Hello world');
    };
  },
);
```

We can see that a map is passed to the `finishTrial()` method. This map is a `Map<string, dynamic>` object and should contain the data you wish to store in addition to the data collected by default by Fluffy.

### Repeating / Skipping a trial

We cannot know for sure whether we really want a trial to be run or how many times it should be run at the start of an experiment. There are occasions when we wish to skip or repeat a certain trial. That is where the `repeat` and `skip` functions of a trial come into place.

The two functions both receive a `Fluffy` instance as a single argument and return a boolean value: if the return value is `true`, the trial is repeated / skipped. For example:

```dart
// The trial is never run
trial.skip = (Fluffy fluffy) {
  return false;
};
```

You can also use these two functions as a mean of doing something before / after the running of a trial.

### Using loops

Think of this: how do we repeat a set of trials? We cannot call `repeat` on all of them, because that would mean repeating each of them, not running them in sequence and then restarting. The answer is using loops.

Loops are collections of trials and have also `repeat` / `skip` functions just like trials. We have in reality already encountered loops when we created a main loop, which is a special kind of loop.

```dart
void main() {
  // We use a function here for creating similar trials
  Trial trial(String value) {
    return Trial(
      content: (Fluffy fluffy) {
        return (BuildContext context) {
          Timer(const Duration(seconds: 1), () {
            fluffy.finishTrial({});
          });
          return Text(value);
        };
      },
    );
  }

  final loop = Loop(children: [
    trial('1'),
    trial('2'),
    trial('3'),
  ]);
  loop.repeat = (_) => true;

  final fluffy = Fluffy(mainLoop: MainLoop(children: [loop]));
  fluffy.run();
}
```

In the example above, we will see that first 1, then 2, then 3, and then 1 on the screen.

In addition, loops can be nested, which means you can put loops inside a loop.

### Saving data

Now, perhaps the most crucial of all: how do I access my data? The data collected by Fluffy is stored in a field
called `data` under the `Fluffy` instance we create for the experiment. This field is a `FluffyData` object that provides various methods for handling data. For instance, if we wish to save the data as an excel file at the end of the experiment, we can do it like:

```dart
// Do this at the end of the main loop
mainLoop.repeat = (Fluffy fluffy) {
  fluffy.data.saveAsExcel(fileName: 'data.xlsx');

  // Do not repeat the main loop
  return false;
};
```

We can see in the example that we call the `saveAsExcel` method and pass a file name. But where is this file? That depends on the platform where the experiment is run. On Android devices, it is stored in external storage whilst on others (web not included), it is stored in the download folder.

### Utilities

Fluffy provides several utilities, which should be useless for those adept at flutter development but which can be quite convenient for those who are new to flutter and who do not wish to explore deeper into it. You can check out `FluffyUtils` for these methods.

Note that currently, only limited methods are provided, and any suggestion as to adding to these utilities is much appreciated.
