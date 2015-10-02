{spawn} = require "child_process"
fs = require 'fs'
path = require 'path'

# REPORTER = "dot"         # dot matrix
# REPORTER = "doc"         # html documentation
REPORTER = "spec"        # hierarchical spec list
# REPORTER = "json"        # single json object
# REPORTER = "progress"    # progress bar
# REPORTER = "list"        # spec-style listing
# REPORTER = "tap"         # test-anything-protocol
# REPORTER = "landing"     # unicode landing strip
# REPORTER = "xunit"       # xunit reportert
# REPORTER = "teamcity"    # teamcity ci support
# REPORTER = "html-cov"    # HTML test coverage
# REPORTER = "json-cov"    # JSON test coverage
# REPORTER = "min"         # minimal reporter (great with -watch)
# REPORTER = "json-stream" # newline delimited json events
# REPORTER = "markdown"    # markdown documentation (github flavour)
# REPORTER = "nyan"        # nyan cat!

mocha = './node_modules/.bin/mocha'
coffee = './node_modules/.bin/coffee'

option '-d', '--db [DB]', 'Test with this database variant'
option '-s', '--debug-sql', 'Turn on sql debug'

task "test", "run tests", (options) ->
    db_variant = options.db or 'sqlite'
    env = process.env
    env['NODE_ENV'] = 'test'
    env['BOOKSHELF_FIELDS_TESTS_DB_VARIANT'] = db_variant
    env['BOOKSHELF_FIELDS_TESTS_DEBUG'] = '1' if options['debug-sql']
    spawn mocha,
        ['--compilers', 'coffee:coffee-script',
        '--reporter', "#{REPORTER}",
        '--require', 'coffee-script/register',
        '--require', path.join('test', 'test_helper.coffee'),
        '--colors', 'test'],
        'env': env, 'cwd': process.cwd(), 'stdio': 'inherit'

task "build", "build library", ->
    env = process.env
    spawn coffee,
        ['--compile', '-o', 'lib/', 'src/']
        'env': env, 'cwd': process.cwd(), 'stdio': 'inherit'

