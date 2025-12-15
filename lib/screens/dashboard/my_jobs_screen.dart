import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/models/job_model.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:fixify_admin/screens/dashboard/job_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';

class MyJobsScreen extends ConsumerStatefulWidget {
  const MyJobsScreen({super.key});

  @override
  ConsumerState<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends ConsumerState<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _selectedFilter = 'All Jobs';
  int _selectedTabIndex = 0;
  bool _isLoading = false;
  List<JobModel> _jobs = [];
  Map<String, dynamic> getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case "upcoming":
        return {
          "label": "Upcoming",
          "bg": Color(0xffF2F6FB),
          "text": Color(0xFF214370),
          "border": Color(0xFFC2DAF0),
        };

      case "ongoing":
        return {
          "label": "Ongoing",
          "bg": Color(0xffFBF6F2),
          "text": Color(0xFF704B21),
          "border": Color(0xFFF0E4C2),
        };

      case "past":
        return {
          "label": "Past",
          "bg": Color(0xffF2FBF2),
          "text": Color(0xFF257021),
          "border": Color(0xFFC2F0C7),
        };

      case "cancelled":
        return {
          "label": "Cancelled",
          "bg": Color(0xffF5F5F5),
          "text": Color(0xFF434343),
          "border": Color(0xFFDFDFDF),
        };

      default:
        return {
          "label": "Unknown",
          "bg": Color(0xffF5F5F5),
          "text": Color(0xFF434343),
          "border": Color(0xFFDFDFDF),
        };
    }
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.getAllJobs();

      result.fold(
        (failure) {
          if (!mounted) return;

          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (data) {
          if (!mounted) return;

          final list = data['data'] as List;
          _jobs = list.map((e) => JobModel.fromJson(e)).toList();

          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJobs();
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
    final jobs =
        _jobs.where((j) {
          if (isNewJob) {
            return j.workStatus.toLowerCase() == "upcoming";
          } else {
            return j.workStatus.toLowerCase() == "assigned";
          }
        }).toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _loadJobs(),
              icon: const Icon(Icons.refresh),
              label: Text(_isLoading ? 'Refreshing...' : 'Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (_, index) {
        final job = jobs[index];

        return _buildJobCard(job);
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

  Widget _buildJobCard(JobModel job) {
    final status = getStatusStyle(job.workStatus);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 300),
            child: JobDetailsScreen(
              token: job.token, // pass only token
              isNewJob: true,
            ),
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
              color: Colors.black.withOpacity(0.08),
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
                    job.username,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Service Requested",
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xff4B5563),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job.address,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xff4B5563),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status["bg"],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: status["border"],
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '${status["label"]}: ${job.dateTime}',
                          style: TextStyle(
                            fontSize: 13,
                            color: status["text"],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        job.price == null ? '₹--' : '₹${job.price}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
