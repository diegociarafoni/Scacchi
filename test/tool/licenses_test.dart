import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/licenses.dart';

void main() {
  group('riconoscimento delle licenze', () {
    test('MIT', () {
      expect(
        detectLicense(
          'Permission is hereby granted, free of charge, to any person '
          'obtaining a copy of this software',
        ),
        'MIT',
      );
    });

    test('BSD-3-Clause', () {
      expect(
        detectLicense(
          'Redistribution and use in source and binary forms, with or '
          'without modification, are permitted provided that ... '
          'Neither the name of Google Inc. nor the names of its contributors '
          'may be used to endorse or promote products',
        ),
        'BSD-3-Clause',
      );
    });

    test('BSD-2-Clause', () {
      expect(
        detectLicense(
          'Redistribution and use in source and binary forms, with or '
          'without modification, are permitted provided that the following '
          'conditions are met',
        ),
        'BSD-2-Clause',
      );
    });

    test('Apache-2.0', () {
      expect(
        detectLicense('Apache License\nVersion 2.0, January 2004'),
        'Apache-2.0',
      );
    });

    test('GPL-3.0', () {
      expect(
        detectLicense('GNU GENERAL PUBLIC LICENSE\nVersion 3, 29 June 2007'),
        'GPL-3.0',
      );
    });

    test('AGPL-3.0 non si confonde con GPL-3.0', () {
      expect(
        detectLicense(
          'GNU AFFERO GENERAL PUBLIC LICENSE\nVersion 3, 19 November 2007',
        ),
        'AGPL-3.0',
      );
    });

    test('GPL-3.0 che cita la AGPL nella sezione 13', () {
      expect(
        detectLicense(
          'GNU GENERAL PUBLIC LICENSE\nVersion 3, 29 June 2007\n'
          '${'testo ' * 200}'
          '13. Use with the GNU Affero General Public License.',
        ),
        'GPL-3.0',
      );
    });

    test('testo sconosciuto', () {
      expect(detectLicense('All rights reserved.'), isNull);
    });
  });

  test('le licenze proprietarie o ignote non sono compatibili', () {
    const allowed = {'MIT', 'GPL-3.0'};
    expect(isAllowed('MIT', allowed), isTrue);
    expect(isAllowed(null, allowed), isFalse);
    expect(isAllowed('SSPL-1.0', allowed), isFalse);
  });
}
