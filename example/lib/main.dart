import 'package:flutter/material.dart';
import 'package:fluffy/fluffy.dart';

void main() {
  int count = 0;
  content(int value) {
    return (Fluffy fluffy) {
      return (BuildContext context) {
        return GestureDetector(
          onTap: () {
            FluffyUtils.alert(
              context: context,
              title: 'Title ',
              content: 'Trial finished',
            ).then((value) async {
              await FluffyUtils.vibrate();

              count++;
              fluffy.finishTrial({});
            });
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            child: Text(
              '$count - $value',
            ),
          ),
        );
      };
    };
  }

  int repeat1 = 0;
  int repeat2 = 0;

  final mainLoop = MainLoop(
    children: [
      // Level 0
      Loop(children: [
        // Level 1
        Trial(
          content: content(1),
          startTrialAfter: const Duration(
            milliseconds: 200,
          ),
        )..repeat = (fluffy) {
            // repeat three extra times, resulting in 4 repeats in total
            while (repeat1 < 3) {
              repeat1++;
              return true;
            }
            return false;
          },
        // Level 1
        Trial(
            content: content(1),
            startTrialAfterFunc: (Fluffy fluffy) {
              print('Start trial after func');
              return const Duration(milliseconds: 500);
            })
          ..skip = (fluffy) => true,
        // Level 1
        Loop(children: [
          // Level 2
          Loop(children: [
            // Level 3
            Trial(
              content: content(3),
              startTrialAfterFunc: (Fluffy fluffy) {
                print('Start trial after func');
                return const Duration(milliseconds: 500);
              },
            ),
            // Level 3
            Loop(children: [
              // Level 4
              Trial(content: content(4)),
              // Level 4
              Trial(content: content(4)),
            ])
              ..repeat = (fluffy) {
                if (repeat2 == 0) {
                  repeat2 = 1;
                  return true;
                } else {
                  return false;
                }
              },
            Loop(children: [
              // Level 4
              Trial(content: content(4)),
              // Level 4
              Trial(content: content(4)),
            ]),
            // Level 3
            Trial(content: content(3)),
          ]),
          // Level 2
          Trial(content: content(2)),
        ]),
      ]),
    ],
  );
  mainLoop.repeat = (Fluffy fluffy) {
    fluffy.data.saveAsExcel(fileName: 'data/data.xlsx');
    return false;
  };

  final fluffy = Fluffy(mainLoop: mainLoop);
  fluffy.run();
}
