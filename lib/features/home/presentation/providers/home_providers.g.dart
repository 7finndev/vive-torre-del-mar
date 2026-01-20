// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$localDbHash() => r'02a8a5c599aca41b8bdaab46eab1e4f93296dbfa';

/// See also [localDb].
@ProviderFor(localDb)
final localDbProvider = AutoDisposeProvider<LocalDbService>.internal(
  localDb,
  name: r'localDbProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$localDbHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LocalDbRef = AutoDisposeProviderRef<LocalDbService>;
String _$establishmentRepositoryHash() =>
    r'b300c9b23d34e300876ed05bd6fba8732135ae21';

/// See also [establishmentRepository].
@ProviderFor(establishmentRepository)
final establishmentRepositoryProvider =
    AutoDisposeProvider<EstablishmentRepository>.internal(
  establishmentRepository,
  name: r'establishmentRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$establishmentRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EstablishmentRepositoryRef
    = AutoDisposeProviderRef<EstablishmentRepository>;
String _$establishmentsListHash() =>
    r'063787dfca766f3fc7a16a87eef34cbe73fcf657';

/// See also [establishmentsList].
@ProviderFor(establishmentsList)
final establishmentsListProvider =
    AutoDisposeFutureProvider<List<EstablishmentModel>>.internal(
  establishmentsList,
  name: r'establishmentsListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$establishmentsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EstablishmentsListRef
    = AutoDisposeFutureProviderRef<List<EstablishmentModel>>;
String _$connectivityStreamHash() =>
    r'2b9c6b00272455180b3b92776f6caae413ddc00f';

/// See also [connectivityStream].
@ProviderFor(connectivityStream)
final connectivityStreamProvider =
    AutoDisposeStreamProvider<List<ConnectivityResult>>.internal(
  connectivityStream,
  name: r'connectivityStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectivityStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ConnectivityStreamRef
    = AutoDisposeStreamProviderRef<List<ConnectivityResult>>;
String _$productsListHash() => r'0002579cdaaf7da8e05f1988f5eefa91244a1e54';

/// See also [productsList].
@ProviderFor(productsList)
final productsListProvider =
    AutoDisposeFutureProvider<List<ProductModel>>.internal(
  productsList,
  name: r'productsListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$productsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProductsListRef = AutoDisposeFutureProviderRef<List<ProductModel>>;
String _$passportRepositoryHash() =>
    r'ff2638d27de373fc1e6b6357536e621433255691';

/// See also [passportRepository].
@ProviderFor(passportRepository)
final passportRepositoryProvider =
    AutoDisposeProvider<PassportRepository>.internal(
  passportRepository,
  name: r'passportRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$passportRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PassportRepositoryRef = AutoDisposeProviderRef<PassportRepository>;
String _$currentEventHash() => r'b8c60972fd5ed9523ac0a4d1bca3fef7a32b8ed7';

/// See also [currentEvent].
@ProviderFor(currentEvent)
final currentEventProvider = AutoDisposeFutureProvider<EventModel>.internal(
  currentEvent,
  name: r'currentEventProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentEventHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentEventRef = AutoDisposeFutureProviderRef<EventModel>;
String _$activeEventsListHash() => r'fc9e37cac919da6ca8a9efceaeeb45a0e1c0eb12';

/// See also [activeEventsList].
@ProviderFor(activeEventsList)
final activeEventsListProvider =
    AutoDisposeFutureProvider<List<EventModel>>.internal(
  activeEventsList,
  name: r'activeEventsListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeEventsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActiveEventsListRef = AutoDisposeFutureProviderRef<List<EventModel>>;
String _$allEstablishmentsListHash() =>
    r'c075aa87774f81cdd330313faaf6665949b3a14b';

/// See also [allEstablishmentsList].
@ProviderFor(allEstablishmentsList)
final allEstablishmentsListProvider =
    AutoDisposeFutureProvider<List<EstablishmentModel>>.internal(
  allEstablishmentsList,
  name: r'allEstablishmentsListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allEstablishmentsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllEstablishmentsListRef
    = AutoDisposeFutureProviderRef<List<EstablishmentModel>>;
String _$eventDetailsHash() => r'fd0d0f12cb8fb76b4c5ffa7e71156e5d3f1ac325';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [eventDetails].
@ProviderFor(eventDetails)
const eventDetailsProvider = EventDetailsFamily();

/// See also [eventDetails].
class EventDetailsFamily extends Family<AsyncValue<EventModel>> {
  /// See also [eventDetails].
  const EventDetailsFamily();

  /// See also [eventDetails].
  EventDetailsProvider call(
    int eventId,
  ) {
    return EventDetailsProvider(
      eventId,
    );
  }

  @override
  EventDetailsProvider getProviderOverride(
    covariant EventDetailsProvider provider,
  ) {
    return call(
      provider.eventId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'eventDetailsProvider';
}

/// See also [eventDetails].
class EventDetailsProvider extends AutoDisposeFutureProvider<EventModel> {
  /// See also [eventDetails].
  EventDetailsProvider(
    int eventId,
  ) : this._internal(
          (ref) => eventDetails(
            ref as EventDetailsRef,
            eventId,
          ),
          from: eventDetailsProvider,
          name: r'eventDetailsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$eventDetailsHash,
          dependencies: EventDetailsFamily._dependencies,
          allTransitiveDependencies:
              EventDetailsFamily._allTransitiveDependencies,
          eventId: eventId,
        );

  EventDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.eventId,
  }) : super.internal();

  final int eventId;

  @override
  Override overrideWith(
    FutureOr<EventModel> Function(EventDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EventDetailsProvider._internal(
        (ref) => create(ref as EventDetailsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        eventId: eventId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<EventModel> createElement() {
    return _EventDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EventDetailsProvider && other.eventId == eventId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, eventId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin EventDetailsRef on AutoDisposeFutureProviderRef<EventModel> {
  /// The parameter `eventId` of this provider.
  int get eventId;
}

class _EventDetailsProviderElement
    extends AutoDisposeFutureProviderElement<EventModel> with EventDetailsRef {
  _EventDetailsProviderElement(super.provider);

  @override
  int get eventId => (origin as EventDetailsProvider).eventId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
