# GitHub Pages Setup Instructions

## The Issue

The GitHub Pages deployment is failing with a 404 error because GitHub Pages has not been enabled for this repository.

## To Fix This

You need to enable GitHub Pages in your repository settings:

1. **Go to Repository Settings**:
   - Navigate to https://github.com/riccardomerolla/rapitapir/settings/pages
   - Or: Go to your repository → Settings tab → Pages (in the left sidebar)

2. **Configure GitHub Pages**:
   - **Source**: Select "GitHub Actions" (this is the modern way)
   - **Branch**: Leave as default or select "main" if asked
   - Click "Save"

3. **Alternative Method** (if GitHub Actions option isn't available):
   - **Source**: Select "Deploy from a branch"
   - **Branch**: Select "main" 
   - **Folder**: Select "/ (root)"
   - Click "Save"

## What This Enables

Once GitHub Pages is enabled, the workflow will:
- ✅ Build documentation from your docs/ folder
- ✅ Generate API documentation with YARD
- ✅ Create a beautiful documentation website
- ✅ Deploy to https://riccardomerolla.github.io/rapitapir/

## Verification

After enabling GitHub Pages:
1. The workflow should succeed on the next push
2. Your documentation will be available at the GitHub Pages URL
3. The workflow will show a green checkmark

## Updated Workflow

The workflow has been updated to:
- Use proper GitHub Pages deployment pattern
- Include proper permissions and concurrency settings
- Generate a clean documentation site
- Handle missing files gracefully

Once you enable GitHub Pages in the repository settings, the deployment should work correctly!
