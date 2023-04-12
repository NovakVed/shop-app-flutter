import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/orders.dart' show Orders;
import '../widgets/app_drawer.dart';
import '../widgets/order_item.dart';

class OrdersScreen extends StatelessWidget {
  static const routeName = '/orders';

  Future<void> _refreshOrders(BuildContext context) async {
    await Provider.of<Orders>(context, listen: false).fetchAndSetOrders();
  }

  @override
  Widget build(BuildContext context) {
    // final orderData = Provider.of<Orders>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Orders'),
      ),
      drawer: AppDrawer(),
      body: RefreshIndicator(
        child: FutureBuilder(
            future:
                Provider.of<Orders>(context, listen: false).fetchAndSetOrders(),
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.error != null) {
                  // Do some error handling
                  return Center(
                    child: Text('An error occured!'),
                  );
                } else {
                  return Consumer<Orders>(
                    builder: (_, orderData, _2) {
                      return ListView.builder(
                        itemCount: orderData.orders.length,
                        itemBuilder: (_, index) => OrderItem(
                          orderData.orders[index],
                        ),
                      );
                    },
                  );
                }
              }
            }),
        onRefresh: () => _refreshOrders(context),
      ),
    );
  }
}
