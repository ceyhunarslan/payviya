import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/utils/logo_helper.dart';

enum CampaignTemplateStyle {
  card,    // Compact card for lists
  detail,  // Detailed view for focused display
  grid,    // Grid item for dashboard
  list,    // List item for vertical lists
  homeCard, // Compact card specifically for home screen
  discover, // Campaign discovery screen style
}

class CampaignTemplate extends StatelessWidget {
  final Campaign campaign;
  final CampaignTemplateStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData? actionIcon;
  final double? width;
  final double? height;
  final bool showSource;
  final bool showDetails;

  const CampaignTemplate({
    Key? key,
    required this.campaign,
    this.style = CampaignTemplateStyle.card,
    this.onTap,
    this.onAction,
    this.actionLabel,
    this.actionIcon,
    this.width,
    this.height,
    this.showSource = false,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case CampaignTemplateStyle.detail:
        return _buildDetailView();
      case CampaignTemplateStyle.grid:
        return _buildGridItem();
      case CampaignTemplateStyle.list:
        return _buildListItem();
      case CampaignTemplateStyle.homeCard:
        return _buildHomeCardView();
      case CampaignTemplateStyle.discover:
        return _buildDiscoverView();
      case CampaignTemplateStyle.card:
      default:
        return _buildCardView();
    }
  }

