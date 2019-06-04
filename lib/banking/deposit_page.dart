import 'package:flutter/material.dart';
import 'package:proxy_flutter/banking/banking_service_factory.dart';
import 'package:proxy_flutter/banking/db/deposit_repo.dart';
import 'package:proxy_flutter/banking/model/deposit_entity.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:proxy_flutter/services/event_bloc.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';

import 'event_actions.dart';

class DepositPage extends StatefulWidget {
  final DepositEntity depositEntity;

  const DepositPage({
    Key key,
    @required this.depositEntity,
  }) : super(key: key);

  @override
  DepositPageState createState() {
    return DepositPageState(
      depositEntity: depositEntity,
    );
  }
}

class DepositPageState extends LoadingSupportState<DepositPage> {
  final DepositEntity depositEntity;

  final EventBloc eventBloc = ServiceFactory.eventBloc();
  final EventActions eventActions = BankingServiceFactory.eventActions();

  DepositPageState({
    @required this.depositEntity,
  });



  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.depositEventTitle),
        actions: [
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(),
            child: new Text(
              localizations.okButtonLabel,
              style: Theme.of(context)
                  .textTheme
                  .subhead
                  .copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: StreamBuilder<DepositEntity>(
            stream: eventBloc.events,
            initialData: [],
            builder: (BuildContext context,
                AsyncSnapshot<DepositEntity> snapshot) {
              return body(context, localizations, snapshot);
            },
          ),
        ),
      ),
    );
  }

  Widget body(BuildContext context, ProxyLocalizations localizations,
      AsyncSnapshot<DepositEntity> snapshot) {
    ThemeData themeData = Theme.of(context);
    DepositEntity latestEvent;
    if (snapshot.hasData) {
      latestEvent = snapshot.data;
    }

    List<Widget> rows = [
      const SizedBox(height: 16.0),
      Icon(Icons.file_download, size: 64.0),
      const SizedBox(height: 24.0),
      Center(
        child: Text(
          localizations.amount,
        ),
      ),
      const SizedBox(height: 8.0),
      Center(
        child: Text(
          event.getAmountText(localizations),
          style: themeData.textTheme.title,
        ),
      ),
      const SizedBox(height: 24.0),
      Center(
        child: Text(
          localizations.status,
        ),
      ),
      const SizedBox(height: 8.0),
      Center(
        child: Text(
          latestEvent?.getStatus(localizations) ?? localizations.eventDeleted,
          style: themeData.textTheme.title,
        ),
      ),
    ];
    List<EventAction> actions =
        eventActions.getPossibleActions(latestEvent, localizations);
    if (actions.isNotEmpty) {
      rows.add(const SizedBox(height: 24.0));
      rows.add(ButtonBar(
        alignment: MainAxisAlignment.spaceAround,
        children: actions.map(_actionButton).toList(),
      ));
    }
    return ListView(children: rows);
  }

  Widget _actionButton(EventAction action) {
    return RaisedButton.icon(
      onPressed: () => invoke(action.action),
      icon: Icon(action.icon),
      label: Text(action.title),
    );
  }
}
