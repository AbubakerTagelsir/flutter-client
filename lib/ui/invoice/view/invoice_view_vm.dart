import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja/redux/client/client_actions.dart';
import 'package:invoiceninja/utils/localization.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja/redux/invoice/invoice_actions.dart';
import 'package:invoiceninja/data/models/models.dart';
import 'package:invoiceninja/ui/invoice/view/invoice_view.dart';
import 'package:invoiceninja/redux/app/app_state.dart';
import 'package:invoiceninja/ui/app/snackbar_row.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceViewScreen extends StatelessWidget {
  static final String route = '/invoice/view';
  InvoiceViewScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, InvoiceViewVM>(
      converter: (Store<AppState> store) {
        return InvoiceViewVM.fromStore(store);
      },
      builder: (context, vm) {
        return InvoiceView(
          viewModel: vm,
        );
      },
    );
  }
}

class InvoiceViewVM {
  final AppState appState;
  final InvoiceEntity invoice;
  final ClientEntity client;
  final Function(BuildContext, EntityAction) onActionSelected;
  final Function(BuildContext) onEditPressed;
  final Function(BuildContext) onClientPressed;
  final bool isLoading;
  final bool isDirty;

  InvoiceViewVM({
    @required this.appState,
    @required this.invoice,
    @required this.client,
    @required this.onActionSelected,
    @required this.onEditPressed,
    @required this.onClientPressed,
    @required this.isLoading,
    @required this.isDirty,
  });

  factory InvoiceViewVM.fromStore(Store<AppState> store) {
    final invoice = store.state.invoiceUIState.selected;
    final client = store.state.clientState.map[invoice.clientId];

    Future<Null> _viewPdf(BuildContext context) async {
      var localization = AppLocalization.of(context);
      var url;
      var useWebView;

      if (Theme.of(context).platform == TargetPlatform.iOS) {
        url = invoice.invitationSilentLink;
        useWebView = true;
      } else {
        url = 'https://docs.google.com/viewer?url=' +  invoice.invitationDownloadLink;
        useWebView = false;
      }

      if (await canLaunch(url)) {
        await launch(url, forceSafariVC: useWebView, forceWebView: useWebView);
      } else {
        throw '${localization.anErrorOccurred}';
      }
    }

    return InvoiceViewVM(
        appState: store.state,
        isLoading: store.state.isLoading,
        isDirty: invoice.isNew(),
        invoice: invoice,
        client: client,
        onEditPressed: (BuildContext context) {
          store.dispatch(EditInvoice(invoice: invoice, context: context));
        },
        onClientPressed: (BuildContext context) {
          store.dispatch(ViewClient(client: client, context: context));
        },
        onActionSelected: (BuildContext context, EntityAction action) {
          final Completer<Null> completer = new Completer<Null>();
          var message;
          switch (action) {
            case EntityAction.pdf:
              _viewPdf(context);
              break;
            case EntityAction.email:
              store.dispatch(EmailInvoiceRequest(completer, invoice.id));
              message = AppLocalization.of(context).successfullyEmailedInvoice;
              break;
            case EntityAction.archive:
              store.dispatch(ArchiveInvoiceRequest(completer, invoice.id));
              message = AppLocalization.of(context).successfullyArchivedInvoice;
              break;
            case EntityAction.delete:
              store.dispatch(DeleteInvoiceRequest(completer, invoice.id));
              message = AppLocalization.of(context).successfullyDeletedInvoice;
              break;
            case EntityAction.restore:
              store.dispatch(RestoreInvoiceRequest(completer, invoice.id));
              message = AppLocalization.of(context).successfullyRestoredInvoice;
              break;
          }
          if (message != null) {
            return completer.future.then((_) {
              Scaffold.of(context).showSnackBar(SnackBar(
                  content: SnackBarRow(
                    message: message,
                  ),
                  duration: Duration(seconds: 3)));
            });
          }
        }
    );
  }
}
