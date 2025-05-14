import 'package:flutter/material.dart';
import 'package:payviya_app/models/campaign.dart';
import 'package:payviya_app/services/campaign_service.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/widgets/campaign_template.dart';

class CampaignsPage extends StatefulWidget {
  const CampaignsPage({Key? key}) : super(key: key);

  @override
  _CampaignsPageState createState() => _CampaignsPageState();
}

class _CampaignsPageState extends State<CampaignsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Campaign> _allCampaigns = [];
  List<Campaign> _personalizedCampaigns = [];
  bool _isLoadingAll = true;
  bool _isLoadingPersonalized = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllCampaigns();
    _loadPersonalizedCampaigns();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCampaigns() async {
    setState(() {
      _isLoadingAll = true;
      _error = null;
    });

    try {
      final campaigns = await ApiService.getCampaigns(limit: 20);
      setState(() {
        _allCampaigns = campaigns;
        _isLoadingAll = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load campaigns: $e';
        _isLoadingAll = false;
      });
    }
  }

  Future<void> _loadPersonalizedCampaigns() async {
    setState(() {
      _isLoadingPersonalized = true;
      _error = null;
    });

    try {
      // For personalized campaigns, we'll use recommendations
      final campaigns = await ApiService.getRecommendedCampaigns();
      setState(() {
        _personalizedCampaigns = campaigns;
        _isLoadingPersonalized = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load personalized campaigns: $e';
        _isLoadingPersonalized = false;
      });
    }
  }

  Widget _buildCampaignList(List<Campaign> campaigns, bool isLoading) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No campaigns available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new offers',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_tabController.index == 0) {
          await _loadAllCampaigns();
        } else {
          await _loadPersonalizedCampaigns();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: campaigns.length,
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: CampaignTemplate(
              campaign: campaign,
              style: CampaignTemplateStyle.card,
              width: double.infinity,
              onTap: () {
                // Handle campaign tap - navigate to detail page
                // Navigator.of(context).push(MaterialPageRoute(
                //   builder: (context) => CampaignDetailScreen(campaign: campaign),
                // ));
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All Campaigns'),
            Tab(text: 'Special for You'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Campaigns Tab
          _buildCampaignList(_allCampaigns, _isLoadingAll),
          
          // Special for You Tab
          _buildCampaignList(_personalizedCampaigns, _isLoadingPersonalized),
        ],
      ),
    );
  }
} 