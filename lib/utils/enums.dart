enum Gender { male, female }

/// The possible states of an asynchronous view (e.g. the courses list).
///
/// Drives the UI so that loading, success, error and empty cases are each
/// handled explicitly instead of being inferred from scattered booleans.
enum ViewState { loading, success, error, empty }
