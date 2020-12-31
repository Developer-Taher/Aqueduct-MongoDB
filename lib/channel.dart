import 'hello_aqueduct.dart';

class HelloAqueductChannel extends ApplicationChannel {
  Db _db;

  @override
  Future prepare() async {
    logger.onRecord.listen(
        (rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));

    _db = Db("mongodb://localhost:27017/Blog");
    await _db.open();
    await _db.collection('users').createIndex(
      keys: {"email": 1},
      unique: true,
    );
  }

  @override
  Controller get entryPoint {
    final router = Router();

    router
        .route('/files/articles/*')
        .link(() => FileController('public/images/articles'));

    router.route('/auth/login').link(() => LoginController(_db));

    router.route('/auth/register').link(() => RegisterController(_db));

    router
        .route('/users/[:id]')
        .linkFunction(AuthorizationUtils.verifyAuthorization)
        .link(() => UsersController(_db));

    router.route('/articles/[:id]').linkFunction((request) {
      if (request.method == 'GET') {
        return request;
      }
      return AuthorizationUtils.verifyAuthorization(request);
    }).link(() => ArticlesController(_db));

    return router;
  }

  @override
  Future close() {
    _db.close();
    return super.close();
  }
}