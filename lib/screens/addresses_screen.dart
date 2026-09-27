import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../providers/address_provider.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddressProvider(),
      child: Consumer<AddressProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundLight,
              elevation: 0,
              title: const Text('Addresses', style: TextStyle(color: AppColors.textDark)),
              iconTheme: const IconThemeData(color: AppColors.textDark),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: provider.fetchAddresses,
                ),
              ],
            ),
            body: provider.isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
              : provider.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(provider.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGrey)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                            onPressed: provider.fetchAddresses, 
                            child: const Text('Retry', style: TextStyle(color: Colors.white))
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'The following addresses will be used on the checkout page by default.',
                          style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        _buildAddressCard(
                          context,
                          'Billing Address', 
                          provider.customer?.billing,
                          'Edit'
                        ),
                        const SizedBox(height: 16),
                        _buildAddressCard(
                          context,
                          'Shipping Address', 
                          provider.customer?.shipping,
                          'Edit'
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, String title, Address? address, String actionLabel) {
    final bool hasAddress = address != null && !address.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  // TODO: Implement Edit Address
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit address functionality coming soon'))
                  );
                },
                child: Text(actionLabel, style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasAddress)
            Text(
              address.fullAddress,
              style: const TextStyle(
                color: AppColors.textDark, 
                fontSize: 15,
                height: 1.5,
              ),
            )
          else
            const Text(
              'You have not set up this type of address yet.', 
              style: TextStyle(
                color: AppColors.textGrey, 
                fontStyle: FontStyle.italic
              )
            ),
        ],
      ),
    );
  }
}
