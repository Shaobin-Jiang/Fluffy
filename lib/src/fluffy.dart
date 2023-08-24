import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import './fluffy_data.dart';

/// Describes the basic configuration for the nodes in the experiment.
///
/// There are currently three types of nodes in an experiment:
///
///  * [Trial]
///  * [Loop], a list of trials and loops
///  * [MainLoop], the main loop of the experiment
///
/// All nodes can be skipped and repeated by returning `true` in their [skip] and
/// [repeat] functions.
///
/// One has to bear in mind that these nodes that inherit [TrialOrLoop] are not
/// real nodes executed in an experiment. Rather, they are like templates: by
/// instantiating one of these nodes, you create a template that Fluffy is going
/// to parse into a real executable trial or several such trials in the experiment.
///
/// For more information of this distinction, see [FluffyNode] and its child
/// classes in the source code.
abstract final class TrialOrLoop {
  /// Repeats the current node if the return value is `true`
  bool Function(Fluffy fluffy) repeat = (Fluffy fluffy) => false;

  /// Skips the current node if the return value is `true`
  bool Function(Fluffy fluffy) skip = (Fluffy fluffy) => false;
}

/// Creates a trial.
///
/// The [Trial] here is not equivalent to what we normally regard as a trial in
/// an experiment. It is more of a standalone "event", and you may use it not only
/// for the experiment task but also for other occasions such as displaying a
/// fixation cross.
///
/// ## Example
///
/// ```dart
/// final trial = Trial(
///   content: (Fluffy fluffy) {
///     return (BuildContext context) {
///       return Container();
///     };
///   },
/// );
/// ```
///
/// {@category Introduction}
final class Trial extends TrialOrLoop {
  /// Creates a trial with the given [content].
  Trial({
    required this.content,
    this.startTrialAfter = Duration.zero,
    this.startTrialAfterFunc,
  });

  /// Returns a deep copy of the provided [Trial].
  Trial.copy(Trial trial)
      : content = trial.content,
        startTrialAfter = trial.startTrialAfter,
        startTrialAfterFunc = trial.startTrialAfterFunc {
    skip = trial.skip;
    repeat = trial.repeat;
  }

  /// The content to be displayed in the current [Trial].
  ///
  /// This is a [Function] which receives a single argument, which is the [Fluffy]
  /// instance to which the [Trial] belongs. This function returns another function,
  /// which receives also one argument which is the [BuildContext]. This return
  /// function then returns a [Widget], which is then displayed upon the running
  /// of this trial.
  Widget Function(BuildContext context) Function(Fluffy fluffy) content;

  /// How long to wait before starting the trial.
  ///
  /// A blank screen is shown during this period.
  ///
  /// This has a lower priority than [startTrialAfterFunc], so that if both are
  /// set, the return value of [startTrialAfterFunc] would be used.
  Duration startTrialAfter;

  /// How long to wait before starting the trial.
  ///
  /// A blank screen is shown during this period.
  ///
  /// This has a higher priority than [startTrialAfter], so that if both are set,
  /// the return value of [startTrialAfterFunc] would be used.
  Duration Function(Fluffy fluffy)? startTrialAfterFunc;
}

/// Creates a loop, which is a collection of [Trial]s and [Loop]s.
///
/// By using a loop, one can easily organize multiple trials and skip or repeat
/// them as a whole.
///
/// ## Example
///
/// **Note: this code is only for demonstration and will not run properly!**
///
/// ```dart
/// Trial trial1, trial2, trial3;
///
/// final loop = Loop(
///   children: [trial1, trial2, trial3],
/// );
/// ```
///
/// {@category Introduction}
final class Loop extends TrialOrLoop {
  /// Creates a loop with the given [children].
  ///
  /// It is important that [children] here **should not** contain [MainLoop]
  /// objects or be empty. On such occasions, an [ArgumentError] will be thrown.
  ///
  /// The [children] argument, after being passed to the constructor, is then
  /// deep-copied to a private field. Any changes made afterwards to the original
  /// children will thus make no difference to the preserved copy in the [Loop].
  /// In this sense, the components of a loop will remain immutable.
  Loop({required List<TrialOrLoop> children}) {
    _copyChildrenFromList(children);

    if (_containsMainLoop()) {
      throw ArgumentError('Main loop in $runtimeType object!', 'children');
    }

    if (_childrenIsEmpty()) {
      throw ArgumentError('$runtimeType object is empty!', 'children');
    }
  }

