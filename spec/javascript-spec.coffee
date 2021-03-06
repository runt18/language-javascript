describe "Javascript grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-javascript")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.js")

  it "parses the grammar", ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe "source.js"

  describe "strings", ->
    it "tokenizes single-line strings", ->
      delimsByScope =
        "string.quoted.double.js": '"'
        "string.quoted.single.js": "'"

      for scope, delim of delimsByScope
        {tokens} = grammar.tokenizeLine(delim + "x" + delim)
        expect(tokens[0].value).toEqual delim
        expect(tokens[0].scopes).toEqual ["source.js", scope, "punctuation.definition.string.begin.js"]
        expect(tokens[1].value).toEqual "x"
        expect(tokens[1].scopes).toEqual ["source.js", scope]
        expect(tokens[2].value).toEqual delim
        expect(tokens[2].scopes).toEqual ["source.js", scope, "punctuation.definition.string.end.js"]

  describe "keywords", ->
    it "tokenizes with as a keyword", ->
      {tokens} = grammar.tokenizeLine('with')
      expect(tokens[0]).toEqual value: 'with', scopes: ['source.js', 'keyword.control.js']

  describe "regular expressions", ->
    it "tokenizes regular expressions", ->
      {tokens} = grammar.tokenizeLine('/test/')
      expect(tokens[0]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[1]).toEqual value: 'test', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[2]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']

      {tokens} = grammar.tokenizeLine('foo + /test/')
      expect(tokens[0]).toEqual value: 'foo ', scopes: ['source.js']
      expect(tokens[1]).toEqual value: '+', scopes: ['source.js', 'keyword.operator.js']
      expect(tokens[2]).toEqual value: ' ', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[3]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[4]).toEqual value: 'test', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[5]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']

    it "tokenizes regular expressions inside arrays", ->
      {tokens} = grammar.tokenizeLine('[/test/]')
      expect(tokens[0]).toEqual value: '[', scopes: ['source.js', 'meta.brace.square.js']
      expect(tokens[1]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[2]).toEqual value: 'test', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[3]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']
      expect(tokens[4]).toEqual value: ']', scopes: ['source.js', 'meta.brace.square.js']

      {tokens} = grammar.tokenizeLine('[1, /test/]')
      expect(tokens[0]).toEqual value: '[', scopes: ['source.js', 'meta.brace.square.js']
      expect(tokens[1]).toEqual value: '1', scopes: ['source.js', 'constant.numeric.js']
      expect(tokens[2]).toEqual value: ',', scopes: ['source.js', 'meta.delimiter.object.comma.js']
      expect(tokens[3]).toEqual value: ' ', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[4]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.begin.js']
      expect(tokens[5]).toEqual value: 'test', scopes: ['source.js', 'string.regexp.js']
      expect(tokens[6]).toEqual value: '/', scopes: ['source.js', 'string.regexp.js', 'punctuation.definition.string.end.js']
      expect(tokens[7]).toEqual value: ']', scopes: ['source.js', 'meta.brace.square.js']

  describe "operators", ->
    it "tokenizes void correctly", ->
      {tokens} = grammar.tokenizeLine('void')
      expect(tokens[0]).toEqual value: 'void', scopes: ['source.js', 'keyword.operator.js']

    it "tokenizes the / arithmetic operator when separated by newlines", ->
      lines = grammar.tokenizeLines """
        1
        / 2
      """

      expect(lines[0][0]).toEqual value: '1', scopes: ['source.js', 'constant.numeric.js']
      expect(lines[1][0]).toEqual value: '/ ', scopes: ['source.js']
      expect(lines[1][1]).toEqual value: '2', scopes: ['source.js', 'constant.numeric.js']

  describe "ES6 string templates", ->
    it "tokenizes them as strings", ->
      {tokens} = grammar.tokenizeLine('`hey ${name}`')
      expect(tokens[0]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.js', 'punctuation.definition.string.begin.js']
      expect(tokens[1]).toEqual value: 'hey ', scopes: ['source.js', 'string.quoted.template.js']
      expect(tokens[2]).toEqual value: '${', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[3]).toEqual value: 'name', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source']
      expect(tokens[4]).toEqual value: '}', scopes: ['source.js', 'string.quoted.template.js', 'source.js.embedded.source', 'punctuation.section.embedded.js']
      expect(tokens[5]).toEqual value: '`', scopes: ['source.js', 'string.quoted.template.js', 'punctuation.definition.string.end.js']

  describe "default: in a switch statement", ->
    it "tokenizes it as a keyword", ->
      {tokens} = grammar.tokenizeLine('default: ')
      expect(tokens[0]).toEqual value: 'default', scopes: ['source.js', 'keyword.control.js']

  it "tokenizes comments in function params", ->
    {tokens} = grammar.tokenizeLine('foo: function (/**Bar*/bar){')

    expect(tokens[4]).toEqual value: '(', scopes: ['source.js', 'meta.function.json.js', 'punctuation.definition.parameters.begin.js']
    expect(tokens[5]).toEqual value: '/**', scopes: ['source.js', 'meta.function.json.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']
    expect(tokens[6]).toEqual value: 'Bar', scopes: ['source.js', 'meta.function.json.js', 'comment.block.documentation.js']
    expect(tokens[7]).toEqual value: '*/', scopes: ['source.js', 'meta.function.json.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']
    expect(tokens[8]).toEqual value: 'bar', scopes: ['source.js', 'meta.function.json.js', 'variable.parameter.function.js']

  it "tokenizes /* */ comments", ->
    {tokens} = grammar.tokenizeLine('/**/')

    expect(tokens[0]).toEqual value: '/*', scopes: ['source.js', 'comment.block.js', 'punctuation.definition.comment.js']
    expect(tokens[1]).toEqual value: '*/', scopes: ['source.js', 'comment.block.js', 'punctuation.definition.comment.js']

    {tokens} = grammar.tokenizeLine('/* foo */')

    expect(tokens[0]).toEqual value: '/*', scopes: ['source.js', 'comment.block.js', 'punctuation.definition.comment.js']
    expect(tokens[1]).toEqual value: ' foo ', scopes: ['source.js', 'comment.block.js']
    expect(tokens[2]).toEqual value: '*/', scopes: ['source.js', 'comment.block.js', 'punctuation.definition.comment.js']

  it "tokenizes /** */ comments", ->
    {tokens} = grammar.tokenizeLine('/***/')

    expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']
    expect(tokens[1]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']

    {tokens} = grammar.tokenizeLine('/** foo */')

    expect(tokens[0]).toEqual value: '/**', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']
    expect(tokens[1]).toEqual value: ' foo ', scopes: ['source.js', 'comment.block.documentation.js']
    expect(tokens[2]).toEqual value: '*/', scopes: ['source.js', 'comment.block.documentation.js', 'punctuation.definition.comment.js']
