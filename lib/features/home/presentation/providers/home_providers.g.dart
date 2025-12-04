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
String _$productsListHash() => r'975ba31f769d9e316d61fcdcc3017aa15ee80322';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
