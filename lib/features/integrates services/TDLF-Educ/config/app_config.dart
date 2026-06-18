class AppConfig {
  static const String appName = 'TDLF-Educ';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = 'http://10.0.19.22:8000';

  // ── Supabase (cloud backend) ──────────────────────────────────────────────
  // The anon key is a public client key — safe to ship. Access control is
  // enforced server-side by Row Level Security (RLS). Never embed the
  // service_role key here.
  static const String supabaseUrl = 'https://jjiozotzlmblsxgsjzgw.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpqaW96b3R6bG1ibHN4Z3Nqemd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwNzg4NzAsImV4cCI6MjA5NjY1NDg3MH0.6udahheo8t3FNGyeK2f-DCP_scXJWJqVJWSChWKPB9U';

  // Salt used to derive a stable Supabase password from a host (Tawi-Tawi) user
  // so their account "flows in" when opening the embedded app. Deterministic so
  // the same host user maps to the same account on any device. (Class-project
  // convenience — not a production-grade SSO.)
  static const String hostAccountSecret = 'tdlf-educ::tawitawi::v1';
  
  // API Endpoints
  static const String loginEndpoint = '/login';
  static const String signupEndpoint = '/signup';
  static const String booksEndpoint = '/books';
  static const String quizzesEndpoint = '/quizzes';
  static const String coursesEndpoint = '/courses';
  static const String usersEndpoint = '/users';
  static const String quizResultsEndpoint = '/quiz-results';
  static const String studentsEndpoint = '/students';
  
  // User Roles
  static const List<String> userRoles = ['Student', 'Teacher', 'Guest'];
  static const String developerRole = 'Developer';

  // Grade / Year levels (for students)
  static const List<String> gradeLevels = [
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
    '1st Year College',
    '2nd Year College',
    '3rd Year College',
    '4th Year College',
  ];

  // Courses
  static const List<String> courses = [
    'Computer Fundamentals',
    'Basic Mathematics',
    'Science and Technology',
    'English Communication',
  ];
  
  // Quiz Settings
  static const double passingScore = 75.0;
  
  // Database
  static const String databaseName = 'tdlf_educ.db';
  static const int databaseVersion = 7;
}
