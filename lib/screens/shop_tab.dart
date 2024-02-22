import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shopify_flutter/enums/src/payment_token_type.dart';
import 'package:shopify_flutter/models/src/shopify_user/address/address.dart';
import 'package:shopify_flutter/shopify_flutter.dart';

import 'checkout_page.dart';

class ShopTab extends StatefulWidget {
  const ShopTab({super.key});

  @override
  ShopTabState createState() => ShopTabState();
}

class ShopTabState extends State<ShopTab> {
  Shop? shop;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchShopInfo();
  }

  Future<void> fetchShopAdminInfo() async {
    try {
      final shopInfo = await ShopifyCustom.instance.customQuery(
        gqlQuery: """
query{
  shop {
    name
    currencyCode
    checkoutApiSupported
    taxesIncluded
    resourceLimits {
      maxProductVariants
    }
    billingAddress {
      id
      address1
      address2
      city
      company
      country
      countryCodeV2
      formattedArea
      latitude
      longitude
      phone
      province
      provinceCode
      zip
    }
  }
}
""",
        adminAccess: true,
      );
      log('shopInfo: $shopInfo');
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchShopInfo() async {
    try {
      setState(() => _isLoading = true);
      final shopInfo = await ShopifyStore.instance.getShop();
      if (mounted) {
        setState(() {
          shop = shopInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => _isLoading = false);
    }
  }

  Future<void> testCheckoutProcess() async {
    final shopifyStore = ShopifyStore.instance;
    final shopifyAuth = ShopifyAuth.instance;
    final shopifyCheckout = ShopifyCheckout.instance;

    try {
      setState(() => _isLoading = true);
      await shopifyAuth.signInWithEmailAndPassword(
        email: '****@gmail.com',
        password: '*********',
      );

      final bestSellingProducts = await shopifyStore.getAllProducts();

      var items = List<LineItem>.empty(growable: true);
      items.add(LineItem(
          quantity: 1,
          variantId: bestSellingProducts[0].productVariants[0].id,
          title: bestSellingProducts[0].title,
          id: bestSellingProducts[0].id));

      var address = Address(
        address1: '11 Hinkler Avenue',
        city: 'Sydney',
        country: 'Australia',
        countryCode: 'AU',
        firstName: 'Anderson',
        lastName: 'Fetter',
        phone: '044444444',
        zip: '2229',
      );

      Checkout checkout = await shopifyCheckout.createCheckout(
        lineItems: items,
        shippingAddress: address,
        email: '****@gmail.com',
      );
      setState(() => _isLoading = false);
      if (!mounted) return;
      final status = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WebViewCheckout(checkout: checkout),
        ),
      );
      if (status != null && status) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Checkout Success'),
            ),
          );
      }
    } on Exception catch (e) {
      log('error: $e');
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('$e')),
        );
    }
  }

  Future<void> testCheckoutCompleteWithTokenizedPaymentV3() async {
    final shopifyStore = ShopifyStore.instance;
    final shopifyAuth = ShopifyAuth.instance;
    final shopifyCheckout = ShopifyCheckout.instance;

    try {
      await shopifyAuth.signInWithEmailAndPassword(
          email: '**********', password: '**********');

      final bestSellingProducts = await shopifyStore.getAllProducts();

      var items = List<LineItem>.empty(growable: true);
      items.add(LineItem(
          quantity: 1,
          variantId: bestSellingProducts[0].productVariants[0].id,
          title: bestSellingProducts[0].title,
          id: bestSellingProducts[0].id));

      var address = Address(
        address1: '11 Hinkler Avenue',
        city: 'Sydney',
        country: 'Australia',
        countryCode: 'AU',
        firstName: 'Anderson',
        lastName: 'Fetter',
        phone: '044444444',
        zip: '2229',
      );

      Checkout checkout = await shopifyCheckout.createCheckout(
        lineItems: items,
        shippingAddress: address,
        email: '*********',
      );

      /// add line items to current checkout
      // checkout = await shopifyCheckout.addLineItemsToCheckout(
      //   lineItems: items,
      //   checkoutId: checkout.id,
      // );

      /// update line items to current checkout
      ///
      /// updates the lineitems of provided id's quantity to 2
      // checkout = await shopifyCheckout.updateLineItemsInCheckout(
      //   lineItems: [
      //     LineItem(
      //       quantity: 2,
      //       variantId: bestSellingProducts[0].productVariants[0].id,
      //       title: bestSellingProducts[0].title,
      //       id: bestSellingProducts[0].id,
      //     ),
      //   ],
      //   checkoutId: checkout.id,
      // );

      /// remove line items from current checkout
      ///
      /// removes the lineitems of provided id
      // checkout = await shopifyCheckout.removeLineItemsFromCheckout(
      //   lineItems: [
      //     LineItem(
      //       quantity: 1,
      //       variantId: bestSellingProducts[0].productVariants[0].id,
      //       title: bestSellingProducts[0].title,
      //       id: bestSellingProducts[0].id,
      //     ),
      //   ],
      //   checkoutId: checkout.id,
      // );

      final idempotencyKey = UniqueKey().toString();
      await shopifyCheckout.shippingAddressUpdate(checkout.id, address);
      var completed =
      await shopifyCheckout.checkoutCompleteWithTokenizedPaymentV3(
        checkout.id,
        checkout: checkout,
        token: r'CQ32pyIRCmIEfekpX8x=',
        paymentTokenType: PaymentTokenType.APPLE_PAY,
        idempotencyKey: idempotencyKey,
        amount: '1.00',
        currencyCode: 'AUD',
        billingAddress: address,
      );
      log('completed: $completed');
    } on Exception catch (e) {
      log('error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.payment),
          //   onPressed: testCheckoutCompleteWithTokenizedPaymentV3,
          // ),
          IconButton(
            icon: const Icon(Icons.payments_outlined),
            onPressed: testCheckoutProcess,
          ),
          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   onPressed: fetchShopAdminInfo,
          // ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  ListTile(
                    title: const Text('Name'),
                    subtitle: Text(shop?.name ?? 'N/A'),
                  ),
                  ListTile(
                    title: const Text('Description'),
                    subtitle: Text(shop?.description ?? 'N/A'),
                  ),
                  ListTile(
                    title: const Text('Money Format'),
                    subtitle: Text(shop?.moneyFormat ?? 'N/A'),
                  ),
                  ListTile(
                    title: const Text('Primary Domain'),
                    subtitle: Text(shop?.primaryDomain?.url ?? 'N/A'),
                  ),
                  ListTile(
                    title: const Text('Primary Domain SSL Enabled'),
                    subtitle:
                    Text(shop?.primaryDomain?.sslEnabled.toString() ?? ''),
                  ),
                  ListTile(
                    title: const Text('Privacy Policy'),
                    subtitle: Text(shop?.privacyPolicy?.url ?? 'N/A'),
                  ),
                  ListTile(
                    title: const Text('Refund Policy'),
                    subtitle: Text(shop?.refundPolicy?.url ?? 'N/A'),
                  ),
                  ListTile(
                    title: const Text('Shipping Policy'),
                    subtitle: Text(shop?.shippingPolicy?.url ?? 'N/A'),
                  ),
                  ListTile(
                    title: const Text('Subscription Policy'),
                    subtitle: Text(shop?.subscriptionPolicy?.url ?? 'N/A'),
                  ),
                  ListTile(
                    title: const Text('Ships to Countries'),
                    subtitle: Text(shop?.shipsToCountries?.join(', ') ?? 'N/A'),
                  ),
                  ListTile(
                    title: const Text('Terms of Service'),
                    subtitle: Text(shop?.termsOfService?.url ?? 'N/A'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}