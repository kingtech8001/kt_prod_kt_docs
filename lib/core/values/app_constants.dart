class AppConstants {
  AppConstants._();

  // App Metadata
  static const String appName = 'KT Vault';
  static const String appTagline = 'King Technology Document & Asset Vault';
  static const String appVersion = '1.0.0';

  // Supabase Configuration
  static const String supabaseUrl = 'https://cackyudszvdmwrnpbhlx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhY2t5dWRzenZkbXdybnBiaGx4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc0MTk5NzUsImV4cCI6MjEwMjk5NTk3NX0.45Z49-uGGjGi1eM4NfLK-ByUA1xrduQ2D4j1GH2u-O0';
  static const String storageBucket = 'documents';
  static const String webBaseUrl = 'https://kt-vault.kingtechnology.com';

  // Supported Major Cities for Filtering
  static const List<String> supportedCities = [
    'All Cities',
    'Ahmedabad',
    'Surat',
    'Vadodara',
    'Rajkot',
    'Gandhinagar',
    'Bhavnagar',
    'Jamnagar',
    'Mumbai',
    'Pune',
    'Delhi NCR',
    'Bengaluru',
    'Hyderabad',
  ];

  // Utility Bill Subcategories
  static const List<String> utilitySubcategories = [
    'Light / Electricity Bill',
    'Gas Bill (PNG / Piped)',
    'Gas Cylinder (LPG)',
    'Water & Drainage Bill',
    'Internet / Broadband Bill',
    'Property Tax / House Tax',
    'Rent / Lease Receipt',
    'Landline / Phone Bill',
  ];

  // Appliance & Asset Subcategories
  static const List<String> applianceSubcategories = [
    'Fan Bill',
    'Washing Machine Bill',
    'Geyser / Water Heater Bill',
    'Air Conditioner (AC) Bill',
    'Refrigerator Bill',
    'Television (TV) Bill',
    'Microwave / Kitchen Appliance',
    'Laptop / Computer Bill',
    'Printer / Office Equipment',
    'CCTV / Security System',
    'Furniture / Fixture',
  ];

  // Popular Appliance Brands
  static const List<String> popularBrands = [
    'Samsung',
    'LG',
    'Havells',
    'Bajaj',
    'Crompton',
    'Daikin',
    'Voltas',
    'Blue Star',
    'Whirlpool',
    'IFB',
    'AO Smith',
    'Racold',
    'Orient',
    'Usha',
    'Dell',
    'HP',
    'Apple',
    'Lenovo',
    'Sony',
    'Philips',
  ];

  // Document Categories
  static const String catUtilityBills = 'utility_bills';
  static const String catApplianceWarranty = 'appliance_warranty';
  static const String catLegalDocs = 'legal_docs';
  static const String catFinancial = 'financial';
  static const String catIdentityDocs = 'identity_docs';

  // Responsive Breakpoints
  static const double desktopBreakpoint = 1100.0;
  static const double tabletBreakpoint = 768.0;

  // Max Upload File Size: 50 MB
  static const int maxFileSize = 50 * 1024 * 1024;
}
