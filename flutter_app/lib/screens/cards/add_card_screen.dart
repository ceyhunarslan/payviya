import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payviya_app/core/theme/app_theme.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({Key? key}) : super(key: key);

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  
  Color _cardColor = const Color(0xFF1E88E5);
  String _cardType = 'Unknown';
  bool _isDefault = false;
  bool _isLoading = false;
  
  // Card color options
  final List<Color> _colorOptions = [
    const Color(0xFF1E88E5), // Blue
    const Color(0xFF43A047), // Green
    const Color(0xFFE53935), // Red
    const Color(0xFF5E35B1), // Purple
    const Color(0xFFFF9800), // Orange
    const Color(0xFF607D8B), // Blue Grey
  ];
  
  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
  
  // Credit card detection based on first digits
  void _detectCardType(String cardNumber) {
    String cleanNumber = cardNumber.replaceAll(RegExp(r'\s+\b|\b\s'), '');
    
    setState(() {
      if (cleanNumber.isEmpty) {
        _cardType = 'Unknown';
      } else if (cleanNumber.startsWith('4')) {
        _cardType = 'Visa';
      } else if (cleanNumber.startsWith(RegExp(r'5[1-5]'))) {
        _cardType = 'Mastercard';
      } else if (cleanNumber.startsWith('9792')) {
        _cardType = 'Troy';
      } else if (cleanNumber.startsWith(RegExp(r'3[47]'))) {
        _cardType = 'Amex';
      } else {
        _cardType = 'Unknown';
      }
    });
  }
  
  String _formatCardNumber(String input) {
    if (input.length <= 19) {
      // Remove all non-digit characters
      String digitsOnly = input.replaceAll(RegExp(r'\D'), '');
      
      // Format with spaces after every 4 digits
      String formatted = '';
      for (int i = 0; i < digitsOnly.length; i += 4) {
        if (i + 4 < digitsOnly.length) {
          formatted += '${digitsOnly.substring(i, i + 4)} ';
        } else {
          formatted += digitsOnly.substring(i);
        }
      }
      
      return formatted.trim();
    }
    return input;
  }
  
  String _formatExpiryDate(String input) {
    if (input.length <= 5) {
      // Remove all non-digit characters
      String digitsOnly = input.replaceAll(RegExp(r'\D'), '');
      
      // Format as MM/YY
      if (digitsOnly.length >= 2) {
        return '${digitsOnly.substring(0, 2)}/${digitsOnly.substring(2)}';
      } else {
        return digitsOnly;
      }
    }
    return input;
  }
  
  Future<void> _saveCard() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Return to previous screen
      Navigator.of(context).pop(true);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yeni Kart Ekle',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card preview
              _buildCardPreview(),
              const SizedBox(height: 24),
              
              // Card form
              _buildCardForm(),
              const SizedBox(height: 24),
              
              // Card color options
              _buildColorOptions(),
              const SizedBox(height: 24),
              
              // Make default card option
              _buildDefaultCardOption(),
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kartı Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              // Scan card button
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // Open card scanner
                  },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Kartı Tara'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCardPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _cardColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Card background decorations
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Card content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bank name placeholder & card type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'BANKA',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _cardType,
                        style: TextStyle(
                          color: _cardColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Card number
                Text(
                  _cardNumberController.text.isEmpty 
                      ? '**** **** **** ****' 
                      : _cardNumberController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                // Cardholder and expiry
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cardholder
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KART SAHİBİ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _cardHolderController.text.isEmpty 
                              ? 'AD SOYAD' 
                              : _cardHolderController.text.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    // Expiry date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SON KULLANIM',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _expiryDateController.text.isEmpty 
                              ? 'MM/YY' 
                              : _expiryDateController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCardForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card number field
          const Text(
            'Kart Numarası',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              hintText: '1234 5678 9012 3456',
              prefixIcon: Icon(Icons.credit_card),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            onChanged: (value) {
              setState(() {
                _cardNumberController.text = _formatCardNumber(value);
                _cardNumberController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _cardNumberController.text.length),
                );
                _detectCardType(_cardNumberController.text);
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kart numarası gerekli';
              }
              if (value.replaceAll(' ', '').length < 16) {
                return 'Geçerli bir kart numarası girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Card holder field
          const Text(
            'Kart Sahibi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cardHolderController,
            decoration: const InputDecoration(
              hintText: 'Ad Soyad',
              prefixIcon: Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.words,
            keyboardType: TextInputType.name,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kart sahibi adı gerekli';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          
          // Expiry date and CVV
          Row(
            children: [
              // Expiry date field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Son Kullanım Tarihi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(
                        hintText: 'MM/YY',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _expiryDateController.text = _formatExpiryDate(value);
                          _expiryDateController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _expiryDateController.text.length),
                          );
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Son kullanım tarihi gerekli';
                        }
                        
                        // Check if format is correct
                        if (!RegExp(r'^\d\d/\d\d$').hasMatch(value)) {
                          return 'MM/YY formatında girin';
                        }
                        
                        // Parse month and year
                        int month = int.parse(value.split('/')[0]);
                        int year = int.parse(value.split('/')[1]) + 2000;
                        
                        // Check if date is valid
                        if (month < 1 || month > 12) {
                          return 'Geçerli bir ay girin';
                        }
                        
                        // Check if card is not expired
                        final now = DateTime.now();
                        final cardDate = DateTime(year, month);
                        if (cardDate.isBefore(now)) {
                          return 'Kartınız süresi dolmuş';
                        }
                        
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // CVV field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CVV',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(
                        hintText: '123',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'CVV gerekli';
                        }
                        if (value.length < 3) {
                          return 'Geçerli bir CVV girin';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildColorOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kart Rengi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _colorOptions.map((color) {
            final bool isSelected = _cardColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _cardColor = color;
                });
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildDefaultCardOption() {
    return Row(
      children: [
        Checkbox(
          value: _isDefault,
          activeColor: AppTheme.primaryColor,
          onChanged: (value) {
            setState(() {
              _isDefault = value ?? false;
            });
          },
        ),
        const SizedBox(width: 8),
        const Text(
          'Varsayılan ödeme yöntemi olarak ayarla',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
} 