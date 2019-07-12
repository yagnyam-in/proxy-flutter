import 'package:flutter/material.dart';
import 'package:proxy_flutter/model/enticement.dart';

import 'widgets/enticement_card.dart';

mixin NoDataHelper {
  Widget noDataCard(
    BuildContext context,
    Enticement enticement, {
    Function action,
  }) {
    return EnticementCard(
      enticement: enticement,
      setup: () => action(context),
      dismiss: () {},
      dismissable: false,
    );
  }
}
