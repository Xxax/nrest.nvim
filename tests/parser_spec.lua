-- Tests for parser module
local parser = require('nrest.parser')

describe('parser', function()
  describe('parse_request', function()
    it('should parse simple GET request', function()
      local lines = { 'GET https://example.com' }
      local req = parser.parse_request(lines)

      assert.is_not_nil(req)
      assert.equals('GET', req.method)
      assert.equals('https://example.com', req.url)
      assert.is_table(req.headers)
      assert.is_nil(req.body)
    end)

    it('should parse POST request with headers', function()
      local lines = {
        'POST https://api.example.com/users',
        'Content-Type: application/json',
        'Authorization: Bearer token123',
      }
      local req = parser.parse_request(lines)

      assert.is_not_nil(req)
      assert.equals('POST', req.method)
      assert.equals('https://api.example.com/users', req.url)
      assert.equals('application/json', req.headers['Content-Type'])
      assert.equals('Bearer token123', req.headers['Authorization'])
    end)

    it('should parse request with body', function()
      local lines = {
        'POST https://api.example.com/data',
        'Content-Type: application/json',
        '',
        '{"name": "test", "value": 123}',
      }
      local req = parser.parse_request(lines)

      assert.is_not_nil(req)
      assert.equals('POST', req.method)
      assert.is_not_nil(req.body)
      assert.equals('{"name": "test", "value": 123}', req.body)
    end)

    it('should parse multiline body', function()
      local lines = {
        'POST https://api.example.com/data',
        '',
        '{',
        '  "name": "test",',
        '  "value": 123',
        '}',
      }
      local req = parser.parse_request(lines)

      assert.is_not_nil(req)
      assert.is_not_nil(req.body)
      assert.is_truthy(req.body:match('"name"'))
      assert.is_truthy(req.body:match('"value"'))
    end)

    it('should return nil for empty buffer', function()
      local lines = {}
      local req = parser.parse_request(lines)
      assert.is_nil(req)
    end)

    it('should skip comments and blank lines', function()
      local lines = {
        '# This is a comment',
        '',
        '// Another comment',
        'GET https://example.com',
      }
      local req = parser.parse_request(lines)

      assert.is_not_nil(req)
      assert.equals('GET', req.method)
    end)

    it('should parse request with auth directive', function()
      local lines = {
        'GET https://api.example.com/protected',
        '@auth bearer token123',
        'Accept: application/json',
      }
      local req = parser.parse_request(lines)

      assert.is_not_nil(req)
      assert.equals('GET', req.method)
      assert.is_not_nil(req.auth_line)
      assert.is_truthy(req.auth_line:match('bearer'))
    end)
  end)

  describe('parse_all_requests', function()
    it('should parse multiple requests separated by ###', function()
      local lines = {
        '### First request',
        'GET https://example.com/first',
        '',
        '### Second request',
        'POST https://example.com/second',
        'Content-Type: application/json',
      }
      local requests = parser.parse_all_requests(lines)

      assert.equals(2, #requests)
      assert.equals('GET', requests[1].method)
      assert.equals('POST', requests[2].method)
    end)

    it('should track line ranges for each request', function()
      local lines = {
        'GET https://example.com/first',
        '',
        '###',
        'POST https://example.com/second',
      }
      local requests = parser.parse_all_requests(lines)

      assert.equals(2, #requests)
      assert.is_not_nil(requests[1].start_line)
      assert.is_not_nil(requests[1].end_line)
      assert.is_not_nil(requests[2].start_line)
      assert.is_not_nil(requests[2].end_line)
    end)
  end)

  describe('parse_request_at_line', function()
    it('should find request at cursor position', function()
      local lines = {
        'GET https://example.com/first',
        '',
        '###',
        'POST https://example.com/second',
        'Content-Type: application/json',
      }
      local req = parser.parse_request_at_line(lines, 4)

      assert.is_not_nil(req)
      assert.equals('POST', req.method)
    end)

    it('should return nil if cursor is not in any request', function()
      local lines = {
        '# Just a comment',
        '',
        'GET https://example.com',
      }
      local req = parser.parse_request_at_line(lines, 1)

      assert.is_nil(req)
    end)
  end)

  describe('validate_request', function()
    it('should validate correct request', function()
      local req = {
        method = 'GET',
        url = 'https://example.com',
        headers = {},
      }
      local valid, err = parser.validate_request(req)

      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it('should reject invalid HTTP method', function()
      local req = {
        method = 'INVALID',
        url = 'https://example.com',
        headers = {},
      }
      local valid, err = parser.validate_request(req)

      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.is_truthy(err:match('Invalid HTTP method'))
    end)

    it('should reject missing URL', function()
      local req = {
        method = 'GET',
        url = '',
        headers = {},
      }
      local valid, err = parser.validate_request(req)

      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.is_truthy(err:match('URL is missing'))
    end)

    it('should reject invalid URL scheme', function()
      local req = {
        method = 'GET',
        url = 'ftp://example.com',
        headers = {},
      }
      local valid, err = parser.validate_request(req)

      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.is_truthy(err:match('http://') or err:match('https://'))
    end)

    it('should reject nil request', function()
      local valid, err = parser.validate_request(nil)

      assert.is_false(valid)
      assert.is_not_nil(err)
    end)
  end)

  describe('HTTP methods', function()
    local methods = { 'GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS', 'CONNECT', 'TRACE' }

    for _, method in ipairs(methods) do
      it('should accept ' .. method .. ' method', function()
        local lines = { method .. ' https://example.com' }
        local req = parser.parse_request(lines)

        assert.is_not_nil(req)
        assert.equals(method, req.method)
      end)
    end
  end)

  describe('multiline query parameters', function()
    it('should parse query parameters with ?', function()
      local lines = {
        'GET https://example.com/api',
        '?page=1',
        '&limit=10',
      }
      local req = parser.parse_request(lines)

      assert.is_not_nil(req)
      assert.equals('GET', req.method)
      assert.is_truthy(req.url:match('page=1'))
      assert.is_truthy(req.url:match('limit=10'))
    end)

    it('should append query params when URL already has params', function()
      local lines = {
        'GET https://example.com/api?search=test',
        '?page=1',
        '&limit=10',
      }
      local req = parser.parse_request(lines)

      assert.is_not_nil(req)
      assert.is_truthy(req.url:match('search=test'))
      assert.is_truthy(req.url:match('page=1'))
      assert.is_truthy(req.url:match('limit=10'))
    end)

    it('should parse query params before headers', function()
      local lines = {
        'GET https://example.com/api',
        '?page=1',
        'Accept: application/json',
      }
      local req = parser.parse_request(lines)

      assert.is_not_nil(req)
      assert.is_truthy(req.url:match('page=1'))
      assert.equals('application/json', req.headers['Accept'])
    end)
  end)

  describe('request naming', function()
    it('should parse request name with # @name', function()
      local lines = {
        '# @name getUserById',
        'GET https://example.com/users/123',
      }
      local req = parser.parse_request(lines)

      assert.is_not_nil(req)
      assert.equals('getUserById', req.name)
      assert.equals('GET', req.method)
    end)

    it('should parse request name with // @name', function()
      local lines = {
        '// @name createUser',
        'POST https://example.com/users',
      }
      local req = parser.parse_request(lines)

      assert.is_not_nil(req)
      assert.equals('createUser', req.name)
      assert.equals('POST', req.method)
    end)

    it('should handle request without name', function()
      local lines = {
        'GET https://example.com',
      }
      local req = parser.parse_request(lines)

      assert.is_not_nil(req)
      assert.is_nil(req.name)
    end)
  end)
end)
