-- Tests for auth module
local auth = require('nrest.auth')

describe('auth', function()
  describe('parse_auth', function()
    it('should parse basic auth directive', function()
      local lines = { '@auth basic username password' }
      local config, err = auth.parse_auth(lines)

      assert.is_nil(err)
      assert.is_not_nil(config)
      assert.equals('basic', config.type)
      assert.equals('username', config.params[1])
      assert.equals('password', config.params[2])
    end)

    it('should parse bearer auth directive', function()
      local lines = { '@auth bearer token123' }
      local config, err = auth.parse_auth(lines)

      assert.is_nil(err)
      assert.equals('bearer', config.type)
      assert.equals('token123', config.params[1])
    end)

    it('should parse apikey auth directive', function()
      local lines = { '@auth apikey X-API-Key secret123' }
      local config, err = auth.parse_auth(lines)

      assert.is_nil(err)
      assert.equals('apikey', config.type)
      assert.equals('X-API-Key', config.params[1])
      assert.equals('secret123', config.params[2])
    end)

    it('should parse digest auth directive', function()
      local lines = { '@auth digest username password' }
      local config, err = auth.parse_auth(lines)

      assert.is_nil(err)
      assert.equals('digest', config.type)
      assert.equals('username', config.params[1])
      assert.equals('password', config.params[2])
    end)

    it('should return error for invalid auth type', function()
      local lines = { '@auth invalid param' }
      local config, err = auth.parse_auth(lines)

      assert.is_nil(config)
      assert.is_not_nil(err)
      assert.is_truthy(err:match('Invalid auth type'))
    end)

    it('should return error for empty auth directive', function()
      local lines = { '@auth   ' }  -- Use whitespace instead of empty to trigger parsing
      local config, err = auth.parse_auth(lines)

      assert.is_nil(config)
      assert.is_not_nil(err)
      assert.is_truthy(err:match('Auth directive is empty'))
    end)

    it('should return nil when no auth directive found', function()
      local lines = { 'GET https://example.com' }
      local config, err = auth.parse_auth(lines)

      assert.is_nil(config)
      assert.is_nil(err)
    end)

    it('should find auth directive anywhere in buffer', function()
      local lines = {
        'GET https://example.com',
        '',
        '@auth bearer token123',
        '',
        'POST https://example.com/data',
      }
      local config, err = auth.parse_auth(lines)

      assert.is_nil(err)
      assert.equals('bearer', config.type)
    end)
  end)

  describe('parse_auth_line', function()
    it('should parse auth from single line', function()
      local config, err = auth.parse_auth_line('@auth bearer token123')

      assert.is_nil(err)
      assert.equals('bearer', config.type)
      assert.equals('token123', config.params[1])
    end)

    it('should return nil for nil input', function()
      local config, err = auth.parse_auth_line(nil)

      assert.is_nil(config)
      assert.is_nil(err)
    end)

    it('should return nil for line without auth directive', function()
      local config, err = auth.parse_auth_line('GET https://example.com')

      assert.is_nil(config)
      assert.is_nil(err)
    end)
  end)

  describe('apply_auth', function()
    describe('basic auth', function()
      it('should add Authorization header with base64 encoded credentials', function()
        local request = { headers = {} }
        local config = {
          type = 'basic',
          params = { 'user', 'pass' },
        }

        local ok, err = auth.apply_auth(request, config)

        assert.is_true(ok)
        assert.is_nil(err)
        assert.is_not_nil(request.headers.Authorization)
        assert.is_truthy(request.headers.Authorization:match('^Basic '))
      end)

      it('should return error for missing password', function()
        local request = { headers = {} }
        local config = {
          type = 'basic',
          params = { 'user' },
        }

        local ok, err = auth.apply_auth(request, config)

        assert.is_false(ok)
        assert.is_not_nil(err)
        assert.is_truthy(err:match('username and password'))
      end)
    end)

    describe('bearer auth', function()
      it('should add Authorization header with bearer token', function()
        local request = { headers = {} }
        local config = {
          type = 'bearer',
          params = { 'token123' },
        }

        local ok, err = auth.apply_auth(request, config)

        assert.is_true(ok)
        assert.is_nil(err)
        assert.equals('Bearer token123', request.headers.Authorization)
      end)

      it('should return error for missing token', function()
        local request = { headers = {} }
        local config = {
          type = 'bearer',
          params = {},
        }

        local ok, err = auth.apply_auth(request, config)

        assert.is_false(ok)
        assert.is_not_nil(err)
      end)
    end)

    describe('apikey auth', function()
      it('should add custom header with API key', function()
        local request = { headers = {} }
        local config = {
          type = 'apikey',
          params = { 'X-API-Key', 'secret123' },
        }

        local ok, err = auth.apply_auth(request, config)

        assert.is_true(ok)
        assert.is_nil(err)
        assert.equals('secret123', request.headers['X-API-Key'])
      end)

      it('should return error for missing parameters', function()
        local request = { headers = {} }
        local config = {
          type = 'apikey',
          params = { 'X-API-Key' },
        }

        local ok, err = auth.apply_auth(request, config)

        assert.is_false(ok)
        assert.is_not_nil(err)
      end)
    end)

    describe('digest auth', function()
      it('should set digest_auth metadata in request', function()
        local request = { headers = {} }
        local config = {
          type = 'digest',
          params = { 'user', 'pass' },
        }

        local ok, err = auth.apply_auth(request, config)

        assert.is_true(ok)
        assert.is_nil(err)
        assert.is_not_nil(request.digest_auth)
        assert.equals('user', request.digest_auth.username)
        assert.equals('pass', request.digest_auth.password)
      end)

      it('should return error for missing credentials', function()
        local request = { headers = {} }
        local config = {
          type = 'digest',
          params = { 'user' },
        }

        local ok, err = auth.apply_auth(request, config)

        assert.is_false(ok)
        assert.is_not_nil(err)
      end)
    end)

    it('should return true for nil auth config', function()
      local request = { headers = {} }
      local ok, err = auth.apply_auth(request, nil)

      assert.is_true(ok)
      assert.is_nil(err)
    end)
  end)

  describe('parse_standard_auth_header', function()
    it('should parse Basic auth with colon separator', function()
      local request = {
        headers = {
          Authorization = 'Basic user:password',
        },
      }

      local modified = auth.parse_standard_auth_header(request)

      assert.is_true(modified)
      assert.is_truthy(request.headers.Authorization:match('^Basic%s+'))
      -- Check that it's base64 encoded (should not contain colon anymore)
      assert.is_falsy(request.headers.Authorization:match(':'))
    end)

    it('should parse Basic auth with space separator', function()
      local request = {
        headers = {
          Authorization = 'Basic user password',
        },
      }

      local modified = auth.parse_standard_auth_header(request)

      assert.is_true(modified)
      assert.is_truthy(request.headers.Authorization:match('^Basic%s+'))
    end)

    it('should parse Digest auth', function()
      local request = {
        headers = {
          Authorization = 'Digest user password',
        },
      }

      local modified = auth.parse_standard_auth_header(request)

      assert.is_true(modified)
      assert.is_not_nil(request.digest_auth)
      assert.equals('user', request.digest_auth.username)
      assert.equals('password', request.digest_auth.password)
      assert.is_nil(request.headers.Authorization)
    end)

    it('should not modify Bearer tokens', function()
      local request = {
        headers = {
          Authorization = 'Bearer token123',
        },
      }

      local modified = auth.parse_standard_auth_header(request)

      assert.is_false(modified)
      assert.equals('Bearer token123', request.headers.Authorization)
    end)

    it('should return false when no Authorization header', function()
      local request = { headers = {} }

      local modified = auth.parse_standard_auth_header(request)

      assert.is_false(modified)
    end)
  end)
end)
