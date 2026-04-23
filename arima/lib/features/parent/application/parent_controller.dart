import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parent_repository.dart';
import '../domain/child_stats.dart';
import '../domain/linked_child.dart';

final AsyncNotifierProvider<ParentController, ParentState> parentControllerProvider =
    AsyncNotifierProvider<ParentController, ParentState>(ParentController.new);

class ParentState {
  const ParentState({
    this.children = const [],
    this.selectedChildId,
    this.selectedChildStats,
  });

  final List<LinkedChild> children;
  final int? selectedChildId;
  final ChildStats? selectedChildStats;

  ParentState copyWith({
    List<LinkedChild>? children,
    int? selectedChildId,
    ChildStats? selectedChildStats,
  }) {
    return ParentState(
      children: children ?? this.children,
      selectedChildId: selectedChildId ?? this.selectedChildId,
      selectedChildStats: selectedChildStats ?? this.selectedChildStats,
    );
  }

  List<Map<String, dynamic>> get escalatedTasks {
    final List<Map<String, dynamic>> result = [];
    for (final child in children) {
      for (final task in child.recentTasks) {
        if (task['reminder'] != null &&
            task['reminder']['escalated_to_parent'] == true) {
          result.add(<String, dynamic>{
            ...task,
            'child_name': child.childName,
            'child_id': child.childId,
          });
        }
      }
    }
    return result;
  }
}

class ParentController extends AsyncNotifier<ParentState> {
  @override
  Future<ParentState> build() async {
    final children = await ref.read(parentRepositoryProvider).fetchLinkedChildren();
    return ParentState(children: children);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final children = await ref.read(parentRepositoryProvider).fetchLinkedChildren();
      return ParentState(children: children);
    });
  }

  Future<void> selectChild(int childId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final stats = await ref.read(parentRepositoryProvider).fetchChildStats(childId);
    state = AsyncValue.data(current.copyWith(
      selectedChildId: childId,
      selectedChildStats: stats,
    ));
  }

  Future<void> linkChild(String email) async {
    await ref.read(parentRepositoryProvider).linkChild(email);
    await refresh();
  }

  Future<void> unlinkChild(int childId) async {
    await ref.read(parentRepositoryProvider).unlinkChild(childId);
    await refresh();
  }

  void clearSelection() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(
      selectedChildId: null,
      selectedChildStats: null,
    ));
  }
}
