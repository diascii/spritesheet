// {@template project_repository}
// Contract for persisting and retrieving packer projects.
//
// A "project" captures the full workspace state — imported frames,
// packing configuration, annotations, etc. — so the user can save
// their work and resume later.
//
// Implementations live in the **data** layer and may use local file
// storage, a database, or cloud persistence.
// {@endtemplate}

/// Abstract repository for project save / load operations.
abstract class ProjectRepository {
  /// Persists the current project state.
  ///
  /// [projectData] is a JSON-serialisable map representing the full
  /// workspace.
  Future<void> saveProject(Map<String, dynamic> projectData);

  /// Loads a previously saved project by its [projectId].
  ///
  /// Returns `null` if no project with the given ID exists.
  Future<Map<String, dynamic>?> loadProject(String projectId);

  /// Returns a list of project IDs that have been saved.
  Future<List<String>> listProjects();
}
