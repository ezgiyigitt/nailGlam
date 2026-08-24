/// One visiting client. This girl is customer1, named Lila.
class CustomerProfile {
  const CustomerProfile({required this.id, required this.name});

  final String id;
  final String name;

  String get introLine => "I'm ready for some glam! 💕";
}

/// Appointment book. New guests get their own id when their sprites land.
abstract final class CustomerRoster {
  static const CustomerProfile customer1 = CustomerProfile(
    id: 'customer1',
    name: 'Lila',
  );

  static const CustomerProfile lila = customer1;

  static const List<CustomerProfile> all = <CustomerProfile>[customer1];

  static CustomerProfile forVisit(int visit) {
    if (all.isEmpty) {
      return customer1;
    }
    final index = visit % all.length;
    return all[index < 0 ? 0 : index];
  }
}
