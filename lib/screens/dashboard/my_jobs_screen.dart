import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/screens/dashboard/job_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _selectedFilter = 'All Jobs';
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_selectedTabIndex != _tabController.index) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'My Jobs'),
      backgroundColor: const Color(0xFFF5F7F8),
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPillTab(title: 'New Job Request', index: 0),
                    _buildPillTab(title: 'Assigned Job', index: 1),
                  ],
                ),
              ),
            ),
          ),

          // Filter Dropdown
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedFilter,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Job List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJobList(isNewJob: true),
                _buildJobList(isNewJob: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobList({required bool isNewJob}) {
    // Sample job data
    final jobs = [
      {
        'clientName': 'Paula Lewis',
        'jobType': 'House Cleaning',
        'serviceType': 'fixed', // 'fixed' or 'hourly'
        'location': 'Sector 43, Gurgaon, Haryana, India',
        'date': '12 Oct 2025, 4:30 PM',
        'price': '₹199',
        'status': isNewJob ? 'Upcoming' : 'Assigned',
        'statusColor': isNewJob ? Colors.blue.shade100 : Colors.green.shade100,
        'statusTextColor':
            isNewJob ? Colors.blue.shade700 : Colors.green.shade700,
      },
      {
        'clientName': 'Paula Lewis',
        'jobType': 'Hourly Cleaning Service',
        'serviceType': 'hourly', // 'fixed' or 'hourly'
        'location': 'Sector 43, Gurgaon, Haryana, India',
        'date': '12 Oct 2025, 4:30 PM',
        'price': '₹199',
        'status': 'Upcoming',
        'statusColor': Colors.orange.shade100,
        'statusTextColor': Colors.orange.shade700,
      },
    ];

    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              isNewJob ? 'No new job requests' : 'No assigned jobs',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _buildJobCard(job, isNewJob);
      },
    );
  }

  Widget _buildPillTab({required String title, required int index}) {
    final bool isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        setState(() => _selectedTabIndex = index);
      },
      child: AnimatedContainer(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primary.withOpacity(0.4)
                    : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, bool isNewJob) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 300),
            child: JobDetailsScreen(job: job, isNewJob: isNewJob),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['clientName'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job['jobType'],
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job['location'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: job['statusColor'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${job['status']}: ${job['date']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: job['statusTextColor'],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  job['price'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
