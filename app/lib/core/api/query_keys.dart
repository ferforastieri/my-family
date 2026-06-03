class QueryKeys {
  const QueryKeys._();

  static const users = ['users'];
  static const notifications = ['notifications'];
  static const chatConversations = ['chat', 'conversations'];
  static const locations = ['location', 'latest'];
  static const familyLists = ['lists'];
  static const admin = ['admin'];

  static List<Object?> familyListItems(String listId) =>
      ['lists', 'items', listId];

  static List<Object?> quizQuestions() => ['games', 'quiz', 'public'];

  static List<Object?> wordSearchWords() => ['games', 'words', 'public'];

  static List<Object?> adminPage({
    required int usersPage,
    required int notificationsPage,
    required int questionsPage,
    required int wordsPage,
    required int statsPage,
  }) =>
      [
        ...admin,
        usersPage,
        notificationsPage,
        questionsPage,
        wordsPage,
        statsPage,
      ];

  static List<Object?> resourceScope(String resource) => ['resource', resource];

  static List<Object?> resource(String resource, int page, int limit) =>
      [...resourceScope(resource), page, limit];

  static List<Object?> textCollection(String prefix, int page, int limit) =>
      ['text-collection', prefix, page, limit];

  static List<Object?> textCollectionScope(String prefix) =>
      ['text-collection', prefix];

  static List<Object?> games(String scope, int page, int limit) =>
      ['games', scope, page, limit];
}
