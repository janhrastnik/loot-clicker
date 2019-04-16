import 'package:bloc/bloc.dart';
import 'main.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'classes.dart';

class DungeonBloc extends Bloc<List<DungeonTile>, List<DungeonTile>> {
  @override
  List<DungeonTile> get initialState => [
    DungeonTile(event: DungeonEvent(eventType: "fight", length: 10, enemy: rat)),
    DungeonTile(event: DungeonEvent(eventType: "fight", length: 10, enemy: rat)),
    DungeonTile(event: DungeonEvent(eventType: "fight", length: 10, enemy: rat))
  ];

  List eventTypes = ["loot", "fight", "puzzle"];

  DungeonTile generateDungeon() {
    int randomRange(int min, int max) => min + Random().nextInt(max - min);
    String dungeonType = eventTypes[Random().nextInt(eventTypes.length)];
    int lootAmount = randomRange(1, 10);
    int length = randomRange(10, 20);
    Enemy enemyTest;
    if (dungeonType == "fight") {
      enemyTest = rat;
      length = enemyTest.hp;
    }

    return DungeonTile(event: DungeonEvent(
        eventType: dungeonType,
        length: length,
        loot: lootAmount,
        enemy: dungeonType == "fight" ? enemyTest : null
    ));
  }

  @override
  Stream<List<DungeonTile>> mapEventToState(List<DungeonTile> event) async* {

    switch (event.length) {
      case 3:
        final List<DungeonTile> newList = List.from(event, growable: true);
        newList.add(generateDungeon());
        yield newList;
        break;
      case 4:
        final List<DungeonTile> newList = List.from(event);
        newList.removeAt(0);
        yield newList;
        break;
    }
  }
}

class ClickerBloc extends Bloc<List<DungeonTile>, double> {
  double get initialState => 0.0;
  final GoldBloc goldBloc;
  final HeroHpBloc heroHpBloc;
  final HeroExpBloc heroExpBloc;
  final DungeonBloc dungeonBloc;

  ClickerBloc({this.goldBloc, this.heroHpBloc, this.heroExpBloc, this.dungeonBloc});

  void scrollToMiddle() {
    scrollController.jumpTo(TILE_LENGTH/2);
  }

  void scrollDungeon(DungeonBloc bloc) {
    scrollToMiddle();
    bloc.dispatch(dungeonTiles);
    scrollController.animateTo(
        scrollController.offset + TILE_LENGTH,
        duration: Duration(seconds: 1),
        curve: Curves.ease
    ).then((data) {
      bloc.dispatch(dungeonTiles);
      scrollToMiddle();
      isScrolling = false;
    });
  }

  @override
  Stream<double> mapEventToState(List<DungeonTile> event) async* {
    final DungeonEvent currEvent = event[1].event;

    print(isMenu.toString());
    switch(currEvent.eventType) {
      case "fight":
        currEvent.progress++;
        heroHpBloc.dispatch(currEvent.enemy.attack);
        if (currEvent.progress == currEvent.length) {
          if (event[2].event.eventType == "fight") {
            currEvent.progress = 0;
          } else {
            currEvent.progress = event[2].event.length;
          }
          currEvent.length = event[2].event.length;
          if (isMenu == false) {
            isScrolling = true;
            scrollDungeon(dungeonBloc);
          }
          heroExpBloc.dispatch(currEvent.enemy.expValue);
          yield -1;
        } else {
          yield 1 - (currEvent.progress / currEvent.length);
        }
        break;
      case "loot":
        currEvent.progress++;
        if (currEvent.progress == currEvent.length) {
          currEvent.progress = 0;
          currEvent.length = event[2].event.length;
          goldBloc.dispatch(currEvent.loot);
          if (isMenu == false) {
            isScrolling = true;
            scrollDungeon(dungeonBloc);
          }
          yield -1;
        } else {
          yield currEvent.progress / currEvent.length;
        }
        break;
      case "puzzle":
        currEvent.progress++;
        if (currEvent.progress == currEvent.length) {
          currEvent.progress = 0;
          currEvent.length = event[2].event.length;
          if (isMenu == false) {
            isScrolling = true;
            scrollDungeon(dungeonBloc);
          }
          yield -1;
        } else {
          yield currEvent.progress / currEvent.length;
        }
        break;
    }
  }
}

class GoldBloc extends Bloc<int, int> {
  int get initialState => 0;

  @override
  Stream<int> mapEventToState(int gold) async* {
    int newGold = gold;
    yield newGold;
  }
}

class HeroHpBloc extends Bloc<int, double> {
  double get initialState => 1.0;

  @override
  Stream<double> mapEventToState(int event) async* {
    player.hp = player.hp - event;
    if (player.hp <= 0) {
      print("hero hp dropped to zero.");
      player.gold = (player.gold / 2).round();
      player.hp = player.hpCap;
      // TODO: spawn player in new tile on death
    }
    yield player.hp / player.hpCap;
  }
}

class HeroExpBloc extends Bloc<int, double> {
  double get initialState => 0.0;

  @override
  Stream<double> mapEventToState(int event) async* {
    player.exp = player.exp + event;
    if (player.exp >= player.expCap) {
      print("hero levels up");
      player.exp = 0;
      player.levelUp();
    }
    yield player.exp / player.expCap;
  }
}

class TapAnimationBloc extends Bloc<List, List> {
  List get initialState => [];

  @override
  Stream<List> mapEventToState(List event) async* {
    switch(event[2]) {
      case "fight":
        final List newList = List.from(event, growable: true);
        newList[2] = player.attack;
        yield newList;
        break;
      case "loot":
        final List newList = List.from(event, growable: true);
        newList[2] = player.looting;
        yield newList;
        break;
      case "puzzle":
        final List newList = List.from(event, growable: true);
        newList[2] = player.intelligence;
        yield newList;
        break;
    }
  }
}