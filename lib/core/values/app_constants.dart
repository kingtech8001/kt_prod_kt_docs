class AppConstants {
  AppConstants._();

  // App Metadata
  static const String appName = 'DocHolder';
  static const String appTagline = 'King Technology Document Holder & Vault';
  static const String appVersion = '1.0.1';

  // Supabase Configuration
  static const String supabaseUrl = 'https://db.docholder.kingtechnology.in';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjA5NDU5MjAwLCJleHAiOjMzMjYwOTc2MDAwfQ.OBb1rjgP0-MKYhcpGdS0ahbyZaDR_B9jTQPI6nXLKhg';
  static const String storageBucket = 'documents';
  static const String webBaseUrl = 'https://kt-vault.kingtechnology.com';


  // King Technology Media Engine API Configuration
  static const String apiEngineBaseUrl = 'https://apiengine.kingtechnology.in';
  static const String apiEngineImageCompressEndpoint = '/api/image/compress';
  static const String apiEnginePdfCompressEndpoint = '/api/pdf/compress';

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
    'Other',
  ];

  // Vehicle Pass Types (Annual / Monthly / Parking)
  static const List<String> vehiclePassTypes = [
    'Annual Toll Pass',
    'Monthly Toll Pass',
    'Annual Parking Pass',
    'Society / Campus Parking Permit',
    'Expressway / Highway Pass',
    'Commercial / Municipal Entry Pass',
    'Other Pass',
  ];

  // Vehicle Service Maintenance Types
  static const List<String> vehicleServiceTypes = [
    'Engine Oil Change',
    'Oil Filter Replacement',
    'Periodic / General Service',
    'Air Filter Replacement',
    'Cabin / AC Filter',
    'Brake Pads & Disc Service',
    'Tyre Rotation & Balancing',
    'Wheel Alignment',
    'Battery Health Check / Replace',
    'Coolant Flush / Top-Up',
    'Brake Fluid Service',
    'Transmission / Gearbox Oil',
    'Spark Plugs Replacement',
    'Wiper Blades Replacement',
    'AC Gas & Cooling Service',
    'Suspension & Shock Absorber',
    'Washing & Detailing',
    'Other Repairs',
  ];

  // Document Categories
  static const String catUtilityBills = 'utility_bills';
  static const String catApplianceWarranty = 'appliance_warranty';
  static const String catLegalDocs = 'legal_docs';
  static const String catFinancial = 'financial';
  static const String catIdentityDocs = 'identity_docs';
  static const String catVehicleDocs = 'vehicle_docs';

  // Responsive Breakpoints (AI Master Context: Desktop > 1024px, Tablet 768-1024px, Mobile < 768px)
  static const double desktopBreakpoint = 1024.0;
  static const double tabletBreakpoint = 768.0;

  // Snackbar Sizing & Tokens
  static const double compactSnackbarMaxWidth = 400.0;
  static const double mobileSnackbarMargin = 16.0;

  // Layout Spacing & Geometry Tokens
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 20.0;
  static const double paddingExtraLarge = 24.0;
  static const double paddingHero = 32.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Max Upload File Size: 50 MB
  static const int maxFileSize = 50 * 1024 * 1024;
}