  /// Returns a deep copy of the provided [Loop].
  Loop.copy(Loop loop) {
    _copyChildrenFromList(loop._children);
    skip = loop.skip;
    repeat = loop.repeat;
  }

  final List<TrialOrLoop> _children = [];

  /// Copies all the [TrialOrLoop] objects from a given list to [_children]
  void _copyChildrenFromList(List<TrialOrLoop> children) {
    _children.addAll(children);
  }

  bool _containsMainLoop() {
    return _children.any((child) => child is MainLoop);
  }

  bool _childrenIsEmpty() {
    return _children.isEmpty;
  }
}

/// Creates a main loop, which describes the whole content of an experiment.
///
/// ## Example
///
/// **Note: this code is only for demonstration and will not run properly!**
///
/// ```dart
/// Trial trial1, trial2;
/// Loop loop1, loop2;
///
/// final mainLoop = MainLoop(
///   children: [trial1, loop1, trial2, loop2],
/// );
/// ```
///
/// {@category Introduction}
final class MainLoop extends Loop {
  /// Creates a main loop with the given [children].
  ///
  /// It is important that [children] here **should not** contain [MainLoop]
  /// objects or be empty. On such occasions, an [ArgumentError] will be thrown.
  ///
  /// The [children] argument, after being passed to the constructor, is then
  /// deep-copied to a private field. Any changes made afterwards to the original
  /// children will thus make no difference to the preserved copy in the [MainLoop].
  /// In this sense, the components of a main loop will remain immutable.
  MainLoop({required super.children}) : super();
}

/// A module for creating, running, testing an experiment.
///
/// ## Example
///
/// ```dart
/// final trial = Trial(content: (Fluffy fluffy) {
///   return (BuildContext context) {
///     return const Text('Hello world');
///   };
/// });
///
/// final mainLoop = MainLoop(
///   children: [trial],
/// );
///
/// final fluffy = Fluffy(mainLoop: mainLoop);
/// ```
///
/// See also:
///
///  * [Trial], for how to create a single trial
///  * [Loop], for how to create a loop
///  * [MainLoop], for how to create a main loop for the experiment
///
/// {@category Introduction}
final class Fluffy {
  /// Creates a [Fluffy] instance based on the provided [MainLoop] object
  Fluffy({
    required this.mainLoop,
  });

  /// The main loop of the experiment containing all the [Trial]s and [Loop]s.
  final MainLoop mainLoop;

  /// The trial that is currently running.
  ///
  /// This is needed because we need to provide exact information regarding the
  /// current trial when calling [finishTrial].
  late FluffyTrial _currentTrial;

  /// Storage of experiment data
  final FluffyData data = FluffyData();

  /// Value notifier, indicating the content of the current trial.
  final _content = ValueNotifier<Widget Function(BuildContext context)?>(null);

  /// The start time of the **current** trial in milliseconds
  int _currentTrialStartTime = -1;

  /// Start running the experiment
  void run() {
    _run();
    Timer(Duration.zero, () {
      _parseMainLoop().run();
    });
  }

  /// Finishes the current trial, stores data and proceeds to the next trial.
  ///
  /// When creating a [Trial], you need to call this to signify the end of the
  /// trial, otherwise that trial will go on forever and the experiment will not
  /// proceed.
  ///
  /// While you can insert almost anything you wish to store in [data], a few
  /// properties are reserved for internal use of the Fluffy library, which are:
  ///
  ///  * level: level of the trial; a trial that directly belongs to the [mainLoop]
  ///    has a level of `0`, whereas one that belongs to a loop of level `0`
  ///    would have a level of `1`.
  ///  * startTime: time stamp in milliseconds when the trial starts
  ///  * endTime: time stamp in milliseconds when the trial ends
  ///
  /// There is no preventing you from adding these properties yourself when calling
  /// [finishTrial], but they will be automatically covered afterwards and your
  /// record of these values is then gone forever.
  void finishTrial(Map<String, dynamic> data) {
    int finishTime = _getTimeInMilliseconds();

    data['level'] = _currentTrial.level;
    data['startTime'] = _currentTrialStartTime;
    data['endTime'] = finishTime;

    this.data.addDataItem(data);

    _currentTrial._next()?.run();
  }

  /// Runs the app.
  void _run() {
    runApp(MaterialApp(home: FluffyContent(root: this)));
  }

  /// Spreads the [mainLoop] and returns the [FluffyLoopStart] that begins the
  /// spread loop.
  ///
  /// For more detail on how the spreading is done, see [FluffyLoop.spreadLoop].
  FluffyLoopStart _parseMainLoop() {
    return FluffyLoop(root: this, loop: mainLoop, level: -1).spreadLoop().start;
  }

