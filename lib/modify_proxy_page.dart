import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/contact_store.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';

import 'model/contact_entity.dart';

typedef SetupMasterProxyCallback = void Function(ProxyId proxyId);

class ModifyProxyPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final ContactEntity contactEntity;

  ModifyProxyPage(this.appConfiguration, this.contactEntity, {Key key}) : super(key: key) {
    print("Constructing ModifyProxyPage");
  }

  @override
  _ModifyProxyPageState createState() => _ModifyProxyPageState(appConfiguration, contactEntity);
}

class _ModifyProxyPageState extends LoadingSupportState<ModifyProxyPage> with ProxyUtils {
  final AppConfiguration appConfiguration;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ContactStore _contactStore;

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;

  final ContactEntity contactEntity;

  bool loading = false;

  _ModifyProxyPageState(this.appConfiguration, this.contactEntity)
      : _contactStore = ContactStore(appConfiguration),
        nameController = TextEditingController(text: contactEntity?.name),
        emailController = TextEditingController(text: contactEntity?.email),
        phoneController = TextEditingController(text: contactEntity?.phone);

  void showError(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    String title = localizations.saveContactTitle;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(title),
        actions: [
          new FlatButton(
            onPressed: () => _submit(localizations),
            child: new Text(
              localizations.okButtonLabel,
              style: Theme.of(context).textTheme.subhead.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: form(context),
      ),
    );
  }

  Widget form(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        children: [
          new TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: localizations.contactName,
            ),
            validator: (value) => _mandatoryFieldValidator(localizations, value),
          ),
          const SizedBox(height: 8.0),
          new TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: localizations.contactName,
            ),
            validator: (value) => _mandatoryFieldValidator(localizations, value),
          ),
          const SizedBox(height: 8.0),
          new TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: localizations.customerEmail,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8.0),
          new TextFormField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: localizations.customerPhone,
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  void _submit(ProxyLocalizations localizations) async {
    if (!_formKey.currentState.validate()) {
      print("Validation failure");
    } else {
      ContactEntity updatedContact = contactEntity.copy(
        proxyUniverse: appConfiguration.proxyUniverse,
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
      );
      await _contactStore.saveContact(updatedContact);
      Navigator.of(context).pop(updatedContact);
    }
  }

  String _mandatoryFieldValidator(ProxyLocalizations localizations, String value) {
    if (value == null || value.isEmpty) {
      return localizations.fieldIsMandatory(localizations.thisField);
    }
    return null;
  }
}
