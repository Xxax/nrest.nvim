# GitLab CI/CD Configuration

This document describes the CI/CD setup for nrest.nvim on GitLab.

## Pipeline Overview

The CI/CD pipeline automatically runs tests on every push and merge request to ensure code quality.

### Pipeline Files

- **`.gitlab-ci.yml`** - Full pipeline with multiple test jobs
- **`.gitlab-ci-simple.yml`** - Simplified pipeline for faster builds

### Stages

1. **test** - Run automated tests

## Jobs

### `test:neovim-stable`

Tests the plugin against stable Neovim from Alpine Linux packages.

- **Runs on**: All branches, merge requests, tags
- **Image**: `alpine:latest`
- **Neovim version**: Latest stable from Alpine repos (usually 0.9.x)
- **Duration**: ~2-3 minutes

### `test:neovim-latest`

Tests the plugin against the latest Neovim built from source.

- **Runs on**: `main` and `develop` branches only
- **Image**: `ubuntu:latest`
- **Neovim version**: Latest stable tag from GitHub
- **Duration**: ~5-7 minutes (includes building Neovim)
- **Allow failure**: Yes (doesn't block pipeline if fails)

### `lint:luacheck` (optional)

Runs luacheck linting on the Lua code.

- **Runs on**: Merge requests only
- **Image**: `alpine:latest`
- **Allow failure**: Yes (doesn't block pipeline if fails)
- **Command**: `luacheck lua/ --globals vim --no-unused-args`

### `check:health` (optional)

Basic sanity check that the plugin loads without errors.

- **Runs on**: `main` branch and merge requests
- **Image**: `alpine:latest`
- **Allow failure**: Yes

### `pages` (optional)

Creates a simple GitLab Pages site on successful test completion.

- **Runs on**: `main` branch only
- **When**: On success
- **Artifact**: `public/` directory

## Requirements

### GitLab Runner Requirements

- **Executor**: Docker
- **Tags**: `docker` (used in all jobs)

If you're using shared runners, no additional configuration is needed.

### Using Custom Runners

If using custom GitLab runners, ensure:

1. Docker executor is configured
2. Runner has the `docker` tag
3. Internet access for downloading Neovim and plenary.nvim

## Using the Simple Pipeline

If you want faster builds without the extra jobs, rename the files:

```bash
# Backup full pipeline
mv .gitlab-ci.yml .gitlab-ci-full.yml

# Use simple pipeline
mv .gitlab-ci-simple.yml .gitlab-ci.yml
```

The simple pipeline only runs the essential test job on stable Neovim.

## Local Testing

You can test the pipeline locally using GitLab Runner:

```bash
# Install GitLab Runner
# See: https://docs.gitlab.com/runner/install/

# Validate pipeline syntax
gitlab-runner exec docker test:neovim-stable

# Or use docker directly to simulate
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  alpine:latest \
  sh -c "apk add --no-cache git neovim && \
         mkdir -p ~/.local/share/nvim/site/pack/vendor/start && \
         git clone --depth 1 https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim && \
         nvim --headless -u tests/minimal_init.lua -c 'PlenaryBustedDirectory tests/ {minimal_init = \"tests/minimal_init.lua\"}'"
```

## Troubleshooting

### Tests Fail on GitLab but Pass Locally

**Check Neovim version:**
```yaml
script:
  - nvim --version  # Check which version is running
```

**Check plenary.nvim installation:**
```yaml
script:
  - ls -la ~/.local/share/nvim/site/pack/vendor/start/
```

### Pipeline Timeout

The default job timeout is usually 1 hour. If building Neovim from source times out:

```yaml
test:neovim-latest:
  timeout: 2h  # Increase timeout
```

### Cache Not Working

GitLab CI cache requires runners with cache support. If using shared runners, cache should work automatically. For custom runners, ensure cache configuration is set up.

### Missing Docker Tag

If you see "This job is stuck because no runner with the `docker` tag is available":

1. Check your runner configuration
2. Or remove the `tags:` section from `.gitlab-ci.yml` to use any available runner

## Pipeline Configuration Tips

### Skip CI for Documentation Changes

Add `[skip ci]` to commit message:
```bash
git commit -m "Update README [skip ci]"
```

### Run Only Specific Jobs

Use GitLab's web interface to manually trigger specific jobs or create custom pipelines.

### Parallel Testing

To run tests in parallel, modify `.gitlab-ci.yml`:

```yaml
test:
  parallel:
    matrix:
      - NVIM_VERSION: ['v0.8.0', 'v0.9.0', 'v0.10.0']
  script:
    - # Install specific Neovim version
```

## Monitoring

### View Pipeline Status

1. Go to your GitLab project
2. Navigate to **CI/CD → Pipelines**
3. Click on a pipeline to see job details

### Pipeline Badges

Add a pipeline badge to your README.md:

```markdown
[![pipeline status](https://gitlab.ttu.ch/matthias/nrest/badges/main/pipeline.svg)](https://gitlab.ttu.ch/matthias/nrest/-/commits/main)
```

### Test Coverage (Future)

To add test coverage reporting, modify `.gitlab-ci.yml`:

```yaml
test:
  coverage: '/^Success: (\d+)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
```

## See Also

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [GitLab Runner Documentation](https://docs.gitlab.com/runner/)
- [Testing Documentation](../tests/README.md)