  // Build a compact card view for horizontal scrolling lists
  Widget _buildCardView() {
    final bankName = campaign.bank?.name ?? 'Unknown Bank';
    final cardName = campaign.creditCard?.name ?? 'Unknown Card';
    final category = campaign.categoryName ?? campaign.category;
    final discount = campaign.formattedDiscount;
    final expiry = campaign.timeRemaining;
    final bankColor = _getBankColor(bankName);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = width ?? constraints.maxWidth;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: maxWidth.isFinite ? maxWidth : 280,
            height: height ?? 235,
            margin: const EdgeInsets.only(right: 12, bottom: 8),
            constraints: BoxConstraints(
              maxWidth: maxWidth.isFinite ? maxWidth : 280,
              minWidth: 280,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top section with banner, logo, and discount badge
                SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Banner background
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: bankColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      
                      // Logo container
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.1),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LogoHelper.getCardLogoWidget(
                              cardName,
                              campaign.creditCard?.logoUrl,
                              size: 65,
                            ),
                          ),
                        ),
                      ),
                      
                      // Discount badge
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            discount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Bank and card info
                        Text(
                          '$bankName · $cardName',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Campaign details
                        if (showDetails) ...[
                          Flexible(
                            child: Text(
                              campaign.name,
                              style: const TextStyle(
                                color: Color(0xFF212121),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              campaign.trimmedDescription,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                
                // Footer
                Container(
                  height: 40,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFFEEEEEE),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            color: bankColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          expiry,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build a detailed view with more information
  Widget _buildDetailView() {
    final bankName = campaign.bank?.name ?? 'Banka';
    final cardName = campaign.creditCard?.name ?? 'Kart';
    final merchant = campaign.merchant?.name;
    final category = campaign.categoryName ?? campaign.category;
    final discount = campaign.formattedDiscount;
    final expiry = campaign.timeRemaining;
    final bankColor = _getBankColor(bankName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with label
          if (actionLabel != null || actionIcon != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          actionIcon ?? Icons.local_offer_rounded,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          actionLabel ?? "Kampanya",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (onAction != null)
                    IconButton(
                      icon: Icon(
                        actionIcon ?? Icons.refresh_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: onAction,
                    ),
                ],
              ),
            ),

          // Main card content - clickable
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bank and card info section
                  Row(
                    children: [
                      // Bank logo/avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: bankColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: bankColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: LogoHelper.getCardLogoWidget(
                            cardName,
                            campaign.creditCard?.logoUrl,
                            size: 60,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Bank and card info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bankName,
                              style: const TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cardName,
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Discount badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: bankColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: bankColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          discount,
                          style: TextStyle(
                            color: bankColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (showDetails) ...[
                    const SizedBox(height: 20),

                    // Campaign details
                    Text(
                      campaign.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      campaign.trimmedDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 16),

                    // Campaign metadata
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(
                          Icons.category_rounded,
                          category,
                          AppTheme.primaryColor,
                        ),
                        if (merchant != null) 
                          _buildInfoChip(
                            Icons.storefront_rounded,
                            merchant,
                            Colors.purple,
                          ),
                        _buildInfoChip(
                          Icons.timer_outlined,
                          expiry,
                          Colors.orange,
                        ),
                        if (campaign.requiresEnrollment)
                          _buildInfoChip(
                            Icons.app_registration_rounded,
                            'Kayıt Gerekli',
                            Colors.red,
                          ),
                      ],
                    ),

                    if ((campaign.minAmount ?? 0) > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Min. Harcama: ${(campaign.minAmount ?? 0).toStringAsFixed(0)} TL',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          if (campaign.maxDiscount != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              'Max. İndirim: ${campaign.maxDiscount!.toStringAsFixed(0)} TL',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Source info
          if (showSource)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.source_rounded,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kaynak: ${_formatSource(campaign.source)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Eklenme: ${_formatDate(campaign.createdAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Build a grid item for dashboard grids
  Widget _buildGridItem() {
    final bankName = campaign.bank?.name ?? 'Banka';
    final cardName = campaign.creditCard?.name ?? 'Kart';
    final discount = campaign.formattedDiscount;
    final category = campaign.categoryName ?? campaign.category;
    final bankColor = _getBankColor(bankName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner with bank and discount
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bankColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Bank logo placeholder
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LogoHelper.getCardLogoWidget(
                        cardName,
                        campaign.creditCard?.logoUrl,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bank name
                  Expanded(
                    child: Text(
                      bankName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Discount badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      discount,
                      style: TextStyle(
                        color: bankColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Campaign info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    campaign.trimmedDescription,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    campaign.timeRemaining,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build a list item for vertical scrolling lists
  Widget _buildListItem() {
    final bankName = campaign.bank?.name ?? 'Banka';
    final cardName = campaign.creditCard?.name ?? 'Kart';
    final discount = campaign.formattedDiscount;
    final bankColor = _getBankColor(bankName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Bank logo/avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bankColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LogoHelper.getCardLogoWidget(
                    cardName,
                    campaign.creditCard?.logoUrl,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Campaign info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bankName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cardName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaign.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      campaign.trimmedDescription,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            campaign.categoryName ?? campaign.category,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          campaign.timeRemaining,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Discount badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: bankColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  discount,
                  style: TextStyle(
                    color: bankColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build a more compact card view specifically for the homepage to prevent overflow
  Widget _buildHomeCardView() {
    final bankName = campaign.bank?.name ?? 'Banka';
    final cardName = campaign.creditCard?.name ?? 'Kart';
    final category = campaign.categoryName ?? campaign.category;
    final discount = campaign.formattedDiscount;
    final expiry = campaign.timeRemaining;
    final bankColor = _getBankColor(bankName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 280,
        height: height ?? 207, // Increased height by 7 pixels (from 200 to 207)
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // Use a Column for the main layout - ensures proper constraints
        child: Column(
          children: [
            // Top section with banner, logo, and discount badge
            SizedBox(
              height: 60,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Banner background
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: bankColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  
                  // Logo container - positioned slightly lower for better appearance
                  Positioned(
                    top: 20, // Changed from 30px to 20px (10px higher)
                    left: 15,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: LogoHelper.getCardLogoWidget(
                          cardName,
                          campaign.creditCard?.logoUrl,
                          size: 45,
                        ),
                      ),
                    ),
                  ),
                  
                  // Discount badge
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        discount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Middle content area - make it expandable with Expanded and constrain properly
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 12), // Slightly adjusted padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
                  children: [
                    // Bank and card info
                    Text(
                      '$bankName · $cardName',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 3),
                    
                    // Campaign details with explicit constraints
                    if (showDetails) ...[
                      Flexible(
                        child: Text(
                          campaign.name,
                          style: const TextStyle(
                            color: Color(0xFF212121),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          campaign.trimmedDescription,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Footer - with fixed height
            Container(
              height: 30,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F9),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFEEEEEE),
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: bankColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      expiry,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the discover view style
  Widget _buildDiscoverView() {
    final bankName = campaign.bank?.name ?? 'Unknown Bank';
    final cardName = campaign.creditCard?.name ?? 'Unknown Card';
    final category = campaign.categoryName ?? campaign.category ?? 'Genel';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: width ?? double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campaign header (bank logo, name, discount)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bank logo or placeholder
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LogoHelper.getCardLogoWidget(
                            cardName,
                            campaign.creditCard?.logoUrl,
                            size: 65,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Campaign name and bank name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              campaign.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              cardName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Discount badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          campaign.formattedDiscount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Campaign description
                Text(
                  campaign.trimmedDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Campaign metadata (end date, category)
                Row(
                  children: [
                    // End date
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      campaign.timeRemaining,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Category display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatSource(CampaignSource source) {
    switch (source) {
      case CampaignSource.MANUAL:
        return 'Manuel';
      case CampaignSource.API:
        return 'API';
      case CampaignSource.AUTOMATIC:
        return 'Otomatik';
      default:
        return source.toString().split('.').last;
    }
  }

  Color _getBankColor(String bankName) {
    final Map<String, Color> bankColors = {
      'Akbank': const Color(0xFFF01C31),       // Red
      'Garanti BBVA': const Color(0xFF00854A), // Green
      'Yapı Kredi': const Color(0xFF010066),   // Dark Blue
      'İş Bankası': const Color(0xFF0A5CA8),   // Blue
      'QNB Finansbank': const Color(0xFF63166E), // Purple
      'TEB': const Color(0xFF133C8B),          // Navy Blue
      'DenizBank': const Color(0xFF008ACF),    // Light Blue
      'Ziraat Bankası': const Color(0xFFE4032E), // Red
      'Halkbank': const Color(0xFF004E9E),     // Blue
      'Vakıfbank': const Color(0xFF00705F),    // Teal
      'HSBC': const Color(0xFFDB0011),         // Red
      'ING': const Color(0xFFFF6200),          // Orange
    };
    
    return bankColors[bankName] ?? AppTheme.primaryColor; // Default if bank not found
  }
} 