class AppConstants {
  static const String appName = 'Hisabi';
  static const String appNameBn = 'হিসাবি';
  static const String currencySymbol = '৳';
  static const String currencyCode = 'BDT';

  static const List<Map<String, String>> bankAccounts = [
    {'name': 'Sonali Bank', 'nameBn': 'সোনালী ব্যাংক'},
    {'name': 'Dutch-Bangla Bank (DBBL)', 'nameBn': 'ডাচ-বাংলা ব্যাংক'},
    {'name': 'BRAC Bank', 'nameBn': 'ব্র্যাক ব্যাংক'},
    {'name': 'Islami Bank Bangladesh', 'nameBn': 'ইসলামী ব্যাংক বাংলাদেশ'},
    {'name': 'Eastern Bank (EBL)', 'nameBn': 'ইস্টার্ন ব্যাংক'},
    {'name': 'Mutual Trust Bank (MTB)', 'nameBn': 'মিউচুয়াল ট্রাস্ট ব্যাংক'},
    {'name': 'City Bank', 'nameBn': 'সিটি ব্যাংক'},
    {'name': 'Prime Bank', 'nameBn': 'প্রাইম ব্যাংক'},
    {'name': 'National Bank (NBL)', 'nameBn': 'ন্যাশনাল ব্যাংক'},
    {'name': 'AB Bank', 'nameBn': 'এবি ব্যাংক'},
    {'name': 'Pubali Bank', 'nameBn': 'পুবালী ব্যাংক'},
    {'name': 'Mercantile Bank', 'nameBn': 'মার্কেন্টাইল ব্যাংক'},
    {'name': 'Southeast Bank', 'nameBn': 'সাউথইস্ট ব্যাংক'},
    {'name': 'Standard Chartered BD', 'nameBn': 'স্ট্যান্ডার্ড চার্টার্ড বিডি'},
    {'name': 'Bank Asia', 'nameBn': 'ব্যাংক এশিয়া'},
    {'name': 'One Bank', 'nameBn': 'ওয়ান ব্যাংক'},
    {'name': 'IFIC Bank', 'nameBn': 'আইএফআইসি ব্যাংক'},
    {'name': 'Jamuna Bank', 'nameBn': 'যমুনা ব্যাংক'},
  ];

  static const List<Map<String, String>> mobileBanking = [
    {'name': 'bKash', 'nameBn': 'বিকাশ', 'provider': 'BRAC Bank'},
    {'name': 'Nagad', 'nameBn': 'নগদ', 'provider': 'Bangladesh Post Office'},
    {'name': 'Rocket', 'nameBn': 'রকেট', 'provider': 'DBBL'},
    {'name': 'Upay', 'nameBn': 'উপায়', 'provider': 'UCB'},
    {'name': 'MyCash', 'nameBn': 'মাইক্যাশ', 'provider': 'Mercantile Bank'},
    {'name': 'SureCash', 'nameBn': 'শিওরক্যাশ', 'provider': 'Rupali Bank'},
    {'name': 'OK Wallet', 'nameBn': 'ওকে ওয়ালেট', 'provider': 'One Bank'},
    {'name': 'Tap', 'nameBn': 'ট্যাপ', 'provider': 'IFIC Bank'},
  ];

  static const List<Map<String, String>> accountTypes = [
    {'name': 'Savings', 'nameBn': 'সঞ্চয়'},
    {'name': 'Current', 'nameBn': 'কারেন্ট'},
    {'name': 'Mudaraba Savings', 'nameBn': 'মুদারাবা সঞ্চয়'},
    {'name': 'Cash on Hand', 'nameBn': 'নগদ'},
    {'name': 'Piggy Bank', 'nameBn': 'পিগি ব্যাংক'},
    {'name': 'DPS', 'nameBn': 'ডিপিএস'},
    {'name': 'FDR', 'nameBn': 'এফডিআর'},
    {'name': 'Mobile Banking', 'nameBn': 'মোবাইল ব্যাংকিং'},
    {'name': 'Custom', 'nameBn': 'কাস্টম'},
  ];

