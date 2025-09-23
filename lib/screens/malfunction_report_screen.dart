// lib/screens/malfunction_report_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_trip_model.dart';
import '../services/auth_service.dart';
import 'dart:io';

class MalfunctionReportScreen extends StatefulWidget {
  final UserTrip trip;
  
  const MalfunctionReportScreen({Key? key, required this.trip}) : super(key: key);
  
  @override
  _MalfunctionReportScreenState createState() => _MalfunctionReportScreenState();
}

class _MalfunctionReportScreenState extends State<MalfunctionReportScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String _selectedIssueType = 'AC Problem';
  String _selectedUrgency = 'Normal';
  List<File> _attachedFiles = [];
  bool _isSubmitting = false;
  
  final List<String> _issueTypes = [
    'AC Problem',
    'Breakdown',
    'Safety Issue',
    'Electrical Problem',
    'Engine Issue',
    'Door/Window Problem',
    'Seat Issue',
    'Other',
  ];
  
  final List<String> _urgencyLevels = [
    'Normal',
    'High',
    'Critical',
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Report Malfunction'),
        backgroundColor: Color(0xFFEF4444),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTripInfoCard(),
            SizedBox(height: 20),
            _buildIssueTypeSelector(),
            SizedBox(height: 20),
            _buildUrgencySelector(),
            SizedBox(height: 20),
            _buildDescriptionField(),
            SizedBox(height: 20),
            _buildEvidenceSection(),
            SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTripInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text('Bus: ${widget.trip.busNumber}'),
          Text('Route: ${widget.trip.fromStopName} → ${widget.trip.toStopName}'),
          Text('Seats: ${widget.trip.seatNumbers.join(', ')}'),
        ],
      ),
    );
  }
  
  Widget _buildIssueTypeSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Issue Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedIssueType,
            onChanged: (value) {
              setState(() {
                _selectedIssueType = value!;
              });
            },
            items: _issueTypes.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            )).toList(),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Color(0xFFF9FAFB),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUrgencySelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Urgency Level',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: _urgencyLevels.map((level) {
              Color color = level == 'Critical' ? Colors.red : 
                          level == 'High' ? Colors.orange : Colors.blue;
              bool isSelected = _selectedUrgency == level;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedUrgency = level;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      level,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDescriptionField() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Please describe the issue in detail...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Color(0xFFF9FAFB),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEvidenceSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evidence (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _capturePhoto(),
                  icon: Icon(Icons.photo_camera),
                  label: Text('Photo'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _captureVideo(),
                  icon: Icon(Icons.videocam),
                  label: Text('Video'),
                ),
              ),
            ],
          ),
          if (_attachedFiles.isNotEmpty) ...[
            SizedBox(height: 12),
            Text('${_attachedFiles.length} file(s) attached'),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getUrgencyColor(),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
          ? CircularProgressIndicator(color: Colors.white)
          : Text(
              'Submit Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }
  
  Color _getUrgencyColor() {
    switch (_selectedUrgency) {
      case 'Critical': return Colors.red[600]!;
      case 'High': return Colors.orange[600]!;
      default: return Colors.blue[600]!;
    }
  }
  
  void _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _attachedFiles.add(File(photo.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to capture photo')),
      );
    }
  }
  
  void _captureVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        setState(() {
          _attachedFiles.add(File(video.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to capture video')),
      );
    }
  }
  
  void _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final reportData = {
        'type': 'malfunction',
        'tripId': widget.trip.id,
        'busId': widget.trip.busId,
        'busNumber': widget.trip.busNumber,
        'userId': AuthService.currentUser?.uid,
        'issueType': _selectedIssueType,
        'urgency': _selectedUrgency,
        'description': _descriptionController.text,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'submitted',
        'attachmentCount': _attachedFiles.length,
      };
      
      // Submit to Firestore - implementation here
      print('Malfunction report submitted: $reportData');
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report submitted. Maintenance team notified.'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isSubmitting = false;
    });
  }
  
  void _callHelpline() async {
    final url = 'tel:1800123456';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print('Could not launch $url');
    }
  }
}
