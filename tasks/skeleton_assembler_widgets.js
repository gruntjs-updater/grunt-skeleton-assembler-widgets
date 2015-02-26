/*
 * grunt-skeleton-assembler-widgets
 * https://github.com/ginetta/grunt-skeleton-assembler-widgets
 *
 * Copyright (c) 2015 Ginetta
 * Licensed under the MIT license.
 */

"use strict";

module.exports = function(grunt) {

  // Please see the Grunt documentation for more information regarding task
  // creation: http://gruntjs.com/creating-tasks

  grunt.registerMultiTask("skeleton_assembler_widgets", "Grunt plugin to assemble skeleton components as AngularJS widgets.", function() {
    // Merge task-specific and/or target-specific options with these defaults.
    var options = this.options({
      componentsFolder: "",
      stylesFolder: ""
    });

    var task = require('./skeleton-assembler-widgets/task')(grunt)

  //   // Iterate over all specified file groups.
    this.files.forEach(function(f) {
      var src = f.src[0];
      var dest = f.dest;
      task.build(src, dest, options)
    });
  });

};
