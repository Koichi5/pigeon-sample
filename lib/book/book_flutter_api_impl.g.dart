// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_flutter_api_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookApiHash() => r'b4fc3dc433cfe85c3c8bec74c58957379525708e';

/// See also [bookApi].
@ProviderFor(bookApi)
final bookApiProvider = AutoDisposeProvider<BookFlutterApiImpl>.internal(
  bookApi,
  name: r'bookApiProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$bookApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BookApiRef = AutoDisposeProviderRef<BookFlutterApiImpl>;
String _$booksHash() => r'576adab76d5da04347061f826df2611a280ca7c1';

/// See also [books].
@ProviderFor(books)
final booksProvider = AutoDisposeFutureProvider<List<Book>>.internal(
  books,
  name: r'booksProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$booksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BooksRef = AutoDisposeFutureProviderRef<List<Book>>;
String _$recordsHash() => r'dbd8647f760d8e9fcf2a665a7813b0a95f51d833';

/// See also [records].
@ProviderFor(records)
final recordsProvider = AutoDisposeFutureProvider<List<Record>>.internal(
  records,
  name: r'recordsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$recordsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecordsRef = AutoDisposeFutureProviderRef<List<Record>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
