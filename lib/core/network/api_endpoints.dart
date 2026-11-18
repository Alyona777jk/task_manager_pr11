class ApiEndpoints {
  // ReqRes API для авторизації
  static const String authBaseUrl = 'https://reqres.in/api';
  static const String login = '$authBaseUrl/login';
  static const String register = '$authBaseUrl/register';

  // JSONPlaceholder API для задач
  static const String tasksBaseUrl = 'https://jsonplaceholder.typicode.com';
  static const String todos = '$tasksBaseUrl/todos';
  static String todoById(int id) => '$tasksBaseUrl/todos/$id';
}
