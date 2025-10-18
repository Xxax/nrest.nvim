-- Tests for variables module
local variables = require('nrest.variables')

describe('variables', function()
  describe('parse_variables', function()
    it('should parse simple variable definition', function()
      local lines = { '@baseUrl = https://example.com' }
      local vars = variables.parse_variables(lines)

      assert.is_not_nil(vars)
      assert.equals('https://example.com', vars.baseUrl)
    end)

    it('should parse multiple variables', function()
      local lines = {
        '@baseUrl = https://api.example.com',
        '@token = abc123',
        '@version = v1',
      }
      local vars = variables.parse_variables(lines)

      assert.equals('https://api.example.com', vars.baseUrl)
      assert.equals('abc123', vars.token)
      assert.equals('v1', vars.version)
    end)

    it('should trim whitespace from values', function()
      local lines = { '@key =   value with spaces   ' }
      local vars = variables.parse_variables(lines)

      assert.equals('value with spaces', vars.key)
    end)

    it('should ignore non-variable lines', function()
      local lines = {
        'GET https://example.com',
        '@var = value',
        '# Comment',
      }
      local vars = variables.parse_variables(lines)

      assert.equals('value', vars.var)
      assert.equals(1, vim.tbl_count(vars))
    end)

    it('should handle empty lines', function()
      local lines = { '', '@var = value', '' }
      local vars = variables.parse_variables(lines)

      assert.equals('value', vars.var)
    end)
  end)

  describe('substitute', function()
    it('should substitute single variable', function()
      local vars = { name = 'John' }
      local result = variables.substitute('Hello {{name}}', vars)

      assert.equals('Hello John', result)
    end)

    it('should substitute multiple variables', function()
      local vars = { first = 'John', last = 'Doe' }
      local result = variables.substitute('{{first}} {{last}}', vars)

      assert.equals('John Doe', result)
    end)

    it('should keep original if variable not found', function()
      local vars = { name = 'John' }
      local result = variables.substitute('Hello {{unknown}}', vars)

      assert.equals('Hello {{unknown}}', result)
    end)

    it('should substitute system env variables', function()
      -- Set a test env var to ensure it exists
      vim.env.NREST_TEST_VAR = 'test_value'
      local result = variables.substitute('Value: $NREST_TEST_VAR', {})

      -- Should substitute the env var
      assert.equals('Value: test_value', result)

      -- Cleanup
      vim.env.NREST_TEST_VAR = nil
    end)

    it('should substitute system env variables with braces', function()
      -- Set a test env var to ensure it exists
      vim.env.NREST_TEST_VAR2 = 'braced_value'
      local result = variables.substitute('Value: ${NREST_TEST_VAR2}', {})

      -- Should substitute the env var
      assert.equals('Value: braced_value', result)

      -- Cleanup
      vim.env.NREST_TEST_VAR2 = nil
    end)

    it('should handle mixed variable types', function()
      -- Set a test env var to ensure it exists
      vim.env.NREST_TEST_USER = 'testuser'
      local vars = { apiKey = 'secret' }
      local result = variables.substitute('User: $NREST_TEST_USER, Key: {{apiKey}}', vars)

      assert.is_truthy(result:match('User: testuser'))
      assert.is_truthy(result:match('Key: secret'))
      assert.is_falsy(result:match('{{apiKey}}'))

      -- Cleanup
      vim.env.NREST_TEST_USER = nil
    end)

    it('should return nil for nil input', function()
      local result = variables.substitute(nil, {})
      assert.is_nil(result)
    end)
  end)

  describe('substitute_request', function()
    it('should substitute variables in URL', function()
      local vars = { host = 'api.example.com', version = 'v1' }
      local request = {
        method = 'GET',
        url = 'https://{{host}}/{{version}}/users',
        headers = {},
      }

      local result = variables.substitute_request(request, vars)

      assert.equals('https://api.example.com/v1/users', result.url)
    end)

    it('should substitute variables in headers', function()
      local vars = { token = 'abc123' }
      local request = {
        method = 'GET',
        url = 'https://example.com',
        headers = {
          Authorization = 'Bearer {{token}}',
        },
      }

      local result = variables.substitute_request(request, vars)

      assert.equals('Bearer abc123', result.headers.Authorization)
    end)

    it('should substitute variables in body', function()
      local vars = { name = 'John', age = '30' }
      local request = {
        method = 'POST',
        url = 'https://example.com',
        headers = {},
        body = '{"name": "{{name}}", "age": {{age}}}',
      }

      local result = variables.substitute_request(request, vars)

      assert.is_truthy(result.body:match('John'))
      assert.is_truthy(result.body:match('30'))
    end)

    it('should handle nil request', function()
      local result = variables.substitute_request(nil, {})
      assert.is_nil(result)
    end)
  end)

  describe('substitute_system_env', function()
    it('should substitute $VAR format', function()
      -- Set a test env var
      vim.env.TEST_VAR = 'test_value'
      local result = variables.substitute_system_env('Value: $TEST_VAR')

      assert.equals('Value: test_value', result)
    end)

    it('should substitute ${VAR} format', function()
      vim.env.TEST_VAR = 'test_value'
      local result = variables.substitute_system_env('Value: ${TEST_VAR}')

      assert.equals('Value: test_value', result)
    end)

    it('should keep original if env var not found', function()
      local result = variables.substitute_system_env('Value: $NONEXISTENT_VAR_12345')

      assert.equals('Value: $NONEXISTENT_VAR_12345', result)
    end)

    it('should handle malformed braces', function()
      local result = variables.substitute_system_env('Bad: ${VAR')

      -- Should keep original for malformed syntax
      assert.equals('Bad: ${VAR', result)
    end)
  end)

  describe('find_env_file', function()
    it('should return nil for non-existent directory', function()
      local result = variables.find_env_file('/nonexistent/path/12345')

      assert.is_nil(result)
    end)

    it('should return nil for empty directory', function()
      local result = variables.find_env_file('')

      assert.is_nil(result)
    end)
  end)

  describe('load_env_file', function()
    it('should return empty table for non-existent file', function()
      local vars = variables.load_env_file('/nonexistent/file.env')

      assert.is_table(vars)
      assert.equals(0, vim.tbl_count(vars))
    end)

    it('should return empty table for nil path', function()
      local vars = variables.load_env_file(nil)

      assert.is_table(vars)
      assert.equals(0, vim.tbl_count(vars))
    end)
  end)
end)
