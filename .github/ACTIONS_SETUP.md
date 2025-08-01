# 🚀 GitHub Actions Setup Guide

This document explains how to set up the GitHub Actions workflows for RapiTapir.

## 🔧 Required Secrets

To enable automatic gem publishing, you need to set up the following GitHub secrets:

### 1. RubyGems API Key (`RUBYGEMS_API_KEY`)

1. **Get your RubyGems API key:**
   ```bash
   # Login to RubyGems
   gem signin
   
   # Get your API key
   curl -u your_email https://rubygems.org/api/v1/api_key.yaml
   ```

2. **Add to GitHub Secrets:**
   - Go to your repository on GitHub
   - Navigate to **Settings** → **Secrets and variables** → **Actions**
   - Click **New repository secret**
   - Name: `RUBYGEMS_API_KEY`
   - Value: Your RubyGems API key

### 2. Personal Access Token (if needed)

For advanced workflows, you might need a personal access token:

1. **Create a PAT:**
   - Go to GitHub **Settings** → **Developer settings** → **Personal access tokens**
   - Generate a new token with `repo` and `workflow` permissions

2. **Add to GitHub Secrets:**
   - Name: `GITHUB_PAT`
   - Value: Your personal access token

## 📋 Workflow Overview

### 🧪 CI/CD Pipeline (`ci.yml`)
- **Triggers:** Push to main/develop, PRs, daily schedule
- **Actions:** 
  - Tests across Ruby versions (3.0-3.3) and OS (Ubuntu, macOS)
  - Security audits
  - Code quality checks (RuboCop, Reek)
  - Example validation

### 💎 Gem Publishing (`publish.yml`)
- **Triggers:** Version tags (v*), manual dispatch
- **Actions:**
  - Pre-publish testing
  - Gem building and publishing to RubyGems
  - GitHub release creation
  - Community notifications

### 📚 Documentation (`docs.yml`)
- **Triggers:** Push to main, docs changes
- **Actions:**
  - API documentation generation (YARD)
  - GitHub Pages deployment
  - OpenAPI spec generation from examples

### 🔧 Maintenance (`maintenance.yml`)
- **Triggers:** Weekly schedule, manual
- **Actions:**
  - Security audits
  - Dependency updates
  - Performance benchmarks
  - Automated PR creation for updates

### 🏷️ Release Management (`release.yml`)
- **Triggers:** Manual workflow dispatch
- **Actions:**
  - Version bumping (major/minor/patch)
  - Changelog generation
  - Multi-Ruby testing
  - GitHub release creation

## 🚀 How to Use

### Publishing a New Version

1. **Using Release Workflow (Recommended):**
   ```bash
   # Go to GitHub Actions → Release Management → Run workflow
   # Choose version type: patch/minor/major
   # Optionally mark as pre-release
   ```

2. **Manual Tag Creation:**
   ```bash
   # Bump version in lib/rapitapir/version.rb
   git add lib/rapitapir/version.rb
   git commit -m "🔖 Bump version to 1.0.0"
   git tag v1.0.0
   git push origin main v1.0.0
   ```

### Local Development

```bash
# Run tests locally
bundle exec rspec

# Build gem locally
gem build rapitapir.gemspec

# Install local gem
gem install ./rapitapir-*.gem

# Run security audit
gem install bundler-audit
bundler-audit --update
```

### Monitoring Workflows

- **GitHub Actions tab:** Monitor all workflow runs
- **Security tab:** Review security advisories
- **Insights → Dependency graph:** Track dependencies
- **Releases:** Monitor published versions

## 🎯 Best Practices

1. **Always test before releasing:**
   - All workflows include comprehensive testing
   - Multiple Ruby versions are tested
   - Security audits run automatically

2. **Semantic Versioning:**
   - Use `patch` for bug fixes
   - Use `minor` for new features
   - Use `major` for breaking changes

3. **Documentation:**
   - Update CHANGELOG.md for significant changes
   - Keep README.md current
   - Document new features and breaking changes

4. **Security:**
   - Monitor security audit results
   - Update dependencies regularly
   - Review and approve dependency update PRs

## 🔍 Troubleshooting

### Common Issues

1. **"Invalid credentials" during gem push:**
   - Verify `RUBYGEMS_API_KEY` secret is set correctly
   - Check if the API key has expired

2. **Tests failing on specific Ruby versions:**
   - Check compatibility issues
   - Update gemspec constraints if needed

3. **Documentation deployment fails:**
   - Ensure GitHub Pages is enabled in repository settings
   - Check file paths and permissions

4. **Security audit failures:**
   - Review bundler-audit output
   - Update vulnerable dependencies
   - Check for known CVEs

### Getting Help

- **GitHub Issues:** Report workflow problems
- **GitHub Discussions:** Ask questions about setup
- **Actions logs:** Check detailed workflow outputs

## 🎉 Success Indicators

When everything is set up correctly, you should see:

- ✅ Green builds on all PRs
- ✅ Automatic gem publishing on version tags
- ✅ Updated documentation on GitHub Pages
- ✅ Weekly dependency update PRs
- ✅ Security audit reports with no critical issues

Your RapiTapir gem is now ready for professional deployment and maintenance! 🦙✨
