import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:patient_app/models/schedule.dart';
import 'package:patient_app/utils/constants.dart';

class ScheduleCard extends StatelessWidget {
  final List<Schedule> schedules;
  final Size size;

  const ScheduleCard({
    super.key,
    required this.schedules,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: size.height * 0.28,
          child: FlutterCarousel(
            options: CarouselOptions(
              height: size.height * 0.28,
              viewportFraction: 0.93,
              enlargeCenterPage: true,
              autoPlay: schedules.length > 1,
              autoPlayInterval: const Duration(seconds: 4),
              showIndicator: true,
              indicatorMargin: 10,
            ),
            items: schedules.map((schedule) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.symmetric(horizontal: size.width * 0.01),
                    padding: EdgeInsets.all(size.width * 0.04),
                    decoration: AppStyles.cardDecoration,
                    child: Column(
                      children: [
                        _buildDoctorInfo(schedule),
                        SizedBox(height: size.height * 0.02),
                        _buildScheduleInfo(schedule),
                        SizedBox(height: size.height * 0.02),
                        _buildActionButtons(),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorInfo(Schedule schedule) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: AssetImage(schedule.avatar),
          radius: size.width * 0.08,
        ),
        SizedBox(width: size.width * 0.04),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.doctor,
              style: TextStyle(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              schedule.address,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: size.width * 0.035,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleInfo(Schedule schedule) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(
              vertical: size.height * 0.01,
              horizontal: size.width * 0.04,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(Icons.calendar_today, schedule.dayTime),
                _buildInfoItem(
                  Icons.access_time,
                  "${schedule.startTime} - ${schedule.endTime}",
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primaryColor,
          ),
          SizedBox(width: size.width * 0.01),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: size.width * 0.03,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: FittedBox(
                child: Text(
                  AppStrings.reschedule,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: size.width * 0.035,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: FittedBox(
                child: Text(
                  AppStrings.joinSession,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: size.width * 0.035,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
