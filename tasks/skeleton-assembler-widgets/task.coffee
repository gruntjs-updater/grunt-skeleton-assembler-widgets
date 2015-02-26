jade = require('jade')
_    = require('lodash')

module.exports = (grunt, options)  ->
  # Config Variables
  # srcDir     = options.config.srcDir
  # targetDir  = options.config.targetDir

  tmpBase                = '.tmp/'
  destBase               = 'styleguide/'
  widgetsCodeDest        = 'widgets/'


  TEMPLATE_PATH = 'node_modules/grunt-skeleton-assembler-widgets/tasks/skeleton-assembler-widgets/templates/widgets-module.template.js'

  WIDGETS_MODULE_NAME = 'app.widgets'


  parseAngularComponentsMetadata = (src, options) ->
    componentsMetadata = []
    grunt.file.glob.sync(src + '/' + options.componentsFolder + '/**/package.yml').forEach  (path) ->
      componentData = grunt.file.readYAML(path)
      name = componentData.name
      if componentData.type && componentData.type == "angular"
        componentData.basePath = path.replace('package.yml', '')
        componentsMetadata.push(componentData)

    return componentsMetadata


  compileTemplates = (components, dest) ->
    components.forEach (component) ->
      templateSrc     = component.basePath + component.name + '.jade'
      templateDst     = dest + '/' + widgetsCodeDest + component.name + '/template.html'
      templateContent = jade.renderFile(templateSrc, { pretty: true })
      grunt.file.write(templateDst, templateContent)

  cacheTemplates = (dest) ->
    config =
      ngtemplates:
        widgets:
          src: widgetsCodeDest + '**/*.html'
          dest: tmpBase + 'templates.js'
          cwd: dest + '/'
          options:
            module: 'app.widgets.templates' # TODO: make this configurable
    grunt.config.merge(config)
    grunt.task.run(['ngtemplates:widgets'])


  copyScripts = (components, dest) ->
    config =
      copy: {}
    components.forEach (component) ->
      scriptSrc = component.basePath + component.name + '.js'
      scriptDst = dest + '/' + widgetsCodeDest + component.name + '/' + component.name + '.js'

      config.copy['styleguide-' + component.name] = {}
      config.copy['styleguide-' + component.name].src  = scriptSrc
      config.copy['styleguide-' + component.name].dest = scriptDst

    grunt.config.merge(config)

    copyTasksNames = _.keys(config.copy).map (target) -> 'copy:' + target
    grunt.task.run(copyTasksNames)

  createMainModule = (components, dest) ->
    artifactSrc = TEMPLATE_PATH
    artifactDst = dest + '/' + widgetsCodeDest + 'directives.js'
    template = grunt.file.read(artifactSrc)
    angularModules = ['app.widgets.templates'] # TODO: make this configurable
    components.forEach (component) ->
      angularModules.push('app.widgets.' + component.name)

    artifactContents = template
      .replace('__SUBMODULES__', JSON.stringify(angularModules))
      .replace('__MAINMODULENAME__', WIDGETS_MODULE_NAME) # TODO: make this configurable
    grunt.file.write(artifactDst, artifactContents)

  concatScripts = (dest) ->
    config =
      concat:
        widgetsArtifact:
          src:  [
            dest + '/' + widgetsCodeDest + '**/*.js',
            tmpBase + 'templates.js'
          ]
          dest: dest + '/widgets.js'

    grunt.config.merge(config)
    grunt.task.run('concat:widgetsArtifact')

  compileStyles = (src, dest, options) ->
    config =
      sass:
        myWidgetsStyles:
          files: [
            {
              expand: true
              cwd: src + '/' + options.stylesFolder + '/'
              src: ['**/*.scss']
              dest: tmpBase
              ext: '.css'
            }
          ]
      rename:
        widgetsStyles:
          src:  tmpBase  + 'main.css'
          dest: dest + '/widgets.css'

    grunt.config.merge(config)
    grunt.task.run(['sass:myWidgetsStyles', 'rename:widgetsStyles'])


  return {
    build: (src, dest, options) ->
      # Parse widgets metadata
      components = parseAngularComponentsMetadata(src, options)

      # Templates
      compileTemplates(components, dest) # JADE   ==> HTML
      cacheTemplates(dest)               # HTML's ==> $templateCache

      # Styles
      compileStyles(src, dest, options)           # SASS    ==> CSS

      # Scripts
      copyScripts(components, dest)


      # Group widgets directives and templates into a single widgets module
      createMainModule(components, dest)
      concatScripts(dest)
  }