  static const List<Map<String, String>> incomeCategories = [
    {'name': 'Salary', 'nameBn': 'চাকরির বেতন', 'icon': 'work'},
    {'name': 'Business', 'nameBn': 'ব্যবসা', 'icon': 'business'},
    {'name': 'Freelance', 'nameBn': 'ফ্রিল্যান্স', 'icon': 'laptop'},
    {'name': 'House Rent', 'nameBn': 'বাড়ি ভাড়া', 'icon': 'home'},
    {'name': 'Agriculture', 'nameBn': 'কৃষি', 'icon': 'agriculture'},
    {'name': 'Investment', 'nameBn': 'বিনিয়োগ', 'icon': 'trending_up'},
    {'name': 'Tuition', 'nameBn': 'টিউশন', 'icon': 'school'},
    {'name': 'Ride Share', 'nameBn': 'রাইড শেয়ার', 'icon': 'directions_car'},
    {'name': 'Online Business', 'nameBn': 'অনলাইন ব্যবসা', 'icon': 'store'},
    {'name': 'Gift', 'nameBn': 'উপহার', 'icon': 'card_giftcard'},
    {'name': 'Loan Received', 'nameBn': 'ধার পেয়েছি', 'icon': 'account_balance'},
    {'name': 'Bank Interest', 'nameBn': 'ব্যাংক সুদ', 'icon': 'monetization_on'},
    {'name': 'Product Sales', 'nameBn': 'পণ্য বিক্রয়', 'icon': 'inventory'},
    {'name': 'Professional Fees', 'nameBn': 'পেশাগত ফি', 'icon': 'medical_services'},
    {'name': 'Other Income', 'nameBn': 'অন্যান্য', 'icon': 'add_circle'},
  ];

  static const List<Map<String, String>> expenseCategories = [
    {'name': 'Food & Groceries', 'nameBn': 'খাবার ও বাজার', 'icon': 'restaurant'},
    {'name': 'House Rent', 'nameBn': 'বাড়ি ভাড়া', 'icon': 'home'},
    {'name': 'Medicine & Health', 'nameBn': 'ওষুধ ও স্বাস্থ্য', 'icon': 'medical_services'},
    {'name': 'Education', 'nameBn': 'পড়াশোনা', 'icon': 'school'},
    {'name': 'Clothing', 'nameBn': 'পোশাক', 'icon': 'checkroom'},
    {'name': 'Transport', 'nameBn': 'যাতায়াত', 'icon': 'directions_bus'},
    {'name': 'Utility Bills', 'nameBn': 'ইউটিলিটি', 'icon': 'bolt'},
    {'name': 'Mobile Recharge', 'nameBn': 'মোবাইল রিচার্জ', 'icon': 'smartphone'},
    {'name': 'Donation', 'nameBn': 'দান', 'icon': 'volunteer_activism'},
    {'name': 'Festival', 'nameBn': 'উৎসব', 'icon': 'celebration'},
    {'name': 'Restaurant', 'nameBn': 'রেস্টুরেন্ট', 'icon': 'local_dining'},
    {'name': 'Child Expenses', 'nameBn': 'শিশু খরচ', 'icon': 'child_care'},
    {'name': 'Personal Care', 'nameBn': 'সাজসজ্জা', 'icon': 'spa'},
    {'name': 'Home Maintenance', 'nameBn': 'বাড়ি মেরামত', 'icon': 'build'},
    {'name': 'Entertainment', 'nameBn': 'বিনোদন', 'icon': 'movie'},
    {'name': 'Online Shopping', 'nameBn': 'অনলাইন শপিং', 'icon': 'shopping_cart'},
    {'name': 'Travel', 'nameBn': 'ভ্রমণ', 'icon': 'flight'},
    {'name': 'Insurance', 'nameBn': 'বীমা', 'icon': 'security'},
    {'name': 'Loan Payment', 'nameBn': 'কিস্তি', 'icon': 'payments'},
    {'name': 'Qurbani', 'nameBn': 'কুরবানী', 'icon': 'mosque'},
    {'name': 'Other', 'nameBn': 'অন্যান্য', 'icon': 'more_horiz'},
  ];
}
