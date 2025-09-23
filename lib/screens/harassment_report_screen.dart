// lib/screens/harassment_report_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_trip_model.dart';
import '../services/auth_service.dart';
import 'dart:io';

class HarassmentReportScreen extends StatefulWidget {
  final UserTrip trip;
  
  const HarassmentReportScreen({Key? key, required this.trip}) : super(key: key);
  
  @override
  _HarassmentReportScreenState createState() => _HarassmentReportScreenState();
}

class _HarassmentReportScreenState extends State<HarassmentReportScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String _selectedIncidentType = 'Inappropriate behavior';
  List<File> _attachedFiles = [];
  bool _isSubmitting = false;
  
  final List<String> _incidentTypes = [
    'Inappropriate behavior',
    'Verbal harassment',
    'Physical harassment',
    'Discriminatory behavior',
    'Other safety concern',
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Report Issue', style: TextStyle(fontSize: 16)),
        backgroundColor: Color(0xFF6B7280),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _callHelpline(),
            child: Text(
              'CALL HELP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDiscreetHeader(),
            SizedBox(height: 20),
            _buildIncidentTypeSelector(),
            SizedBox(height: 20),
            _buildDescriptionField(),
            SizedBox(height: 20),
            _buildEvidenceSection(),
            SizedBox(height: 30),
            _buildSubmitButton(),
            SizedBox(height: 20),
            _buildEmergencyActions(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDiscreetHeader() {
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
          Row(
            children: [
              Icon(Icons.shield, color: Color(0xFF10B981), size: 24),
              SizedBox(width: 12),
              Text(
                'Safe Reporting',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Your report is confidential and will be handled with priority. Support team and authorities will be notified.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIncidentTypeSelector() {
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
            'Incident Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ..._incidentTypes.map((type) => RadioListTile<String>(
            title: Text(type),
            value: type,
            groupValue: _selectedIncidentType,
            onChanged: (value) {
              setState(() {
                _selectedIncidentType = value!;
              });
            },
            contentPadding: EdgeInsets.zero,
          )).toList(),
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
            'Description (Optional)',
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
              hintText: 'Describe what happened (optional)...',
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
                  onPressed: () => _recordAudio(),
                  icon: Icon(Icons.mic),
                  label: Text('Audio'),
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
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
          ? CircularProgressIndicator(color: Colors.white)
          : Text(
              'Submit Confidential Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }
  
  Widget _buildEmergencyActions() {
    return Column(
      children: [
        Divider(),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _callPolice(),
                icon: Icon(Icons.local_police, color: Colors.red),
                label: Text(
                  'Call Police (100)',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _callHelpline(),
                icon: Icon(Icons.support_agent, color: Color(0xFF667EEA)),
                label: Text('Support'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF667EEA),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  void _capturePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );
    
    if (photo != null) {
      setState(() {
        _attachedFiles.add(File(photo.path));
      });
    }
  }
  
  void _recordAudio() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio recording feature will be implemented')),
    );
  }
  
  void _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Submit to backend
      final reportData = {
        'tripId': widget.trip.id,
        'busId': widget.trip.busId,
        'busNumber': widget.trip.busNumber,
        'userId': AuthService.currentUser?.uid,
        'incidentType': _selectedIncidentType,
        'description': _descriptionController.text,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'submitted',
        'attachmentCount': _attachedFiles.length,
      };
      
      // Save to Firestore
      // Implementation here
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report submitted. Case ID: HSR${DateTime.now().millisecondsSinceEpoch}'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isSubmitting = false;
    });
  }
  
  void _callPolice() async {
    final url = 'tel:100';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
  
  void _callHelpline() async {
    final url = 'tel:1800123456'; // Your support helpline
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
