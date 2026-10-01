import 'package:equatable/equatable.dart';

/// [Failure] is the base failure class for the domain layer.
///
/// SOLID Principles:
/// - Single Responsibility Principle (SRP): Standardizes application errors across clean layers.
/// - Open/Closed Principle (OCP): New failure types can be introduced via inheritance without altering existing handlers.
/// - Liskov Substitution Principle (LSP): Any sub-failure can be handled where [Failure] is expected.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'حدث خطأ في قاعدة البيانات المحلية']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'فشل استرجاع البيانات المحفوظة محلياً']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'البيانات المدخلة غير صحيحة']);
}
