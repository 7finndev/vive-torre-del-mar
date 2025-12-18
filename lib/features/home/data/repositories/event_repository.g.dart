// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$eventRepositoryHash() => r'1ce454e258785d617cfd18d69f5f5166aa71872a';

/// See also [eventRepository].
@ProviderFor(eventRepository)
final eventRepositoryProvider = AutoDisposeProvider<EventRepository>.internal(
  eventRepository,
  name: r'eventRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$eventRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EventRepositoryRef = AutoDisposeProviderRef<EventRepository>;
String _$adminEventsListHash() => r'3c22b3f8e24078b0109a87151dec4864ed84f89a';

/// See also [adminEventsList].
@ProviderFor(adminEventsList)
final adminEventsListProvider =
    AutoDisposeFutureProvider<List<EventModel>>.internal(
  adminEventsList,
  name: r'adminEventsListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminEventsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AdminEventsListRef = AutoDisposeFutureProviderRef<List<EventModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
