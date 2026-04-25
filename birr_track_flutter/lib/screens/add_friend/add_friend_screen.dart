import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_provider.dart';
import '../../data/models/transaction.dart';
import '../../core/colors.dart';

class AddFriendScreen extends StatefulWidget {
  final String? friendId;

  const AddFriendScreen({super.key, this.friendId});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  String? _photoUri;
  bool _isEditing = false;
  bool _saving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.friendId != null) {
        final provider = context.read<AppProvider>();
        final matched = provider.friends.where((f) => f.id == widget.friendId).toList();
        if (matched.isNotEmpty) {
          final f = matched.first;
          setState(() {
            _isEditing = true;
            _nameController.text = f.name;
            _phoneController.text = f.phone ?? '';
            _noteController.text = f.note ?? '';
            _photoUri = f.photoUri;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handlePickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _photoUri = image.path;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<AppProvider>();

    try {
      final friendId = _isEditing ? widget.friendId! : provider.generateId();
      final friend = Friend(
        id: friendId,
        name: name,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        photoUri: _photoUri,
        createdAt: DateTime.now().toIso8601String(),
      );

      if (_isEditing) {
        await provider.updateFriend(friend);
        context.pop();
      } else {
        await provider.addFriend(friend);
        // Replace current screen with the detail page of the new friend
        context.replace('/friend-detail/$friendId');
      }
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSave = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.text),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    _isEditing ? 'Edit Friend' : 'Add Friend',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppColors.primary),
                    onPressed: canSave && !_saving ? _handleSave : null,
                  ),
                ],
              ),
            ),

            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar picker
                    Center(
                      child: GestureDetector(
                        onTap: _handlePickPhoto,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                if (_photoUri != null && _photoUri!.isNotEmpty)
                                  CircleAvatar(
                                    radius: 44,
                                    backgroundImage: FileImage(File(_photoUri!)),
                                  )
                                else
                                  CircleAvatar(
                                    radius: 44,
                                    backgroundColor: AppColors.primary.withOpacity(0.12),
                                    child: Text(
                                      _nameController.text.isNotEmpty
                                          ? _nameController.text[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.primary,
                                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to add photo',
                              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name Field
                    const Text(
                      'Name *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: 'Friend\'s name'),
                      autofocus: !_isEditing,
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    // Phone Field
                    const Text(
                      'Phone (optional)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: '+251 9XX XXX XXXX'),
                    ),
                    const SizedBox(height: 20),

                    // Note Field
                    const Text(
                      'Note (optional)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'e.g. Roommate, Colleague'),
                    ),

                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canSave && !_saving ? _handleSave : null,
                        child: Text(_saving ? 'Saving...' : (_isEditing ? 'Update Friend' : 'Add Friend')),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
