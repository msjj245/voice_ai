import 'package:flutter/material.dart';

class EditableTextField extends StatefulWidget {
  final String initialText;
  final TextStyle? style;
  final Function(String)? onChanged;
  final int? maxLines;
  final String? hintText;
  
  const EditableTextField({
    super.key,
    required this.initialText,
    this.style,
    this.onChanged,
    this.maxLines,
    this.hintText,
  });

  @override
  State<EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<EditableTextField> {
  late TextEditingController _controller;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return TextField(
        controller: _controller,
        style: widget.style,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          hintText: widget.hintText,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                  widget.onChanged?.call(_controller.text);
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _controller.text = widget.initialText;
                  });
                },
              ),
            ],
          ),
        ),
        autofocus: true,
      );
    }
    
    return InkWell(
      onTap: () {
        setState(() {
          _isEditing = true;
        });
      },
      child: Row(
        children: [
          Expanded(
            child: Text(
              _controller.text.isEmpty ? widget.hintText ?? '' : _controller.text,
              style: widget.style?.copyWith(
                color: _controller.text.isEmpty ? Colors.grey : null,
              ),
              maxLines: widget.maxLines,
            ),
          ),
          const Icon(Icons.edit, size: 16),
        ],
      ),
    );
  }
}