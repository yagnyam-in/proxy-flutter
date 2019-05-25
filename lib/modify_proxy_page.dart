import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:quiver/strings.dart' as prefix0;

import 'model/contact_entity.dart';
import 'services/contacts_bloc.dart';
import 'services/service_factory.dart';

typedef SetupMasterProxyCallback = void Function(ProxyId proxyId);

class ModifyProxyPage extends StatefulWidget {
  final ContactEntity contactEntity;

  ModifyProxyPage(this.contactEntity, {Key key}) : super(key: key) {
    print("Constructing ModifyProxyPage");
  }

  @override
  _ModifyProxyPageState createState() => _ModifyProxyPageState(contactEntity);
}

class _ModifyProxyPageState extends LoadingSupportState<ModifyProxyPage> with ProxyUtils {
  ContactEntity contactEntity;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ContactsBloc contactsBloc = ServiceFactory.contactsBloc();

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;

  List<String> get validProxyUniverses {
    if (isNotEmpty(contactEntity?.proxyUniverse)) {
      return [contactEntity.proxyUniverse];
    }
    return [ProxyUniverse.PRODUCTION, ProxyUniverse.TEST];
  }

  String _proxyUniverse;

  _ModifyProxyPageState(this.contactEntity)
      : nameController = TextEditingController(text: contactEntity?.name),
        emailController = TextEditingController(text: contactEntity?.email),
        phoneController = TextEditingController(text: contactEntity?.phone),
        _proxyUniverse = contactEntity?.proxyUniverse;


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

    List<Widget> children = [
      new FormField(
        builder: (FormFieldState state) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: localizations.proxyUniverse,
              // helperText: localizations.currencyHint,
            ),
            isEmpty: _proxyUniverse == '',
            child: new DropdownButtonHideUnderline(
              child: new DropdownButton(
                value: _proxyUniverse,
                isDense: true,
                onChanged: (String newValue) {
                  setState(() {
                    _proxyUniverse = newValue;
                    state.didChange(newValue);
                  });
                },
                items: validProxyUniverses.map((String value) {
                  return new DropdownMenuItem(
                    value: value,
                    child: new Text(value),
                  );
                }).toList(),
              ),
            ),
          );
        },
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
    ];

    return Form(
      key: _formKey,
      child: ListView(
        children: children,
      ),
    );
  }

  void _submit(ProxyLocalizations localizations) {
    if (_proxyUniverse == null || _proxyUniverse.isEmpty) {
      print("Invalid Proxy Universe");
      showError(localizations.fieldIsMandatory(localizations.proxyUniverse));
    } else if (!_formKey.currentState.validate()) {
      print("Validation failure");
    } else {
      contactEntity = contactEntity.copy(
        proxyUniverse: _proxyUniverse,
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
      );
      contactsBloc.saveContact(contactEntity);
      Navigator.of(context).pop(contactEntity);
    }
  }

  String _mandatoryFieldValidator(ProxyLocalizations localizations, String value) {
    if (value == null || value.isEmpty) {
      return localizations.fieldIsMandatory(localizations.thisField);
    }
    return null;
  }
}
