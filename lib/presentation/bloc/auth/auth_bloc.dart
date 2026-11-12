import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/auth_session.dart';
import '../../../domain/usecases/auth/auth_usecases.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// [AuthBloc] coordinates authentication workflows with offline and online mode toggling.
///
/// SOLID Principles:
/// - Single Responsibility Principle (SRP): Manages auth presentation state only.
/// - Dependency Inversion Principle (DIP): Relies on pure domain use cases.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final SignupUseCase signupUseCase;
  final GetAuthSessionUseCase getAuthSessionUseCase;
  final GetPreferredModeUseCase getPreferredModeUseCase;
  final SetPreferredModeUseCase setPreferredModeUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.signupUseCase,
    required this.getAuthSessionUseCase,
    required this.getPreferredModeUseCase,
    required this.setPreferredModeUseCase,
    required this.logoutUseCase,
  }) : super(const AuthState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SwitchConnectionModeEvent>(_onSwitchConnectionMode);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<QuickOfflineAccessEvent>(_onQuickOfflineAccess);
    on<SignupSubmittedEvent>(_onSignupSubmitted);
    on<ClearAuthErrorEvent>(_onClearError);
    on<LogoutAuthEvent>(_onLogout);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final preferredMode = await getPreferredModeUseCase();
      final session = await getAuthSessionUseCase();

      if (session != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          connectionMode: session.connectionMode,
          session: session,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          connectionMode: preferredMode,
        ));
      }
    } catch (_) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        connectionMode: AuthConnectionMode.offline,
      ));
    }
  }

  Future<void> _onSwitchConnectionMode(
    SwitchConnectionModeEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      connectionMode: event.mode,
      clearError: true,
    ));
    try {
      await setPreferredModeUseCase(event.mode);
    } catch (_) {}
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final session = await loginUseCase(
        identifier: event.identifier,
        password: event.password,
        mode: state.connectionMode,
        rememberMe: event.rememberMe,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        session: session,
        successMessage: state.connectionMode == AuthConnectionMode.offline
            ? 'تم الدخول في وضع عدم الاتصال بنجاح'
            : 'تم تسجيل الدخول السحابي بنجاح',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onQuickOfflineAccess(
    QuickOfflineAccessEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      connectionMode: AuthConnectionMode.offline,
      clearError: true,
    ));

    try {
      final session = await loginUseCase(
        identifier: event.localName ?? 'مستخدم حسبتك',
        password: '',
        mode: AuthConnectionMode.offline,
        rememberMe: true,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        session: session,
        successMessage: 'تم الدخول السريع في وضع الأوفلاين ⚡',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onSignupSubmitted(
    SignupSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final session = await signupUseCase(
        name: event.name,
        email: event.email,
        password: event.password,
        mode: state.connectionMode,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        session: session,
        successMessage: state.connectionMode == AuthConnectionMode.offline
            ? 'تم إنشاء الخزينة المحلية بنجاح'
            : 'تم إنشاء حسابك السحابي بنجاح',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void _onClearError(
    ClearAuthErrorEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }

  Future<void> _onLogout(
    LogoutAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    await logoutUseCase();
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      session: null,
      clearError: true,
      clearSuccess: true,
    ));
  }
}