  int _getTimeInMilliseconds() {
    return DateTime.now().millisecondsSinceEpoch;
  }
}

/// Describes the basic configuration for the nodes in the experiment **at run
/// time**.
///
/// The [TrialOrLoop] objects created by the user serves as a template to describe
/// trials or loops; what is actually run is not a [TrialOrLoop] object but the
/// outcome that the Fluffy library gets from parsing it, that is a [FluffyNode].
///
/// Three sorts of nodes inherit from this, which are:
///
///  * [FluffyTrial], which is parsed out of a [Trial]
///  * [FluffyLoopStart], which signifies the start of a [Loop]
///  * [FluffyLoopEnd], which signifies the end of a [Loop]
abstract class FluffyNode {
  /// The next [FluffyNode], if the current node is not [repeat]ed, to proceed to
  FluffyNode? next;

  /// Skips the current node if this returns `true`
  ///
  /// When the [FluffyNode] is a:
  ///
  ///  * [FluffyTrial], this is copied from the [Trial] the node parses
  ///  * [FluffyLoopStart], this is copied from the [Loop] the node parses
  ///  * [FluffyLoopEnd], this will stick to the default value
  bool Function(Fluffy fluffy) skip = (Fluffy fluffy) => false;

  /// Returns the current node if this returns `true`
  ///
  /// When the [FluffyNode] is a:
  ///
  ///  * [FluffyTrial], this is copied from the [Trial] the node parses
  ///  * [FluffyLoopStart], this will stick to the default value
  ///  * [FluffyLoopEnd], this is copied from the [Loop] the node parses
  bool Function(Fluffy fluffy) repeat = (Fluffy fluffy) => false;

  /// Runs the [FluffyNode].
  ///
  /// See its child classes for detailed implementation.
  void run();

  /// Proceed to the next [FluffyNode], taking into account the result of [repeat].
  ///
  /// See its child classes for detailed implementation.
  // ignore: unused_element
  FluffyNode? _next();
}

/// The trial that is actually run in an experiment.
///
/// This differs from [Trial] in that the latter is a template, the parsing of
/// which generates an instance of [FluffyTrial].
class FluffyTrial extends FluffyNode {
  /// Parses a given [Trial], binds the generated instance to a [Fluffy] instance,
  /// and marks its [level] in the experiment's main loop.
  ///
  /// The [trial]'s [Trial.repeat] and [Trial.skip] fields are correspondingly
  /// copied to the [FluffyTrial]'s [repeat] and [skip] fields.
  ///
  /// As for the [trial] itself, it is deep-copied using the [Trial.copy]
  /// constructor, so that modifications made to the it after the experiment has
  /// started will not interfere with the [FluffyTrial] instance.
  FluffyTrial({
    required this.root,
    required Trial trial,
    required this.level,
  }) {
    this.trial = Trial.copy(trial);

    skip = this.trial.skip;
    repeat = this.trial.repeat;
  }

  /// The [Fluffy] instance to which the current [FluffyTrial] is bound.
  final Fluffy root;

  /// The trial from which the current [FluffyTrial] is parsed.
  late final Trial trial;

  /// The level of the current [FluffyTrial] in the experiment's main loop.
  ///
  /// A level of `0` indicates that this is a top-level node, whereas a level of
  /// `1` indicates that this belongs to a top-level loop, etc.
  final int level;

  /// Runs the trial.
  ///
  /// If [skip] evaluates to `true`, skips the trial and also the [repeat] function.
  /// Otherwise, the [root] will be notified of the start of a new trial, which
  /// will then dispatch a notification to the corresponding [FluffyContent],
  /// informing it to render something new.
  @override
  void run() {
    root._currentTrial = this;
    bool willSkip = skip(root);

    if (!willSkip) {
      Duration startTrialAfter;
      if (trial.startTrialAfterFunc != null) {
        startTrialAfter = trial.startTrialAfterFunc!(root);
      } else {
        startTrialAfter = trial.startTrialAfter;
      }

      if (startTrialAfter.inMilliseconds > 0) {
        root._content.value = null;
      }

      Timer(startTrialAfter, () {
        root._content.value = trial.content(root);
      });
    } else {
      // If the trial should be skipped, then skip `repeat` all together and
      // proceed directly to the next node specified by `next`.
      next?.run();
    }
  }

  /// Proceeds to the next [FluffyNode].
  ///
  /// Evaluates the [repeat] function, and proceeds to [next] should it return
  /// `false` or repeat the current [FluffyTrial] should it return `true`.
  @override
  FluffyNode? _next() {
    return repeat(root) ? this : next;
  }
}

