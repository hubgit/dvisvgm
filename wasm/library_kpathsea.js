mergeInto(LibraryManager.library, {
  kpse_load_file_remote: function(namePtr, format) {
    // This calls the function we provided to the Module object in index.html
    if (Module['kpse_load_file_remote']) {
      return Module['kpse_load_file_remote'](namePtr, format);
    }
    return 0;
  }
});
