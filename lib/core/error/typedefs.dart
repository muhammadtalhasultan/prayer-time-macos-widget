import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// A type definition for a Future that returns Either a Failure or a generic type T
/// Used for async operations that return data
/// Example: ResultFuture<List<Employee>>
typedef ResultFuture<T> = Future<Either<Failure, T>>;

/// A type definition for a Future that returns Either a Failure or void
/// Used for async operations that don't return data (like delete, update)
/// Example: ResultVoid for deleteEmployee()
typedef ResultVoid = Future<Either<Failure, void>>;

/// A type definition for JSON Map objects
/// Makes it easier to work with JSON data from API responses
typedef DataMap = Map<String, dynamic>;
