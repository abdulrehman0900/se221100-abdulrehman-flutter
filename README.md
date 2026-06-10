
## API Used

This project uses **[JSONPlaceholder](https://jsonplaceholder.typicode.com/)** —
a free, fake REST API for testing and prototyping. It requires no API key.

the app uses its `/posts` endpoint to represent courses (the standard approach for this API). 
Each post's `title` is shown as the **course title** and its `body` as the **description**.

### Endpoints

| Operation | Method   | Endpoint                                             |
| --------- | -------- | ---------------------------------------------------- |
| Read      | `GET`    | `https://jsonplaceholder.typicode.com/posts?_limit=5`|
| Create    | `POST`   | `https://jsonplaceholder.typicode.com/posts`         |
| Update    | `PUT`    | `https://jsonplaceholder.typicode.com/posts/{id}`    |
| Delete    | `DELETE` | `https://jsonplaceholder.typicode.com/posts/{id}`    |



## Reference / Documentation Followed

- **JSONPlaceholder Guide** (request/response examples for GET, POST, PUT, DELETE):
  https://jsonplaceholder.typicode.com/guide/
- **JSONPlaceholder home / available routes:**
  https://jsonplaceholder.typicode.com/
- **Flutter `http` package** (used for all network calls):
  https://pub.dev/packages/http
- **Flutter Cookbook — Fetch data from the internet:**
  https://docs.flutter.dev/cookbook/networking/fetch-data
- **Flutter Cookbook — Send / update / delete data:**
  https://docs.flutter.dev/cookbook/networking/send-data


## Branch Name

**feature/course-api-integration**