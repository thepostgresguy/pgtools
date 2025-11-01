# GitHub Pages Setup Instructions

This documentation is configured to be published via GitHub Pages. Follow these steps to enable it:

## Enable GitHub Pages

1. Go to your repository on GitHub
2. Click on **Settings** (in the top menu)
3. Scroll down to the **Pages** section in the left sidebar
4. Under "Build and deployment":
   - **Source**: Select "Deploy from a branch"
   - **Branch**: Select your main branch (e.g., `main` or `master`)
   - **Folder**: Select `/docs`
5. Click **Save**

## Access Your Documentation

After a few minutes, your documentation will be available at:
```
https://gmartinez-dbai.github.io/pgtools/
```

## Documentation Structure

The documentation is organized as follows:

- `index.md` - Main landing page (converted from README.md)
- `monitoring.md` - Monitoring scripts documentation
- `automation.md` - Automation framework documentation
- `maintenance.md` - Maintenance tools documentation
- `administration.md` - Administration scripts documentation
- `workflows.md` - Operational workflows documentation
- `transaction-wraparound.md` - Transaction wraparound prevention guide

## Theme and Configuration

The site uses the Cayman theme, configured in `_config.yml`. You can customize:

- Site title and description
- Theme selection
- Navigation menu
- Markdown rendering options
- Plugins

## Local Testing (Optional)

To test the documentation locally:

```bash
# Install Jekyll (requires Ruby)
gem install bundler jekyll

# Navigate to docs directory
cd docs

# Serve locally
jekyll serve

# View at http://localhost:4000
```

## Updating Documentation

To update the documentation:

1. Edit the markdown files in the `docs/` directory
2. Commit and push your changes
3. GitHub Pages will automatically rebuild and publish

## Troubleshooting

- **404 errors**: Ensure the `/docs` folder is selected in GitHub Pages settings
- **Styles not loading**: Check that `_config.yml` is in the `docs/` directory
- **Links broken**: Use relative links without `.md` extension (e.g., `[link](page)` instead of `[link](page.md)`)

## Custom Domain (Optional)

To use a custom domain:

1. Add a `CNAME` file to the `docs/` directory with your domain name
2. Configure DNS records with your domain provider
3. Update GitHub Pages settings with your custom domain

For more information, see [GitHub Pages documentation](https://docs.github.com/en/pages).
