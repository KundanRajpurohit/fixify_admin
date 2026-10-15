import 'package:fixify_admin/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Active account routing', () {
    for (final verification in <bool?>[null, false, true]) {
      test('opens dashboard when is_verified is $verification', () {
        final state = PhoneVerificationState(
          authToken: 'test-token',
          accountStatus: 'active',
          isPartnerVerified: verification,
        );

        expect(state.routeTarget, AuthRouteTarget.dashboard);
        expect(state.canOpenDashboard, isTrue);
      });
    }

    test('prioritizes active status over saved document submission', () {
      final state = PhoneVerificationState(
        authToken: 'test-token',
        accountStatus: 'active',
        hasSubmittedDocuments: true,
      );

      expect(state.routeTarget, AuthRouteTarget.dashboard);
    });

    test('requires an authentication token even for active accounts', () {
      final state = PhoneVerificationState(accountStatus: 'active');

      expect(state.routeTarget, AuthRouteTarget.onboarding);
      expect(state.canOpenDashboard, isFalse);
    });

    test('keeps submitted pending accounts awaiting approval', () {
      final state = PhoneVerificationState(
        authToken: 'test-token',
        accountStatus: 'pending',
        isPartnerVerified: true,
        hasSubmittedDocuments: true,
      );

      expect(state.routeTarget, AuthRouteTarget.accountPending);
      expect(state.canOpenDashboard, isFalse);
    });
  });
}
