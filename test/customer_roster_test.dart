import 'package:flutter_test/flutter_test.dart';
import 'package:nail_glam/game/config/customer_roster.dart';

void main() {
  test('customer1 is Lila', () {
    expect(CustomerRoster.customer1.id, 'customer1');
    expect(CustomerRoster.customer1.name, 'Lila');
    expect(CustomerRoster.lila.id, 'customer1');
    expect(CustomerRoster.forVisit(0).name, 'Lila');
    expect(CustomerRoster.forVisit(3).name, 'Lila');
  });
}
