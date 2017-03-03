{spawnSync: spawn} = require "child_process"
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
istanbul = './node_modules/.bin/istanbul'
coffee = './node_modules/.bin/coffee'

option '-d', '--db [DB]', 'Test with this database variant'
option '-s', '--debug-sql', 'Turn on sql debug'
option '', '--coverage', 'Generate code coverage report'
option '', '--debug', 'Use node debugger'

task "test", "run tests", (options) ->
    db_variant = options.db or 'sqlite'
    env = process.env
    env['NODE_ENV'] = 'test'
    env['BOOKSHELF_SCHEMA_TESTS_DB_VARIANT'] = db_variant
    if options['debug-sql']
        env['BOOKSHELF_SCHEMA_TESTS_DEBUG'] = '1'
        env['DEBUG'] = env['DEBUG'] + ' knex:query'
    args = ['--compilers', 'coffee:coffee-script',
        '--reporter', "#{REPORTER}",
        '--require', 'coffee-script/register']

    if options.coverage
        args = args.concat ['--require', 'coffee-coverage/register-istanbul']

    args = args.concat [
        '--require', path.join('test', 'test_helper.coffee'),
        '--colors', '--recursive', 'test'
    ]
    args.unshift '--debug-brk' if options.debug
    spawn mocha, args, 'env': env, 'cwd': process.cwd(), 'stdio': 'inherit'
    if options.coverage
        spawn istanbul, ['report'], env: env, cwd: process.cwd(), stdio: 'inherit'

task "build", "build library", ->
    env = process.env
    spawn coffee,
        ['--compile', '--bare', '-o', 'lib/', 'src/']
        'env': env, 'cwd': process.cwd(), 'stdio': 'inherit'

task "build-doc", "build documentation", ->
    venvStats = fs.statSync './.venv'
    unless venvStats.isDirectory()
        throw new Error('virtualenv directory (.venv) not found')

    spawn '/bin/bash', [
        '-c', 'source .venv/bin/activate; cd doc; sphinx-build -b html . _build/'
    ], 'env': process.env, 'cwd': process.cwd(), 'stdio': 'inherit'

debounce = (interval, fn) ->
    timeout = null
    ->
        clearTimeout(timeout) if timeout
        timeout = setTimeout fn, interval

task "watch-doc", "watch and rebuild documentation", ->
    build = debounce 1000, -> invoke('build-doc')
    fs.watch './doc', (event, filename) ->
        build() unless filename[0] in ['.', '#']
