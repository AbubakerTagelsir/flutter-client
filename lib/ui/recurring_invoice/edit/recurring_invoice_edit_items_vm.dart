import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/redux/recurring_invoice/recurring_invoice_actions.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_items.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_items_desktop.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_items_vm.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_vm.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';

class RecurringInvoiceEditItemsScreen extends StatelessWidget {
  const RecurringInvoiceEditItemsScreen({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  final EntityEditVM viewModel;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, RecurringInvoiceEditItemsVM>(
      converter: (Store<AppState> store) {
        return RecurringInvoiceEditItemsVM.fromStore(store);
      },
      builder: (context, viewModel) {
        if (viewModel.state.prefState.isDesktop) {
          return InvoiceEditItemsDesktop(
            viewModel: viewModel,
            entityViewModel: this.viewModel,
          );
        } else {
          return InvoiceEditItems(
            viewModel: viewModel,
            entityViewModel: this.viewModel,
          );
        }
      },
    );
  }
}

class RecurringInvoiceEditItemsVM extends EntityEditItemsVM {
  RecurringInvoiceEditItemsVM({
    AppState state,
    CompanyEntity company,
    InvoiceEntity invoice,
    int invoiceItemIndex,
    Function addLineItem,
    Function deleteLineItem,
    Function(int) onRemoveInvoiceItemPressed,
    Function onDoneInvoiceItemPressed,
    Function(InvoiceItemEntity, int) onChangedInvoiceItem,
  }) : super(
          state: state,
          company: company,
          invoice: invoice,
          addLineItem: addLineItem,
          deleteLineItem: deleteLineItem,
          invoiceItemIndex: invoiceItemIndex,
          onRemoveInvoiceItemPressed: onRemoveInvoiceItemPressed,
          onDoneInvoiceItemPressed: onDoneInvoiceItemPressed,
          onChangedInvoiceItem: onChangedInvoiceItem,
        );

  factory RecurringInvoiceEditItemsVM.fromStore(Store<AppState> store) {
    return RecurringInvoiceEditItemsVM(
        state: store.state,
        company: store.state.company,
        invoice: store.state.recurringInvoiceUIState.editing,
        invoiceItemIndex: store.state.quoteUIState.editingItemIndex,
        onRemoveInvoiceItemPressed: (index) =>
            store.dispatch(DeleteRecurringInvoiceItem(index)),
        onDoneInvoiceItemPressed: () =>
            store.dispatch(EditRecurringInvoiceItem()),
        onChangedInvoiceItem: (item, index) {
          final invoice = store.state.recurringInvoiceUIState.editing;
          if (index == invoice.lineItems.length) {
            store.dispatch(AddRecurringInvoiceItem(invoiceItem: item));
          } else {
            store
                .dispatch(UpdateRecurringInvoiceItem(item: item, index: index));
          }
        });
  }
}