/// Marks the start of a [FluffyLoop].
///
/// Although it is not clear in here, one might see that the [skip] method of a
/// [FluffyLoopStart] is set in the [FluffyLoop.spreadLoop] method, copied from
/// the corresponding [Loop.skip].
class FluffyLoopStart extends FluffyNode {
  FluffyLoopStart({required this.root});

  /// The paired [FluffyLoopEnd] that marks the end of the same [FluffyLoop].
  ///
  /// This value is automatically set in the [FluffyLoop.spreadLoop] method.
  late final FluffyLoopEnd pair;

  /// The [Fluffy] instance to which the current [FluffyLoopStart] is bound.
  final Fluffy root;

  /// Proceeds directly to the next [FluffyNode].
  @override
  void run() {
    _next()?.run();
  }

  /// Proceeds to the next [FluffyNode].
  ///
  /// If [skip] returns `true`, proceed to [FluffyLoopEnd.next]. Otherwise,
  /// proceed to the [next] trial.
  @override
  FluffyNode? _next() {
    return skip(root) ? pair.next : next;
  }
}

/// Marks the end of a [FluffyLoop].
///
/// Although it is not clear in here, one might see that the [repeat] method of a
/// [FluffyLoopEnd] is set in the [FluffyLoop.spreadLoop] method, copied from
/// the corresponding [Loop.repeat].
class FluffyLoopEnd extends FluffyNode {
  FluffyLoopEnd({required this.root});

  /// The paired [FluffyLoopStart] that marks the start of the same [FluffyLoop].
  ///
  /// This value is automatically set in the [FluffyLoop.spreadLoop] method.
  late final FluffyLoopStart pair;

  /// The [Fluffy] instance to which the current [FluffyLoopEnd] is bound.
  final Fluffy root;

  /// Proceeds directly to the next [FluffyNode].
  @override
  void run() {
    _next()?.run();
  }

  /// Proceeds to the next [FluffyNode].
  ///
  /// If [repeat] returns `true`, proceed to [FluffyLoopStart.next]. Otherwise,
  /// proceed to the [next] trial.
  @override
  FluffyNode? _next() {
    return repeat(root) ? pair.next : next;
  }
}

/// Describes the start and end of a [FluffyLoop].
class FluffyLoopSummary {
  FluffyLoopSummary(this.start, this.end);

  final FluffyLoopStart start;
  final FluffyLoopEnd end;
}

/// Parses a [Loop] or [MainLoop] object, spreading it into a chain of [FluffyNode]s.
///
/// Although this bears the same prefix as [FluffyTrial], [FluffyLoopStart] and
/// [FluffyLoopEnd], [FluffyLoop] is not in reality a node to be run, as can be
/// seen that it does not inherit [FluffyNode]. What it actually does is spreading
/// a loop.
///
/// For example, we have a simple main loop here:
///
/// ```dart
/// Trial trial1, trial2, trial3;
/// final loop = Loop(children: [trial2, trial3]);
/// final mainLoop = MainLoop(children: [trial1, loop]);
/// ```
///
/// By parsing this main loop using [FluffyLoop], we get a chain of [FluffyNode]s
/// like this:
///
/// mainLoop-start ->
///  trial1 ->
///  loop-start ->
///   trial2 -> trial3 ->
///  loop-end ->
/// mainLoop-end
///
/// Now, by accessing the first [FluffyNode], the [FluffyLoopStart] of the main
/// loop, we can eventually gain access all nodes defined in it.
class FluffyLoop {
  /// Parses a given [Loop], binds the generated instance to a [Fluffy] instance,
  /// and marks its [level] in the experiment's main loop. The [root] and [level]
  /// properties are further passed down to the child [FluffyTrial] and [FluffyLoop]
  /// objects.
  ///
  /// A pair of [FluffyLoopStart] and [FluffyLoopEnd] objects are automatically
  /// generated, and the [loop]'s [Loop.repeat] and [Loop.skip] fields are
  /// correspondingly copied to [FluffyLoopEnd.repeat] and [FluffyLoopStart.skip].
  ///
  /// As for the [loop] itself, it is deep-copied using the [Loop.copy]
  /// constructor, so that modifications made to the it after the experiment has
  /// started will not interfere with the [FluffyLoop] instance.
  FluffyLoop({
    required this.root,
    required Loop loop,
    required this.level,
  }) {
    this.loop = Loop.copy(loop);
  }

