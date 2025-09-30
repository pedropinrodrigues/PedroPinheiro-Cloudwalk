Map<String, dynamic> buildSeedData() {
  return {
    'schema_version': 1,
    'settings': {'bonus_every': 3, 'bonus_points': 50},
    'session': {'current_uid': null},
    'users': [
      {
        'uid': 'u-demo-1',
        'name': 'Maria Souza',
        'email': 'maria@example.com',
        'sex': 'F',
        'age': 29,
        'my_code': '12345',
        'points_total': 150,
        'invited_by_code': null,
        'password_hash':
            '55a5e9e78207b4df8699d60886fa070079463547b095d1a05bc719bb4e6cd251',
        'created_at': '2024-01-10T12:00:00Z',
        'updated_at': '2024-01-10T12:00:00Z',
      },
      {
        'uid': 'u-demo-2',
        'name': 'Joao Lima',
        'email': 'joao@example.com',
        'sex': 'M',
        'age': 33,
        'my_code': '67890',
        'points_total': 50,
        'invited_by_code': '12345',
        'password_hash':
            '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
        'created_at': '2024-02-01T15:30:00Z',
        'updated_at': '2024-02-01T15:30:00Z',
      },
    ],
    'notifications': [
      {
        'id': 'n-demo-1',
        'inviter_uid': 'u-demo-1',
        'inviter_code': '12345',
        'invited_name': 'Joao Lima',
        'points_awarded': 50,
        'type': 'conversion',
        'created_at': '2024-02-01T15:30:00Z',
      },
      {
        'id': 'n-demo-2',
        'inviter_uid': 'u-demo-1',
        'inviter_code': '12345',
        'invited_name': '',
        'points_awarded': 50,
        'type': 'bonus',
        'created_at': '2024-03-01T10:00:00Z',
      },
    ],
  };
}
