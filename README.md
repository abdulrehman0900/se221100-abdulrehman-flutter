

## Branch Name

**feature/offline-cache-and-state-management**

## Tools & Packages Used

| Tool / Package         | Version  | Purpose                                              |
| ---------------------- | -------- | ---------------------------------------------------- |
| Flutter / Dart         | 3.41.x / 3.11.x | Framework and language                        |
| `provider`             | ^6.1.5   | State management (`ChangeNotifier`)                  |
| `shared_preferences`   | ^2.5.5   | Local persistence / offline cache                    |
| `http`                 | ^1.6.0   | REST API calls (HTTP layer)                          |
| `flutter_test`         | SDK      | Unit & widget tests                                  |

**API:** [JSONPlaceholder](https://jsonplaceholder.typicode.com/) — a free, no-key
fake REST API. The `/posts` endpoint represents courses: each post's `title` is
the course title and its `body` is the description.

| Operation | Method   | Endpoint                                              |
| --------- | -------- | ----------------------------------------------------- |
| Read      | `GET`    | `https://jsonplaceholder.typicode.com/posts?_limit=5` |
| Create    | `POST`   | `https://jsonplaceholder.typicode.com/posts`          |
| Update    | `PUT`    | `https://jsonplaceholder.typicode.com/posts/{id}`     |
| Delete    | `DELETE` | `https://jsonplaceholder.typicode.com/posts/{id}`     |

## Architecture

The app follows a strict separation of concerns across four layers:

```
        UI (screens)
            │  renders state · forwards user intent
            ▼
   State management  (CourseProvider — ChangeNotifier)
            │  loading / success / error / empty · optimistic updates
            ▼
      Repository      (CourseRepository — chooses the data source)
        ┌───┴────────────────────────┐
        ▼                            ▼
   API service               Local database
 (CourseService)          (CourseLocalStore)
   HTTP only             SharedPreferences cache
```

- **UI** only renders state and forwards user intent — it contains no business logic.
- **CourseProvider** owns all UI state and the optimistic-update logic.
- **CourseRepository** is the single source of truth; it decides whether data
  comes from the network or the local cache.
- **CourseService** for HTTP requests.
- **CourseLocalStore** for read/write local storage.

The UI and provider depend only on the repository — never on the service or
storage directly — which keeps each layer modular, reusable, and testable.


## Offline & State Management Approach

### Offline support (SharedPreferences)

Every successful API fetch is cached locally as JSON in **SharedPreferences**.
The repository follows a **network-first, cache-on-failure** strategy:

- On a successful fetch, fresh data is returned **and** written to the cache,
  so the local copy stays synchronized with the server.
- If the network is unavailable, the repository transparently serves the last
  cached list, and the UI shows an **offline banner**.
- Create / update / delete also re-sync the cache after they succeed, so the
  offline copy never drifts from what the user sees.

### State management (Provider)

`setState`-driven data flow is replaced with a single `CourseProvider`
(`ChangeNotifier`):

- A `ViewState` enum models **loading / success / error / empty** explicitly,
  instead of juggling scattered boolean flags.
- **Optimistic updates:** delete and update are applied to the in-memory list
  immediately; if the API call fails, the change is **rolled back** and the
  error is surfaced — so the UI always stays responsive.
- UI logic and business logic are fully separated: screens just watch the
  provider and forward intent.

