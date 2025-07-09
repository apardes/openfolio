// lib/core/utils/comma_text_input_formatter.dart

import 'package:flutter/services.dart';

class CommaTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all commas and non-numeric characters except decimal point
    String newText = newValue.text.replaceAll(',', '');
    
    // If empty, return as is
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Check if it's a valid number format
    final regex = RegExp(r'^\d*\.?\d*$');
    if (!regex.hasMatch(newText)) {
      return oldValue;
    }
    
    // Split by decimal point
    final parts = newText.split('.');
    
    // Format the integer part with commas
    String integerPart = parts[0];
    String formattedInteger = '';
    
    // Add commas from right to left
    int digitCount = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (digitCount == 3) {
        formattedInteger = ',' + formattedInteger;
        digitCount = 0;
      }
      formattedInteger = integerPart[i] + formattedInteger;
      digitCount++;
    }
    
    // Reconstruct the number
    String formattedText = formattedInteger;
    if (parts.length > 1) {
      formattedText += '.${parts[1]}';
    }
    
    // Calculate new cursor position
    int oldCursorPosition = oldValue.selection.baseOffset;
    int newCursorPosition = newValue.selection.baseOffset;
    
    // Count commas before cursor in old text (safely)
    int oldCommasBeforeCursor = 0;
    if (oldCursorPosition > 0 && oldCursorPosition <= oldValue.text.length) {
      oldCommasBeforeCursor = oldValue.text.substring(0, oldCursorPosition).split(',').length - 1;
    }
    
    // Find the position in the unformatted new text
    String unformattedNewText = newValue.text.replaceAll(',', '');
    int unformattedCursorPos = newCursorPosition;
    
    // If we're deleting, adjust for removed commas
    if (newValue.text.length < oldValue.text.length) {
      int commasRemoved = oldValue.text.split(',').length - newValue.text.split(',').length;
      unformattedCursorPos = newCursorPosition - commasRemoved;
      unformattedCursorPos = unformattedCursorPos.clamp(0, unformattedNewText.length);
    }
    
    // Now calculate where the cursor should be in the newly formatted text
    int finalCursorPosition = 0;
    int digitsCount = 0;
    
    for (int i = 0; i < formattedText.length && digitsCount < unformattedCursorPos; i++) {
      finalCursorPosition++;
      if (formattedText[i] != ',') {
        digitsCount++;
      }
    }
    
    // Ensure cursor position is within valid range
    finalCursorPosition = finalCursorPosition.clamp(0, formattedText.length);
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: finalCursorPosition),
    );
  }
  
  static double? parseValue(String text) {
    // Remove commas and parse
    final cleanText = text.replaceAll(',', '');
    return double.tryParse(cleanText);
  }
}