  /// The [Fluffy] instance to which the current [FluffyLoop] is bound.
  final Fluffy root;

  /// The loop from which the current [FluffyLoop] is parsed.
  late final Loop loop;

  /// The level of the current [FluffyLoop] in the experiment's main loop.
  ///
  /// A level of `0` indicates that this is a top-level loop.
  late int level;

  /// The next [FluffyNode], if the current loop is not repeated, to proceed to
  FluffyNode? next;

  /// Spreads the loop in a recursive fashion.
  ///
  /// We need only the first and last [FluffyNode] of the spread loop, which are
  /// [FluffyLoopStart] and [FluffyLoopEnd] objects respectively, to be able to
  /// insert the spread result into a chain of [FluffyTrial]s, and thus this method
  /// returns a [FluffyLoopSummary] object that provides such info.
  FluffyLoopSummary spreadLoop() {
    FluffyLoopStart loopFirstNode = FluffyLoopStart(root: root)
      ..skip = loop.skip;
    FluffyLoopEnd loopLastNode = FluffyLoopEnd(root: root)
      ..next = next
      ..repeat = loop.repeat;

    pair(loopFirstNode, loopLastNode);

    FluffyNode currentNode = loopFirstNode;

    for (int i = 0; i < loop._children.length; i++) {
      TrialOrLoop node = loop._children[i];

      if (node is Trial) {
        FluffyTrial trial = FluffyTrial(
          root: root,
          trial: node,
          level: level + 1,
        );

        // Points the current node to the next trial, then set the next trial as
        // `currentNode`
        currentNode.next = trial;
        currentNode = trial;
      } else if (node is Loop) {
        FluffyLoop innerLoop = FluffyLoop(
          root: root,
          loop: node,
          level: level + 1,
        );

        // Things are a little more complicated when the next node is a loop, but
        // only just. We have to point the current node to the `FluffyLoopStart`
        // of the parsed loop, and then move `currentNode` to `FluffyLoopEnd` of
        // that same loop.
        FluffyLoopSummary summary = innerLoop.spreadLoop();
        currentNode.next = summary.start;
        currentNode = summary.end;
      }
    }

    currentNode.next = loopLastNode;

    return FluffyLoopSummary(loopFirstNode, loopLastNode);
  }

  /// Pairs a [FluffyLoopStart] and a [FluffyLoopEnd] object, setting the `pair`
  /// property of each to the other.
  void pair(FluffyLoopStart start, FluffyLoopEnd end) {
    start.pair = end;
    end.pair = start;
  }
}

/// The [Widget] that wraps the experiment content.
///
/// This wrapper also wraps in it the content that does not change as the
/// experiment goes on, such as the outermost [Container] widget and the [Center]
/// widget within.
class FluffyContent extends StatefulWidget {
  const FluffyContent({
    super.key,
    required this.root,
  });

  final Fluffy root;

  @override
  State<FluffyContent> createState() => _FluffyContentState();
}

class _FluffyContentState extends State<FluffyContent> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.root._content,
      builder: (
        BuildContext context,
        Widget Function(BuildContext context)? value,
        Widget? _,
      ) {
        Size size = MediaQuery.of(context).size;
        double smallerOfWidthAndHeight = min(size.width, size.height);
        double defaultFontSize = smallerOfWidthAndHeight / 20;
        TextStyle defaultTextStyle = TextStyle(
          color: Colors.black,
          decoration: TextDecoration.none,
          fontSize: defaultFontSize,
          fontWeight: FontWeight.normal,
        );

        return Container(
          color: Colors.white,
          child: Center(
            child: DefaultTextStyle(
              style: defaultTextStyle,
              child: value == null
                  ? Container()
                  : FluffyInnerContent(root: widget.root, child: value),
            ),
          ),
        );
      },
    );
  }
}

/// The [Widget] that wraps the experiment content which changes as the experiment
/// proceeds.
class FluffyInnerContent extends StatefulWidget {
  const FluffyInnerContent({
    super.key,
    required this.root,
    required this.child,
  });

  final Fluffy root;

  final Widget Function(BuildContext context) child;

  @override
  State<FluffyInnerContent> createState() => _FluffyInnerContentState();
}

class _FluffyInnerContentState extends State<FluffyInnerContent> {
  void updateTrialStartTime() {
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      widget.root._currentTrialStartTime = widget.root._getTimeInMilliseconds();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child(context);
  }

  @override
  void initState() {
    super.initState();
    updateTrialStartTime();
  }

  @override
  void didUpdateWidget(FluffyInnerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateTrialStartTime();
  }
}
